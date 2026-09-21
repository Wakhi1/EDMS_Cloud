/**
 * middleware/apiKey.middleware.js
 * Auth for headless callers that can't hold a normal 15-minute JWT session
 * — today, only the local watched-folder agent (routes/agentUpload.routes.js).
 * Reads the `X-Api-Key` header, hashes it, and looks it up in `api_keys`.
 * On success, req.user is populated from the key's owning (created_by)
 * user, same shape as auth.middleware.js's authenticate, so downstream
 * code (runBatch, logAudit) doesn't need to know the caller wasn't a
 * logged-in session.
 */
const crypto = require('crypto');
const { pool } = require('../config/db');
const { fail } = require('../utils/apiResponse');

function hashKey(rawKey) {
  return crypto.createHash('sha256').update(rawKey).digest('hex');
}

async function authenticateApiKey(req, res, next) {
  try {
    const rawKey = req.header('X-Api-Key');
    if (!rawKey) return fail(res, 'API key missing', 401);

    const [[key]] = await pool.query(
      `SELECT ak.id, ak.company_id, ak.scope, ak.revoked_at, u.id AS user_id, u.full_name, u.email, u.is_active, u.is_locked
       FROM api_keys ak JOIN users u ON u.id = ak.created_by
       WHERE ak.key_hash = ? LIMIT 1`,
      [hashKey(rawKey)]
    );
    if (!key || key.revoked_at || !key.is_active || key.is_locked) {
      return fail(res, 'Invalid or revoked API key', 401);
    }

    req.user = {
      id: key.user_id,
      companyId: key.company_id,
      fullName: key.full_name,
      email: key.email,
      role: 'api_key',
    };
    req.apiKey = { id: key.id, scope: key.scope };

    pool.query('UPDATE api_keys SET last_used_at = NOW() WHERE id = ?', [key.id]).catch(() => {});
    return next();
  } catch (err) {
    return next(err);
  }
}

module.exports = { authenticateApiKey, hashKey };
