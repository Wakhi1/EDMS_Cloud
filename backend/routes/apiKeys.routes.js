/**
 * routes/apiKeys.routes.js
 * Admin management of long-lived API keys — today, only used to mint
 * credentials for the local watched-folder agent (see /local-agent and
 * routes/agentUpload.routes.js). Gated behind the 'integrations' module,
 * same governance surface as every other automated intake connector.
 *
 * The raw key is only ever returned once, at creation time (POST) — only
 * its sha256 hash is stored, same principle as a password. Losing it means
 * revoking and creating a new one; there is no "reveal" endpoint.
 */
const express = require('express');
const crypto = require('crypto');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { hashKey } = require('../middleware/apiKey.middleware');

const router = express.Router();
router.use(authenticate);

/** GET /api/api-keys — masked listing, never the raw key or its hash. */
router.get('/', requireModuleAccess('integrations'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT ak.id, ak.name, ak.key_prefix, ak.scope, ak.last_used_at, ak.revoked_at, ak.created_at, u.full_name AS created_by
     FROM api_keys ak JOIN users u ON u.id = ak.created_by
     WHERE ak.company_id = ? ORDER BY ak.created_at DESC`,
    [req.user.companyId]
  );
  return ok(res, rows);
}));

/**
 * POST /api/api-keys — { name } → { id, name, apiKey }. The key is minted
 * against the *creating admin's own account*: it acts as them for
 * createdBy/audit purposes on every upload it authorises.
 */
router.post('/', requireModuleAccess('integrations', true), [body('name').trim().notEmpty()], asyncHandler(async (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

  const rawKey = `pspf_${crypto.randomBytes(24).toString('hex')}`;
  const keyPrefix = rawKey.slice(0, 12);

  const [result] = await pool.query(
    `INSERT INTO api_keys (company_id, name, key_prefix, key_hash, created_by) VALUES (?, ?, ?, ?, ?)`,
    [req.user.companyId, req.body.name, keyPrefix, hashKey(rawKey), req.user.id]
  );
  await logAudit({ userId: req.user.id, action: 'Create', recordType: 'api_key', recordId: result.insertId, detail: req.body.name, ip: req.ip });
  return ok(res, { id: result.insertId, name: req.body.name, apiKey: rawKey }, 'API key created — copy it now, it will not be shown again', 201);
}));

/** DELETE /api/api-keys/:id — revoke (never a hard delete, for audit history). */
router.delete('/:id', requireModuleAccess('integrations', true), asyncHandler(async (req, res) => {
  const [[key]] = await pool.query('SELECT id, name FROM api_keys WHERE id = ? AND company_id = ?', [req.params.id, req.user.companyId]);
  if (!key) return fail(res, 'API key not found', 404);

  await pool.query('UPDATE api_keys SET revoked_at = NOW() WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'api_key', recordId: req.params.id, detail: key.name, ip: req.ip });
  return ok(res, null, 'API key revoked');
}));

module.exports = router;
