/**
 * routes/admin.routes.js
 * Everything an admin does that a developer can't: approve/reject
 * accounts, issue/revoke API keys, and review sandbox usage. Uploading
 * docs/media lives in media.routes.js and content.routes.js (also
 * admin-gated) to keep this file focused on account administration.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate, requireAdmin } = require('../middleware/auth.middleware');
const { generateApiKey } = require('../services/apiKey.service');
const { logAudit } = require('../services/audit.service');
const { sendApiKeyEmail } = require('../services/email.service');

const router = express.Router();
router.use(authenticate, requireAdmin);

/** GET /api/admin/developers?status=pending */
router.get('/developers', asyncHandler(async (req, res) => {
  const { status } = req.query;
  const clauses = [`role = 'developer'`];
  const params = [];
  if (status) { clauses.push('status = ?'); params.push(status); }

  const [rows] = await pool.query(
    `SELECT id, full_name, email, company, reason, status, created_at, approved_at,
            (SELECT COUNT(*) FROM api_keys WHERE user_id = users.id AND revoked_at IS NULL) AS active_keys
     FROM users WHERE ${clauses.join(' AND ')} ORDER BY created_at DESC`,
    params
  );
  return ok(res, rows);
}));

/** PUT /api/admin/developers/:id/approve */
router.put('/developers/:id/approve', asyncHandler(async (req, res) => {
  const [result] = await pool.query(
    `UPDATE users SET status = 'approved', approved_by = ?, approved_at = NOW() WHERE id = ? AND role = 'developer'`,
    [req.user.id, req.params.id]
  );
  if (!result.affectedRows) return fail(res, 'Developer account not found', 404);

  await logAudit({ actorUserId: req.user.id, action: 'Approve', recordType: 'user', recordId: req.params.id, ip: req.ip });
  return ok(res, null, 'Developer approved — issue an API key next so they can use the sandbox');
}));

/** PUT /api/admin/developers/:id/reject */
router.put('/developers/:id/reject', asyncHandler(async (req, res) => {
  const [result] = await pool.query(`UPDATE users SET status = 'rejected' WHERE id = ? AND role = 'developer'`, [req.params.id]);
  if (!result.affectedRows) return fail(res, 'Developer account not found', 404);
  await logAudit({ actorUserId: req.user.id, action: 'Reject', recordType: 'user', recordId: req.params.id, ip: req.ip });
  return ok(res, null, 'Developer account rejected');
}));

/** PUT /api/admin/developers/:id/suspend — revokes portal access for an already-approved account. */
router.put('/developers/:id/suspend', asyncHandler(async (req, res) => {
  const [result] = await pool.query(`UPDATE users SET status = 'suspended' WHERE id = ? AND role = 'developer'`, [req.params.id]);
  if (!result.affectedRows) return fail(res, 'Developer account not found', 404);
  await logAudit({ actorUserId: req.user.id, action: 'Suspend', recordType: 'user', recordId: req.params.id, ip: req.ip });
  return ok(res, null, 'Developer account suspended');
}));

/**
 * POST /api/admin/developers/:id/api-keys
 * Issues a new sandbox API key for an APPROVED developer and emails it
 * to them directly. Still returns the plaintext key in the response
 * too (shown once) — if SMTP isn't configured or the send fails, the
 * admin can still relay it manually rather than being stuck.
 */
router.post(
  '/developers/:id/api-keys',
  [body('label').optional().trim()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[developer]] = await pool.query(`SELECT id, full_name, email, status FROM users WHERE id = ? AND role = 'developer'`, [req.params.id]);
    if (!developer) return fail(res, 'Developer account not found', 404);
    if (developer.status !== 'approved') return fail(res, 'Approve the developer before issuing an API key', 409);

    const label = req.body.label || 'Sandbox key';
    const { plaintext, prefix, hash } = generateApiKey();
    const [result] = await pool.query(
      `INSERT INTO api_keys (user_id, label, key_prefix, key_hash, issued_by) VALUES (?, ?, ?, ?, ?)`,
      [developer.id, label, prefix, hash, req.user.id]
    );

    await logAudit({ actorUserId: req.user.id, action: 'Issue API key', recordType: 'api_key', recordId: result.insertId, detail: `For user ${developer.id}`, ip: req.ip });

    let emailSent = false;
    let emailError = null;
    try {
      await sendApiKeyEmail({
        to: developer.email,
        fullName: developer.full_name,
        apiKey: plaintext,
        label,
        portalUrl: process.env.CLIENT_URL,
      });
      emailSent = true;
      await logAudit({ actorUserId: req.user.id, action: 'Email API key', recordType: 'api_key', recordId: result.insertId, detail: `Sent to ${developer.email}`, ip: req.ip });
    } catch (err) {
      emailError = err.code === 'SMTP_NOT_CONFIGURED' ? 'SMTP is not configured on this server' : err.message;
    }

    return ok(
      res,
      { id: result.insertId, apiKey: plaintext, prefix, emailSent, emailError, email: developer.email },
      emailSent ? `API key issued and emailed to ${developer.email}` : 'API key issued — shown once, copy it now (email delivery was not available)',
      201
    );
  })
);

