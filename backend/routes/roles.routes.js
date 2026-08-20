/**
 * routes/roles.routes.js
 * Role administration for the `roles` table backing `users.role_id`,
 * `workflow_steps.role_id`/`escalation_role_id`, and
 * `role_module_permissions`. Read is gated the same as Users (Records
 * Manager/System Administrator both need role names for Create User,
 * Workflow Designer's per-step role picker, and the Permission Matrix);
 * create/edit/delete are System-Administrator-only, matching the
 * Permission Matrix's own gate — a role is meaningless without matrix
 * configuration to go with it, and only System Administrator can set that.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess, allowRoles } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/roles */
router.get('/', requireModuleAccess('users'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT id, name, description, mfa_required, is_system_role FROM roles WHERE company_id = ? ORDER BY name', [req.user.companyId]);
  return ok(res, rows);
}));

/** POST /api/roles — { name, description?, mfaRequired? }. New roles start with zero role_module_permissions rows — configure access via the Permission Matrix after creating. */
router.post(
  '/',
  allowRoles('System Administrator'),
  [body('name').trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { name, description, mfaRequired } = req.body;
    const [existing] = await pool.query('SELECT id FROM roles WHERE company_id = ? AND name = ?', [req.user.companyId, name]);
    if (existing.length) return fail(res, 'A role with this name already exists', 409);

    const [result] = await pool.query(
      'INSERT INTO roles (company_id, name, description, mfa_required, is_system_role) VALUES (?, ?, ?, ?, 0)',
      [req.user.companyId, name, description || null, mfaRequired ? 1 : 0]
    );
    await logAudit({ userId: req.user.id, companyId: req.user.companyId, action: 'Create', recordType: 'role', recordId: result.insertId, detail: name, ip: req.ip });
    return ok(res, { id: result.insertId }, 'Role created', 201);
  })
);

/** PUT /api/roles/:id — { name?, description?, mfaRequired? }. is_system_role is immutable via this route. */
router.put(
  '/:id',
  allowRoles('System Administrator'),
  [body('name').optional().trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[role]] = await pool.query('SELECT id FROM roles WHERE id = ? AND company_id = ?', [req.params.id, req.user.companyId]);
    if (!role) return fail(res, 'Role not found', 404);

    const { name, description, mfaRequired } = req.body;
    await pool.query(
      `UPDATE roles SET
         name = COALESCE(?, name),
         description = COALESCE(?, description),
         mfa_required = COALESCE(?, mfa_required)
       WHERE id = ?`,
      [name || null, description !== undefined ? description : null, mfaRequired !== undefined ? (mfaRequired ? 1 : 0) : null, req.params.id]
    );
    await logAudit({ userId: req.user.id, companyId: req.user.companyId, action: 'Edit', recordType: 'role', recordId: req.params.id, ip: req.ip });
    return ok(res, null, 'Role updated');
  })
);

/** DELETE /api/roles/:id — refused for built-in system roles, or roles still referenced by a user or workflow step. */
router.delete('/:id', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const [[role]] = await pool.query('SELECT id, name, is_system_role FROM roles WHERE id = ? AND company_id = ?', [req.params.id, req.user.companyId]);
  if (!role) return fail(res, 'Role not found', 404);
  if (role.is_system_role) return fail(res, 'This is a built-in system role and cannot be deleted', 409);

  const [[{ userCount }]] = await pool.query('SELECT COUNT(*) AS userCount FROM users WHERE role_id = ?', [req.params.id]);
  if (userCount > 0) return fail(res, 'Cannot delete a role still assigned to users', 409);

  const [[{ stepCount }]] = await pool.query(
    'SELECT COUNT(*) AS stepCount FROM workflow_steps WHERE role_id = ? OR escalation_role_id = ?',
    [req.params.id, req.params.id]
  );
  if (stepCount > 0) return fail(res, 'Cannot delete a role still referenced by a workflow step', 409);

  await pool.query('DELETE FROM roles WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, companyId: req.user.companyId, action: 'Delete', recordType: 'role', recordId: req.params.id, detail: role.name, ip: req.ip });
  return ok(res, null, 'Role deleted');
}));

module.exports = router;
