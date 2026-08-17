/**
 * services/workflow.service.js
 * Shared workflow-execution logic used by every caller that starts or
 * advances a document_workflow_instance — the Workflow Designer's manual
 * "start" route, the Viewer's "Route for approval" action, automatic
 * submission-triggered routing, sub-workflow nesting, and the human
 * approve/reject decision in approvals.routes.js. Keeping this in one
 * place means "what happens when a step is reached/decided" behaves
 * identically no matter what caused it.
 */
const { pool } = require('../config/db');
const { logAudit } = require('./audit.service');
const { createNotification } = require('./notifications.service');
const { sendApprovalAlertEmail } = require('./email.service');

/**
 * Assigns a step's approval. If the step has sub_workflow_id set, starts a
 * nested instance of that workflow against the same document instead of a
 * human approval — the nested instance's own completion later resumes this
 * step via resumeParent(). Otherwise resolves an active user of the step's
 * role and creates a workflow_approvals row + notification.
 *
 * No-op (silently) if no active user holds the step's role — a
 * pre-existing limitation of this app (a role with zero active users
 * strands the document with nothing actionable), not introduced here.
 */
async function assignStep({ conn, instanceId, step, documentId, ip }) {
  if (step.sub_workflow_id) {
    await startWorkflowInstance({
      conn, workflowId: step.sub_workflow_id, documentId, userId: null, ip, parentInstanceId: instanceId,
    });
    return;
  }

  const [[approver]] = await conn.query('SELECT id, email FROM users WHERE role_id = ? AND is_active = 1 LIMIT 1', [step.role_id]);
  if (!approver) return;

  await conn.query(
    `INSERT INTO workflow_approvals (instance_id, step_id, approver_id) VALUES (?, ?, ?)`,
    [instanceId, step.id, approver.id]
  );
  const [[doc]] = await conn.query('SELECT record_no, title FROM documents WHERE id = ?', [documentId]);
  sendApprovalAlertEmail(approver.email, doc.record_no, doc.title).catch(() => {});
  await createNotification({
    userId: approver.id,
    type: 'approval_pending',
    title: `Approval required: ${doc.record_no}`,
    body: `"${doc.title}" is awaiting your review (step "${step.step_name}").`,
    relatedRecordType: 'document',
    relatedRecordId: documentId,
  });
}

/**
 * Starts an instance of `workflowId` against `documentId` at its first
 * step. `parentInstanceId` is set when this call originates from a parent
 * instance's sub_workflow_id step (see assignStep) — the child instance's
 * completion later resumes that parent.
 *
 * Accepts an optional existing transactional `conn` (a sub-workflow start
 * happening inside its parent's own transaction) or opens/manages its own
 * otherwise, so this is safe to call both standalone and nested.
 */
async function startWorkflowInstance({ conn: existingConn, workflowId, documentId, userId, ip, parentInstanceId = null }) {
  const conn = existingConn || await pool.getConnection();
  const ownsConn = !existingConn;
  try {
    if (ownsConn) await conn.beginTransaction();

    const [[firstStep]] = await conn.query(
      'SELECT * FROM workflow_steps WHERE workflow_id = ? ORDER BY step_order ASC LIMIT 1',
      [workflowId]
    );
    if (!firstStep) throw new Error('Workflow has no steps configured');

    const [instance] = await conn.query(
      `INSERT INTO document_workflow_instances (document_id, workflow_id, current_step_id, parent_instance_id) VALUES (?, ?, ?, ?)`,
      [documentId, workflowId, firstStep.id, parentInstanceId]
    );

    await assignStep({ conn, instanceId: instance.insertId, step: firstStep, documentId, ip });
    await conn.query('UPDATE documents SET status = "pending_approval" WHERE id = ?', [documentId]);
    await logAudit({ userId, action: 'Edit', recordType: 'document', recordId: documentId, detail: `Workflow "${workflowId}" started`, ip });

    if (ownsConn) await conn.commit();
    return instance.insertId;
  } catch (err) {
    if (ownsConn) await conn.rollback();
    throw err;
  } finally {
    if (ownsConn) conn.release();
  }
}

/**
 * Finds one active workflow whose trigger conditions match a newly
 * submitted document, preferring the most specific match (both trigger
 * fields set > one > neither), and starts it. A workflow with neither
 * trigger field configured never auto-fires (it exists only for manual
 * "Route for approval"). Silent no-op if nothing matches, and silent on
 * any failure — routing must never undo a successful registration; the
 * document simply stays awaiting manual routing.
 */
