/**
 * routes/approvals.routes.js
 * "Awaiting my approval" inbox and approve/reject actions that advance a
 * document_workflow_instance to its next step (or completion).
 */
const express = require('express');
const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { advanceInstance } = require('../services/workflow.service');
const { hasSignature, snapshotSignatureForApproval } = require('../services/signature.service');
const { getSettingBool } = require('../services/settings.service');
const { embedSignatureIntoDocument } = require('../services/document.service');

const VALID_SIGNATURE_PAGES = ['first', 'last'];
const VALID_SIGNATURE_POSITIONS = ['bottom-right', 'bottom-left', 'bottom-center', 'top-right', 'top-left'];

const router = express.Router();
router.use(authenticate);

/** GET /api/approvals — items pending approval by the current user's role. */
router.get('/', requireModuleAccess('approvals'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT wa.id AS approval_id, wa.instance_id, wa.step_id, wa.escalated_at, d.id AS document_id, d.record_no, d.title,
            ws.step_name, ws.sla_days, ws.requires_signature, dwi.started_at
     FROM workflow_approvals wa
     JOIN document_workflow_instances dwi ON dwi.id = wa.instance_id
     JOIN documents d ON d.id = dwi.document_id
     JOIN workflow_steps ws ON ws.id = wa.step_id
     WHERE wa.decision = 'pending' AND wa.approver_id = ?
     ORDER BY dwi.started_at ASC`,
    [req.user.id]
  );
  return ok(res, rows);
}));

async function decide(req, res, decision) {
  const { approvalId } = req.params;
  const { comment } = req.body;

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [[approval]] = await conn.query(
      `SELECT wa.*, dwi.document_id, dwi.workflow_id, ws.requires_signature
       FROM workflow_approvals wa
       JOIN document_workflow_instances dwi ON dwi.id = wa.instance_id
       JOIN workflow_steps ws ON ws.id = wa.step_id
       WHERE wa.id = ? AND wa.approver_id = ? FOR UPDATE`,
      [approvalId, req.user.id]
    );
    if (!approval) { await conn.rollback(); return fail(res, 'Approval item not found', 404); }
    if (approval.decision !== 'pending') { await conn.rollback(); return fail(res, 'This item has already been decided', 409); }

    if (decision === 'approved' && approval.requires_signature && !(await hasSignature(req.user.id))) {
      await conn.rollback();
      return fail(res, 'Save a signature in Settings before approving this step', 400);
    }

    await conn.query('UPDATE workflow_approvals SET decision = ?, comment = ?, decided_at = NOW() WHERE id = ?', [decision, comment || null, approvalId]);

    if (decision === 'approved' && approval.requires_signature) {
      const savedSignature = await snapshotSignatureForApproval(conn, approval.id, approval.company_id, req.user.id);

      if (await getSettingBool('embed_approval_signatures', false)) {
        const { page, position } = req.body.signaturePlacement || {};
        await embedSignatureIntoDocument(conn, {
          documentId: approval.document_id, companyId: approval.company_id, userId: req.user.id,
          signatureBuffer: savedSignature.buffer,
          placement: {
            page: VALID_SIGNATURE_PAGES.includes(page) ? page : 'last',
            position: VALID_SIGNATURE_POSITIONS.includes(position) ? position : 'bottom-right',
          },
        });
      }
    }

    await advanceInstance({
      conn, instanceId: approval.instance_id, stepId: approval.step_id, workflowId: approval.workflow_id,
      documentId: approval.document_id, decision, comment, ip: req.ip,
    });

    await conn.commit();
    await logAudit({ userId: req.user.id, action: 'Approve', recordType: 'document', recordId: approval.document_id, detail: decision, ip: req.ip });
    return ok(res, null, `Item ${decision}`);
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}

/** POST /api/approvals/:approvalId/approve */
router.post('/:approvalId/approve', requireModuleAccess('approvals', true), asyncHandler((req, res) => decide(req, res, 'approved')));

/** POST /api/approvals/:approvalId/reject */
router.post('/:approvalId/reject', requireModuleAccess('approvals', true), asyncHandler((req, res) => decide(req, res, 'rejected')));

module.exports = router;
