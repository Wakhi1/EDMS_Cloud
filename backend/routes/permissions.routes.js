/**
 * routes/permissions.routes.js
 * Folder & document ACLs (inheritable), plus the role x module
 * permission matrix used by rbac.middleware.requireModuleAccess.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess, allowRoles } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { PERMISSION_LEVELS, TARGET_TYPES, PRINCIPAL_TYPES } = require('../config/constants');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/permissions/matrix/all — role x module permission matrix
 * (System Administrator only). Registered before the generic
 * /:targetType/:targetId route below — Express matches routes in
 * registration order, and "matrix"/"all" would otherwise be captured as
 * targetType/targetId, failing the TARGET_TYPES check with a spurious
 * "Invalid target type" 400 on every call.
 */
router.get('/matrix/all', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT rmp.*, r.name AS role_name FROM role_module_permissions rmp JOIN roles r ON r.id = rmp.role_id ORDER BY r.name, rmp.module`
  );
  return ok(res, rows);
}));

/** PUT /api/permissions/matrix — upsert a role/module permission cell. */
router.put(
  '/matrix',
  allowRoles('System Administrator'),
  [body('roleId').isInt(), body('module').notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { roleId, module, canView, canEdit } = req.body;
    await pool.query(
      `INSERT INTO role_module_permissions (role_id, module, can_view, can_edit)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE can_view = VALUES(can_view), can_edit = VALUES(can_edit)`,
      [roleId, module, canView ? 1 : 0, canEdit ? 1 : 0]
    );
    await logAudit({ userId: req.user.id, action: 'Permission', recordType: 'role_module', recordId: `${roleId}:${module}`, ip: req.ip });
    return ok(res, null, 'Permission matrix updated');
  })
);

/** GET /api/permissions/:targetType/:targetId — ACL rows for a folder or document, own + inherited. */
router.get('/:targetType/:targetId', requireModuleAccess('permissions'), asyncHandler(async (req, res) => {
  const { targetType, targetId } = req.params;
  if (!TARGET_TYPES.includes(targetType)) return fail(res, 'Invalid target type', 400);

  const [own] = await pool.query(
    `SELECT a.*, IF(a.principal_type = 'user', u.full_name, g.name) AS principal_name
     FROM document_acl a
     LEFT JOIN users u ON a.principal_type = 'user' AND u.id = a.principal_id
     LEFT JOIN groups g ON a.principal_type = 'group' AND g.id = a.principal_id
     WHERE a.target_type = ? AND a.target_id = ?`,
    [targetType, targetId]
  );

  let inherited = [];
  if (targetType === 'document') {
    const [[doc]] = await pool.query('SELECT folder_id FROM documents WHERE id = ?', [targetId]);
    if (doc) {
      [inherited] = await pool.query(
        `SELECT a.*, IF(a.principal_type = 'user', u.full_name, g.name) AS principal_name
         FROM document_acl a
         LEFT JOIN users u ON a.principal_type = 'user' AND u.id = a.principal_id
         LEFT JOIN groups g ON a.principal_type = 'group' AND g.id = a.principal_id
         WHERE a.target_type = 'folder' AND a.target_id = ?`,
        [doc.folder_id]
      );
    }
  }

  return ok(res, { own, inherited });
}));

/** POST /api/permissions/:targetType/:targetId — grant an ACL entry. */
router.post(
  '/:targetType/:targetId',
  requireModuleAccess('permissions', true),
  [
    body('principalType').isIn(PRINCIPAL_TYPES),
    body('principalId').isInt(),
    body('permissionLevel').isIn(PERMISSION_LEVELS),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { targetType, targetId } = req.params;
    if (!TARGET_TYPES.includes(targetType)) return fail(res, 'Invalid target type', 400);
    const { principalType, principalId, permissionLevel } = req.body;

    const [result] = await pool.query(
      `INSERT INTO document_acl (target_type, target_id, principal_type, principal_id, permission_level, granted_by)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [targetType, targetId, principalType, principalId, permissionLevel, req.user.id]
    );

    await logAudit({
      userId: req.user.id, action: 'Permission', recordType: targetType, recordId: targetId,
      detail: `Granted ${permissionLevel} to ${principalType} #${principalId}`, ip: req.ip,
    });

    return ok(res, { id: result.insertId }, 'Access granted', 201);
  })
);

/** DELETE /api/permissions/:aclId — revoke an ACL entry. */
router.delete('/:aclId', requireModuleAccess('permissions', true), asyncHandler(async (req, res) => {
  const [[row]] = await pool.query('SELECT * FROM document_acl WHERE id = ?', [req.params.aclId]);
  if (!row) return fail(res, 'ACL entry not found', 404);

  await pool.query('DELETE FROM document_acl WHERE id = ?', [req.params.aclId]);
  await logAudit({
    userId: req.user.id, action: 'Permission', recordType: row.target_type, recordId: row.target_id,
    detail: `Revoked ${row.permission_level} from ${row.principal_type} #${row.principal_id}`, ip: req.ip,
  });
  return ok(res, null, 'Access revoked');
}));

module.exports = router;
