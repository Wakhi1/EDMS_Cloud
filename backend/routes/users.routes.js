/**
 * routes/users.routes.js
 * Users & Groups administration (System Administrator), plus a "me"
 * profile update endpoint available to any authenticated user.
 */
const express = require('express');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess, allowRoles } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { createNotification } = require('../services/notifications.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/users?role=&departmentId=&status=active|locked */
router.get('/', requireModuleAccess('users'), asyncHandler(async (req, res) => {
  const { role, departmentId, status } = req.query;
  const clauses = [];
  const params = [];
  if (role) { clauses.push('r.name = ?'); params.push(role); }
  if (departmentId) { clauses.push('u.department_id = ?'); params.push(departmentId); }
  if (status === 'active') clauses.push('u.is_active = 1 AND u.is_locked = 0');
  if (status === 'locked') clauses.push('u.is_locked = 1');
  if (status === 'inactive') clauses.push('u.is_active = 0');
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';

  const [rows] = await pool.query(
    `SELECT u.id, u.full_name, u.email, u.phone_number, u.is_active, u.is_locked, u.mfa_enabled,
            u.department_id, r.name AS role_name, dep.name AS department_name,
            EXISTS(SELECT 1 FROM user_social_identities si WHERE si.user_id = u.id AND si.provider = 'active_directory') AS ad_linked
     FROM users u JOIN roles r ON r.id = u.role_id LEFT JOIN departments dep ON dep.id = u.department_id
     ${where} ORDER BY u.full_name`,
    params
  );
  return ok(res, rows);
}));

/**
 * POST /api/users — System Administrator creates an account in-app
 * (distinct from the public POST /api/auth/register self-service flow).
 * Assigning the System Administrator role is always System-Administrator-
 * only, regardless of how the `users` module permission matrix is
 * configured, since that assignment can grant full system control.
 */
router.post(
  '/',
  requireModuleAccess('users', true),
  [
    body('fullName').trim().notEmpty(),
    body('email').isEmail(),
    body('password').isLength({ min: 10 }),
    body('roleId').isInt(),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { fullName, email, password, roleId, departmentId, phoneNumber } = req.body;
    const [[role]] = await pool.query('SELECT name FROM roles WHERE id = ?', [roleId]);
    if (!role) return fail(res, 'Unknown role', 400);
    if (role.name === 'System Administrator' && req.user.role !== 'System Administrator') {
      return fail(res, 'Only a System Administrator can create another System Administrator account', 403);
    }

    const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length) return fail(res, 'An account with this email already exists', 409);

    const passwordHash = await bcrypt.hash(password, 12);
    const [result] = await pool.query(
      `INSERT INTO users (full_name, email, phone_number, password_hash, role_id, department_id, password_changed_at)
       VALUES (?, ?, ?, ?, ?, ?, NOW())`,
      [fullName, email, phoneNumber || null, passwordHash, roleId, departmentId || null]
    );
    await logAudit({ userId: req.user.id, action: 'Create', recordType: 'user', recordId: result.insertId, detail: `${email} (${role.name})`, ip: req.ip });
    return ok(res, { id: result.insertId }, 'Account created', 201);
  })
);

/** DELETE /api/users/:id — deactivates (never hard-deletes; documents/audit rows reference user ids). */
router.delete('/:id', requireModuleAccess('users', true), asyncHandler(async (req, res) => {
  if (Number(req.params.id) === req.user.id) return fail(res, 'You cannot deactivate your own account', 400);

  const [[target]] = await pool.query(
    `SELECT u.id, u.email, r.name AS role_name FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = ?`,
    [req.params.id]
  );
  if (!target) return fail(res, 'User not found', 404);
  if (target.role_name === 'System Administrator' && req.user.role !== 'System Administrator') {
    return fail(res, 'Only a System Administrator can deactivate another System Administrator account', 403);
  }

  await pool.query('UPDATE users SET is_active = 0 WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'user', recordId: req.params.id, detail: `Deactivated ${target.email}`, ip: req.ip });
  return ok(res, null, 'Account deactivated');
}));

/** PUT /api/users/:id/role */
router.put(
  '/:id/role',
  requireModuleAccess('users', true),
  [body('roleId').isInt()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[targetRole]] = await pool.query('SELECT name FROM roles WHERE id = ?', [req.body.roleId]);
    if (!targetRole) return fail(res, 'Unknown role', 400);
    if (targetRole.name === 'System Administrator' && req.user.role !== 'System Administrator') {
      return fail(res, 'Only a System Administrator can grant the System Administrator role', 403);
    }

    await pool.query('UPDATE users SET role_id = ? WHERE id = ?', [req.body.roleId, req.params.id]);
    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'user', recordId: req.params.id, detail: `Role changed to ${req.body.roleId}`, ip: req.ip });
    const [[role]] = await pool.query('SELECT name FROM roles WHERE id = ?', [req.body.roleId]);
    await createNotification({
      userId: req.params.id,
      type: 'role_changed',
      title: 'Your role was changed',
      body: `Your role is now "${role?.name ?? req.body.roleId}".`,
      relatedRecordType: 'user',
      relatedRecordId: req.params.id,
    });
    return ok(res, null, 'Role updated');
  })
);