async function autoTriggerWorkflow({ documentId, documentTypeId, folderId, ip }) {
  const [[workflow]] = await pool.query(
    `SELECT id FROM workflows
     WHERE is_active = 1
       AND (trigger_doc_type_id IS NULL OR trigger_doc_type_id = ?)
       AND (trigger_folder_id IS NULL OR trigger_folder_id = ?)
       AND (trigger_doc_type_id IS NOT NULL OR trigger_folder_id IS NOT NULL)
     ORDER BY (trigger_doc_type_id IS NOT NULL) + (trigger_folder_id IS NOT NULL) DESC
     LIMIT 1`,
    [documentTypeId, folderId]
  );
  if (!workflow) return null;
  return startWorkflowInstance({ workflowId: workflow.id, documentId, userId: null, ip });
}

/**
 * Resumes a parent instance whose sub_workflow_id step's child instance
 * (see assignStep) just reached a terminal state — re-runs advanceInstance
 * against the parent's own current step as if that step had just been
 * "decided" with the child's outcome. Recurses naturally for nested
 * sub-workflows.
 */
async function resumeParent({ conn, parentInstanceId, decision, comment, ip }) {
  const [[parent]] = await conn.query(
    'SELECT document_id, workflow_id, current_step_id FROM document_workflow_instances WHERE id = ?',
    [parentInstanceId]
  );
  if (!parent) return;
  await advanceInstance({
    conn, instanceId: parentInstanceId, stepId: parent.current_step_id,
    workflowId: parent.workflow_id, documentId: parent.document_id, decision, comment, ip,
  });
}

/**
 * The "what happens after a decision" logic — called once a specific step
 * of `instanceId` has been decided (either a human's approve/reject on a
 * workflow_approvals row in approvals.routes.js, or a sub-workflow child
 * instance completing via resumeParent above).
 *
 * Only touches `documents.status` / notifies the document owner when this
 * instance has no parent (parent_instance_id IS NULL) — an instance that's
 * itself satisfying a parent's sub_workflow_id step is an internal/
 * intermediate event; only the root instance's own resolution should
 * change the document's visible status, after resumeParent bubbles the
 * outcome up.
 */
async function advanceInstance({ conn, instanceId, stepId, workflowId, documentId, decision, comment = null, ip }) {
  const [[instance]] = await conn.query('SELECT parent_instance_id FROM document_workflow_instances WHERE id = ?', [instanceId]);

  if (decision === 'rejected') {
    await conn.query('UPDATE document_workflow_instances SET status = "rejected", completed_at = NOW() WHERE id = ?', [instanceId]);
    if (instance.parent_instance_id) {
      await resumeParent({ conn, parentInstanceId: instance.parent_instance_id, decision: 'rejected', comment, ip });
    } else {
      const [[doc]] = await conn.query('SELECT owner_id, record_no, title FROM documents WHERE id = ?', [documentId]);
      await conn.query('UPDATE documents SET status = "rejected" WHERE id = ?', [documentId]);
      await createNotification({
        userId: doc.owner_id, type: 'approval_rejected', title: `Returned: ${doc.record_no}`,
        body: `"${doc.title}" was rejected${comment ? `: ${comment}` : '.'}`, relatedRecordType: 'document', relatedRecordId: documentId,
      });
    }
    return;
  }

  const [[nextStep]] = await conn.query(
    `SELECT ws.* FROM workflow_steps ws
     WHERE ws.workflow_id = ? AND ws.step_order = (SELECT step_order + 1 FROM workflow_steps WHERE id = ?)`,
    [workflowId, stepId]
  );

  if (nextStep) {
    await conn.query('UPDATE document_workflow_instances SET current_step_id = ? WHERE id = ?', [nextStep.id, instanceId]);
    await assignStep({ conn, instanceId, step: nextStep, documentId, ip });
    return;
  }

  await conn.query('UPDATE document_workflow_instances SET status = "approved", completed_at = NOW() WHERE id = ?', [instanceId]);
  if (instance.parent_instance_id) {
    await resumeParent({ conn, parentInstanceId: instance.parent_instance_id, decision: 'approved', ip });
  } else {
    const [[doc]] = await conn.query('SELECT owner_id, record_no, title FROM documents WHERE id = ?', [documentId]);
    await conn.query('UPDATE documents SET status = "approved" WHERE id = ?', [documentId]);
    await createNotification({
      userId: doc.owner_id, type: 'approval_completed', title: `Approved: ${doc.record_no}`,
      body: `"${doc.title}" has completed its approval workflow.`, relatedRecordType: 'document', relatedRecordId: documentId,
    });
  }
}

module.exports = { startWorkflowInstance, autoTriggerWorkflow, advanceInstance, assignStep };