/** DELETE /api/admin/api-keys/:id — revoke a key. */
router.delete('/api-keys/:id', asyncHandler(async (req, res) => {
  const [result] = await pool.query('UPDATE api_keys SET revoked_at = NOW() WHERE id = ? AND revoked_at IS NULL', [req.params.id]);
  if (!result.affectedRows) return fail(res, 'API key not found or already revoked', 404);
  await logAudit({ actorUserId: req.user.id, action: 'Revoke API key', recordType: 'api_key', recordId: req.params.id, ip: req.ip });
  return ok(res, null, 'API key revoked');
}));

/** GET /api/admin/sandbox-usage — recent sandbox activity across all developers. */
router.get('/sandbox-usage', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT l.*, u.full_name, u.email, k.label AS key_label, k.key_prefix
     FROM sandbox_request_logs l
     JOIN users u ON u.id = l.user_id
     JOIN api_keys k ON k.id = l.api_key_id
     ORDER BY l.created_at DESC LIMIT 300`
  );
  return ok(res, rows);
}));

/** GET /api/admin/audit-log */
router.get('/audit-log', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT a.*, u.full_name AS actor_name FROM audit_log a LEFT JOIN users u ON u.id = a.actor_user_id ORDER BY a.id DESC LIMIT 300`
  );
  return ok(res, rows);
}));

/**
 * Environments — where the sandbox proxy is allowed to send calls.
 * This is the actual answer to "we're going to deploy this, localhost
 * won't work": rather than a hardcoded URL anywhere in code, every
 * target is a row here that an admin adds/edits after deployment,
 * with the destination validated server-side (see sandbox.routes.js)
 * so a developer can never point a call at an arbitrary host.
 */

/** GET /api/admin/sandbox-environments */
router.get('/sandbox-environments', asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM sandbox_environments ORDER BY is_default DESC, name');
  return ok(res, rows);
}));

/** POST /api/admin/sandbox-environments — add a new one. */
router.post(
  '/sandbox-environments',
  [body('name').trim().notEmpty(), body('baseUrl').trim().notEmpty().matches(/^https?:\/\//).withMessage('baseUrl must start with http:// or https://')],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { name, baseUrl, isDefault } = req.body;
    if (isDefault) await pool.query('UPDATE sandbox_environments SET is_default = 0');
    const [result] = await pool.query('INSERT INTO sandbox_environments (name, base_url, is_default) VALUES (?, ?, ?)', [name, baseUrl, isDefault ? 1 : 0]);
    await logAudit({ actorUserId: req.user.id, action: 'Create', recordType: 'sandbox_environment', recordId: result.insertId, detail: `${name} -> ${baseUrl}`, ip: req.ip });
    return ok(res, { id: result.insertId }, 'Environment added', 201);
  })
);

/** PUT /api/admin/sandbox-environments/:id — edit name/URL, or set as the default. */
router.put(
  '/sandbox-environments/:id',
  [body('name').optional().trim().notEmpty(), body('baseUrl').optional().trim().matches(/^https?:\/\//).withMessage('baseUrl must start with http:// or https://')],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[existing]] = await pool.query('SELECT * FROM sandbox_environments WHERE id = ?', [req.params.id]);
    if (!existing) return fail(res, 'Environment not found', 404);

    const { name, baseUrl, isDefault } = req.body;
    if (isDefault) await pool.query('UPDATE sandbox_environments SET is_default = 0');
    await pool.query(
      'UPDATE sandbox_environments SET name = COALESCE(?, name), base_url = COALESCE(?, base_url), is_default = COALESCE(?, is_default) WHERE id = ?',
      [name || null, baseUrl || null, isDefault === undefined ? null : (isDefault ? 1 : 0), req.params.id]
    );
    await logAudit({ actorUserId: req.user.id, action: 'Edit', recordType: 'sandbox_environment', recordId: req.params.id, detail: baseUrl || name || 'default changed', ip: req.ip });
    return ok(res, null, 'Environment updated');
  })
);

/** DELETE /api/admin/sandbox-environments/:id */
router.delete('/sandbox-environments/:id', asyncHandler(async (req, res) => {
  const [[existing]] = await pool.query('SELECT * FROM sandbox_environments WHERE id = ?', [req.params.id]);
  if (!existing) return fail(res, 'Environment not found', 404);

  const [[{ count }]] = await pool.query('SELECT COUNT(*) AS count FROM sandbox_environments');
  if (count <= 1) return fail(res, 'At least one environment must remain configured', 409);

  await pool.query('DELETE FROM sandbox_environments WHERE id = ?', [req.params.id]);
  if (existing.is_default) {
    await pool.query('UPDATE sandbox_environments SET is_default = 1 ORDER BY id LIMIT 1');
  }
  await logAudit({ actorUserId: req.user.id, action: 'Delete', recordType: 'sandbox_environment', recordId: req.params.id, detail: existing.name, ip: req.ip });
  return ok(res, null, 'Environment removed');
}));

module.exports = router;