/** PUT /api/users/:id/lock — { locked: true|false } */
router.put('/:id/lock', requireModuleAccess('users', true), asyncHandler(async (req, res) => {
  await pool.query('UPDATE users SET is_locked = ? WHERE id = ?', [req.body.locked ? 1 : 0, req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'user', recordId: req.params.id, detail: req.body.locked ? 'Locked' : 'Unlocked', ip: req.ip });
  await createNotification({
    userId: req.params.id,
    type: req.body.locked ? 'account_locked' : 'account_unlocked',
    title: req.body.locked ? 'Your account was locked' : 'Your account was unlocked',
    body: req.body.locked ? 'Contact your System Administrator if you believe this is an error.' : 'You can now sign in again.',
    relatedRecordType: 'user',
    relatedRecordId: req.params.id,
  });
  return ok(res, null, 'Account updated');
}));

/** PUT /api/users/:id/department — { departmentId: number|null } admin reassignment (distinct from POST /'s creation-time value, which had no update path). */
router.put('/:id/department', requireModuleAccess('users', true), asyncHandler(async (req, res) => {
  const { departmentId } = req.body;
  if (departmentId !== null && departmentId !== undefined) {
    const [[dept]] = await pool.query('SELECT id FROM departments WHERE id = ?', [departmentId]);
    if (!dept) return fail(res, 'Unknown department', 400);
  }

  await pool.query('UPDATE users SET department_id = ? WHERE id = ?', [departmentId ?? null, req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'user', recordId: req.params.id, detail: `Department changed to ${departmentId ?? 'Unassigned'}`, ip: req.ip });
  await createNotification({
    userId: req.params.id,
    type: 'department_changed',
    title: 'Your department was changed',
    body: 'Ask a System Administrator if you believe this is an error.',
    relatedRecordType: 'user',
    relatedRecordId: req.params.id,
  });
  return ok(res, null, 'Department updated');
}));

/**
 * PUT /api/users/:id/password — { newPassword } admin-set password reset,
 * distinct from PUT /me/password (self-service, requires the current
 * password). No "current password" check here since this is the explicit
 * administrative recovery path for a user who cannot sign in — every
 * active session for the target account is revoked so the reset actually
 * takes effect immediately.
 */
router.put(
  '/:id/password',
  requireModuleAccess('users', true),
  [body('newPassword').isLength({ min: 10 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const passwordHash = await bcrypt.hash(req.body.newPassword, 12);
    await pool.query('UPDATE users SET password_hash = ?, password_changed_at = NOW(), failed_login_attempts = 0 WHERE id = ?', [passwordHash, req.params.id]);
    await pool.query('UPDATE user_sessions SET revoked_at = NOW() WHERE user_id = ? AND revoked_at IS NULL', [req.params.id]);
    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'user', recordId: req.params.id, detail: 'Password reset by administrator', ip: req.ip });
    await createNotification({
      userId: req.params.id,
      type: 'password_reset_by_admin',
      title: 'Your password was reset',
      body: 'A System Administrator set a new password for your account. Contact them directly to receive it.',
      relatedRecordType: 'user',
      relatedRecordId: req.params.id,
    });
    return ok(res, null, 'Password reset');
  })
);

/**
 * PUT /api/users/:id/mfa — { enabled: true|false }. Only meaningful for
 * roles that don't already mandate MFA (login's mfaMandatory check is
 * `role.mfa_required || user.mfa_enabled` — this can add a voluntary
 * requirement for an exempt role, or remove one, but can never bypass a
 * role-mandated requirement).
 */
