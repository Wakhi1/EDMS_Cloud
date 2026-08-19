/**
 * middleware/apiKey.middleware.js
 * Validates the sandbox credential itself (X-Api-Key header) — distinct
 * from being logged into the website. Only requests that actually
 * EXECUTE against the target EDMS environment require this; browsing
 * the sandbox catalog only requires a normal session (see auth.middleware).
 */
const { pool } = require('../config/db');
const { hashApiKey } = require('../services/apiKey.service');
const { fail } = require('../utils/apiResponse');

async function requireApiKey(req, res, next) {
  const key = req.headers['x-api-key'];
  if (!key) return fail(res, 'X-Api-Key header is required to execute sandbox requests', 401);

  const hash = hashApiKey(key);
  const [rows] = await pool.query(
    `SELECT ak.*, u.status AS user_status FROM api_keys ak JOIN users u ON u.id = ak.user_id
     WHERE ak.key_hash = ? AND ak.revoked_at IS NULL LIMIT 1`,
    [hash]
  );
  const apiKey = rows[0];
  if (!apiKey) return fail(res, 'API key is invalid or has been revoked', 401);
  if (apiKey.user_status !== 'approved') return fail(res, 'The account this key belongs to is not approved', 403);
  if (req.user && req.user.id !== apiKey.user_id) return fail(res, 'This API key does not belong to the signed-in account', 403);

  await pool.query('UPDATE api_keys SET last_used_at = NOW() WHERE id = ?', [apiKey.id]);
  req.apiKey = apiKey;
  return next();
}

module.exports = { requireApiKey };
