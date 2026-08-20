/**
 * routes/workflow.routes.js
 * Workflow Designer: define named workflows with ordered role-based
 * steps and per-step SLA, and start an instance against a document.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { startWorkflowInstance } = require('../services/workflow.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/workflow */
router.get('/', requireModuleAccess('workflow'), asyncHandler(async (req, res) => {
  const [workflows] = await pool.query('SELECT * FROM workflows ORDER BY created_at DESC');
  const [steps] = await pool.query(
    `SELECT ws.*, r.name AS role_name, er.name AS escalation_role_name, sw.name AS sub_workflow_name
     FROM workflow_steps ws
     JOIN roles r ON r.id = ws.role_id
     LEFT JOIN roles er ON er.id = ws.escalation_role_id
     LEFT JOIN workflows sw ON sw.id = ws.sub_workflow_id
     ORDER BY ws.workflow_id, ws.step_order`
  );
  const grouped = workflows.map((w) => ({ ...w, steps: steps.filter((s) => s.workflow_id === w.id) }));
  return ok(res, grouped);
}));

/** POST /api/workflow — { name, triggerDocTypeId, triggerFolderId, steps: [{ stepName, roleId, slaDays }] } */
router.post(
  '/',
  requireModuleAccess('workflow', true),
  [body('name').trim().notEmpty(), body('steps').isArray({ min: 1 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { name, triggerDocTypeId, triggerFolderId, steps } = req.body;

    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();
      const [wf] = await conn.query(
        `INSERT INTO workflows (company_id, name, trigger_doc_type_id, trigger_folder_id, created_by) VALUES (?, ?, ?, ?, ?)`,
        [req.user.companyId, name, triggerDocTypeId || null, triggerFolderId || null, req.user.id]
      );
      for (let i = 0; i < steps.length; i += 1) {
        const s = steps[i];
        // eslint-disable-next-line no-await-in-loop
        await conn.query(
          `INSERT INTO workflow_steps (company_id, workflow_id, step_order, step_name, role_id, sla_days, escalation_role_id, sub_workflow_id)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
          [req.user.companyId, wf.insertId, i + 1, s.stepName, s.roleId, s.slaDays || 2, s.escalationRoleId || null, s.subWorkflowId || null]
        );
      }
      await conn.commit();
      await logAudit({ userId: req.user.id, action: 'Create', recordType: 'workflow', recordId: wf.insertId, detail: name, ip: req.ip });
      return ok(res, { id: wf.insertId }, 'Workflow saved', 201);
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  })
);

/**
 * PUT /api/workflow/:id — { name?, isActive?, steps? }.
 *
 * Replacing steps updates existing rows in place by position (instead of
 * dropping and re-inserting the whole set) so a step's id survives an edit
 * — `workflow_approvals.step_id` and `document_workflow_instances.
 * current_step_id` FK to `workflow_steps.id` with no cascade, so a blind
 * delete-then-reinsert 500s the moment any step has ever been actioned by a
 * real approval. Only the steps beyond the new count are actually deleted
 * (shrinking the list); if one of those still has approval history, the
 * FK violation is caught and surfaced as a clean 409 instead of a 500.
 */
router.put(
  '/:id',
  requireModuleAccess('workflow', true),
  [body('name').optional().trim().notEmpty(), body('steps').optional().isArray({ min: 1 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[workflow]] = await pool.query('SELECT id FROM workflows WHERE id = ?', [req.params.id]);
    if (!workflow) return fail(res, 'Workflow not found', 404);

    const { name, isActive, steps } = req.body;
    if (Array.isArray(steps) && steps.some((s) => Number(s.subWorkflowId) === Number(req.params.id))) {
      return fail(res, 'A workflow step cannot reference its own workflow as a sub-workflow', 422);
    }

    const conn = await pool.getConnection();
    let stepDeleteConflict = false;
    try {
      await conn.beginTransaction();
      await conn.query(
        `UPDATE workflows SET name = COALESCE(?, name), is_active = COALESCE(?, is_active) WHERE id = ?`,
        [name || null, isActive !== undefined ? (isActive ? 1 : 0) : null, req.params.id]
      );
      if (Array.isArray(steps)) {
        const [existing] = await conn.query(
          'SELECT id FROM workflow_steps WHERE workflow_id = ? ORDER BY step_order',
          [req.params.id]
        );
        for (let i = 0; i < steps.length; i += 1) {
          const s = steps[i];
          if (i < existing.length) {
            // eslint-disable-next-line no-await-in-loop
            await conn.query(
              `UPDATE workflow_steps SET step_order = ?, step_name = ?, role_id = ?, sla_days = ?, escalation_role_id = ?, sub_workflow_id = ?
               WHERE id = ?`,
              [i + 1, s.stepName, s.roleId, s.slaDays || 2, s.escalationRoleId || null, s.subWorkflowId || null, existing[i].id]
            );
          } else {
            // eslint-disable-next-line no-await-in-loop
            await conn.query(
              `INSERT INTO workflow_steps (company_id, workflow_id, step_order, step_name, role_id, sla_days, escalation_role_id, sub_workflow_id)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
              [req.user.companyId, req.params.id, i + 1, s.stepName, s.roleId, s.slaDays || 2, s.escalationRoleId || null, s.subWorkflowId || null]
            );
          }
        }
        if (existing.length > steps.length) {
          const surplusIds = existing.slice(steps.length).map((s) => s.id);
          try {
            await conn.query('DELETE FROM workflow_steps WHERE id IN (?)', [surplusIds]);
          } catch (err) {
            if (err.code === 'ER_ROW_IS_REFERENCED_2' || err.code === 'ER_ROW_IS_REFERENCED') {
              stepDeleteConflict = true;
            } else {
              throw err;
            }
          }
        }
      }
      if (stepDeleteConflict) {
        await conn.rollback();
      } else {
        await conn.commit();
      }
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }

    if (stepDeleteConflict) {
      return fail(res, 'Cannot remove a step that already has approval history — only steps after it in the list can be trimmed', 409);
    }

    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'workflow', recordId: req.params.id, ip: req.ip });
    return ok(res, null, 'Workflow updated');
  })
);

/** DELETE /api/workflow/:id — refuses if any instance is still in flight. */
router.delete('/:id', requireModuleAccess('workflow', true), asyncHandler(async (req, res) => {
  const [[workflow]] = await pool.query('SELECT id, name FROM workflows WHERE id = ?', [req.params.id]);
  if (!workflow) return fail(res, 'Workflow not found', 404);

  const [[{ activeCount }]] = await pool.query(
    `SELECT COUNT(*) AS activeCount FROM document_workflow_instances WHERE workflow_id = ? AND completed_at IS NULL`,
    [req.params.id]
  );
  if (activeCount > 0) return fail(res, 'Cannot delete a workflow with instances still in progress', 409);

  await pool.query('DELETE FROM workflows WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'workflow', recordId: req.params.id, detail: workflow.name, ip: req.ip });
  return ok(res, null, 'Workflow deleted');
}));

/** POST /api/workflow/:workflowId/start/:documentId — begins an instance at step 1. */
router.post('/:workflowId/start/:documentId', requireModuleAccess('workflow', true), asyncHandler(async (req, res) => {
  const { workflowId, documentId } = req.params;
  try {
    const instanceId = await startWorkflowInstance({ workflowId, documentId, userId: req.user.id, ip: req.ip });
    return ok(res, { instanceId }, 'Workflow started', 201);
  } catch (err) {
    if (err.message === 'Workflow has no steps configured') return fail(res, err.message, 400);
    throw err;
  }
}));

module.exports = router;
