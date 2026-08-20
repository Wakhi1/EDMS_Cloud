/**
 * middleware/platformAuth.middleware.js
 * Verifies a platform-admin access token. Deliberately mirrors
 * middleware/auth.middleware.js's shape but is otherwise fully separate:
 * different secret (PLATFORM_JWT_ACCESS_SECRET, never JWT_ACCESS_SECRET),
 * different table (platform_admins, never users/roles), and sets
 * req.platformAdmin (never req.user) — so a tenant user's token can never
 * verify here even under a routing mistake, and a handler reading
 * req.platformAdmin vs req.user is unambiguous about which identity space
 * it's operating in.
 */
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { fail } = require('../utils/apiResponse');
const logger = require('../config/logger');

async function authenticatePlatformAdmin(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return fail(res, 'Authentication token missing', 401);

    const payload = jwt.verify(token, process.env.PLATFORM_JWT_ACCESS_SECRET);

    const [rows] = await pool.query(
      `SELECT id, full_name, email, is_owner, is_active, is_locked FROM platform_admins WHERE id = ? LIMIT 1`,
      [payload.sub]
    );
    const admin = rows[0];
    if (!admin || !admin.is_active || admin.is_locked) {
      return fail(res, 'Account is not active', 401);
    }

    req.platformAdmin = {
      id: admin.id,
      fullName: admin.full_name,
      email: admin.email,
      isOwner: !!admin.is_owner,
    };
    return next();
  } catch (err) {
    logger.warn('Platform-admin JWT verification failed', { error: err.message });
    return fail(res, 'Invalid or expired token', 401);
  }
}

module.exports = { authenticatePlatformAdmin };
