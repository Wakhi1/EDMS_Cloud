/**
 * middleware/auth.middleware.js
 * Verifies the JWT access token, loads the user + role, and enforces
 * that roles flagged mfa_required actually completed MFA on this session.
 */
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { fail } = require('../utils/apiResponse');
const logger = require('../config/logger');

async function authenticate(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return fail(res, 'Authentication token missing', 401);

    const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET);

    const [rows] = await pool.query(
      `SELECT u.id, u.company_id, u.full_name, u.email, u.is_active, u.is_locked, u.mfa_enabled,
              r.id AS role_id, r.name AS role_name, r.mfa_required
       FROM users u JOIN roles r ON r.id = u.role_id
       WHERE u.id = ? LIMIT 1`,
      [payload.sub]
    );
    const user = rows[0];
    if (!user || !user.is_active || user.is_locked) {
      return fail(res, 'Account is not active', 401);
    }
    // Defense in depth: catches a token minted before a user's company
    // was reassigned (mirrors the fresh role re-fetch above) — should
    // never actually differ in normal operation.
    if (payload.cid !== user.company_id) {
      return fail(res, 'Session is out of date — please sign in again', 401);
    }
    if (user.mfa_required && !payload.mfa) {
      return fail(res, 'Multi-factor authentication is required for this role', 401);
    }

    req.user = {
      id: user.id,
      companyId: user.company_id,
      fullName: user.full_name,
      email: user.email,
      roleId: user.role_id,
      role: user.role_name,
      mfaSatisfied: !!payload.mfa,
    };
    return next();
  } catch (err) {
    logger.warn('JWT verification failed', { error: err.message });
    return fail(res, 'Invalid or expired token', 401);
  }
}

module.exports = { authenticate };