router.put('/:id/mfa', requireModuleAccess('users', true), asyncHandler(async (req, res) => {
  await pool.query('UPDATE users SET mfa_enabled = ? WHERE id = ?', [req.body.enabled ? 1 : 0, req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'user', recordId: req.params.id, detail: `MFA ${req.body.enabled ? 'enabled' : 'disabled'} by administrator`, ip: req.ip });
  await createNotification({
    userId: req.params.id,
    type: 'mfa_updated',
    title: `MFA was ${req.body.enabled ? 'enabled' : 'disabled'} for your account`,
    body: 'Contact your System Administrator if you believe this is an error.',
    relatedRecordType: 'user',
    relatedRecordId: req.params.id,
  });
  return ok(res, null, 'MFA setting updated');
}));

/**
 * POST /api/users/:id/mfa/reset — wipes every enrolled factor (TOTP,
 * backup codes, WebAuthn) so a user who lost their device/codes can
 * re-enroll from scratch on next login. Does not touch mfa_enabled or the
 * role's own mandatory-MFA status — a role that requires MFA still will.
 */
router.post('/:id/mfa/reset', requireModuleAccess('users', true), asyncHandler(async (req, res) => {
  const [result] = await pool.query('DELETE FROM user_mfa_methods WHERE user_id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'user', recordId: req.params.id, detail: `MFA enrollment reset by administrator (${result.affectedRows} method(s) removed)`, ip: req.ip });
  await createNotification({
    userId: req.params.id,
    type: 'mfa_reset',
    title: 'Your MFA enrollment was reset',
    body: 'You will be asked to set up multi-factor authentication again next time it is required.',
    relatedRecordType: 'user',
    relatedRecordId: req.params.id,
  });
  return ok(res, { methodsRemoved: result.affectedRows }, 'MFA enrollment reset');
}));

/** GET /api/users/groups */
router.get('/groups/all', allowRoles('System Administrator', 'Records Manager'), asyncHandler(async (req, res) => {
  const [groups] = await pool.query('SELECT * FROM groups ORDER BY name');
  const [members] = await pool.query(
    `SELECT gm.group_id, u.id, u.full_name FROM group_members gm JOIN users u ON u.id = gm.user_id`
  );
  const withMembers = groups.map((g) => ({ ...g, members: members.filter((m) => m.group_id === g.id) }));
  return ok(res, withMembers);
}));

/** POST /api/users/groups/:groupId/members — { userId } */
router.post('/groups/:groupId/members', allowRoles('System Administrator', 'Records Manager'), asyncHandler(async (req, res) => {
  await pool.query('INSERT IGNORE INTO group_members (group_id, user_id) VALUES (?, ?)', [req.params.groupId, req.body.userId]);
  await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'group', recordId: req.params.groupId, detail: `Added user ${req.body.userId}`, ip: req.ip });
  return ok(res, null, 'Member added');
}));

/** PUT /api/users/me — self-service profile update (name, phone). */
router.put(
  '/me',
  [body('fullName').optional().trim().notEmpty(), body('phoneNumber').optional().trim()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { fullName, phoneNumber } = req.body;
    await pool.query(
      'UPDATE users SET full_name = COALESCE(?, full_name), phone_number = COALESCE(?, phone_number) WHERE id = ?',
      [fullName || null, phoneNumber || null, req.user.id]
    );
    return ok(res, null, 'Profile updated');
  })
);

/** PUT /api/users/me/password */
router.put(
  '/me/password',
  [body('currentPassword').notEmpty(), body('newPassword').isLength({ min: 10 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[user]] = await pool.query('SELECT password_hash FROM users WHERE id = ?', [req.user.id]);
    const currentOk = user.password_hash && (await bcrypt.compare(req.body.currentPassword, user.password_hash));
    if (!currentOk) return fail(res, 'Current password is incorrect', 401);

    const newHash = await bcrypt.hash(req.body.newPassword, 12);
    await pool.query('UPDATE users SET password_hash = ?, password_changed_at = NOW() WHERE id = ?', [newHash, req.user.id]);
    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'user', recordId: req.user.id, detail: 'Password changed', ip: req.ip });
    return ok(res, null, 'Password changed');
  })
);

module.exports = router;
