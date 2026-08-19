/**
 * middleware/auth.middleware.js
 * Session auth (JWT access token) — governs access to the docs portal
 * website itself: registering, browsing the sandbox catalog, managing
 * your own profile. This is DIFFERENT from an API key (see
 * apiKey.middleware.js), which governs whether a sandbox call is
 * actually allowed to execute.
 */
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const { fail } = require('../utils/apiResponse');

async function authenticate(req, res, next) {
  try {
    const header = req.headers.authorization || '';
    const token = header.startsWith('Bearer ') ? header.slice(7) : null;
    if (!token) return fail(res, 'Authentication token missing', 401);

    const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    const [rows] = await pool.query('SELECT id, full_name, email, role, status FROM users WHERE id = ? LIMIT 1', [payload.sub]);
    const user = rows[0];
    if (!user) return fail(res, 'Account not found', 401);
    if (user.status === 'suspended' || user.status === 'rejected') return fail(res, 'Account access has been revoked', 403);

    req.user = user;
    return next();
  } catch {
    return fail(res, 'Invalid or expired token', 401);
  }
}

function requireAdmin(req, res, next) {
  if (!req.user || req.user.role !== 'admin') return fail(res, 'Admin access required', 403);
  return next();
}

function requireApprovedDeveloper(req, res, next) {
  if (!req.user) return fail(res, 'Authentication required', 401);
  if (req.user.role === 'admin') return next();
  if (req.user.status !== 'approved') return fail(res, 'Your developer account is not approved yet', 403);
  return next();
}

module.exports = { authenticate, requireAdmin, requireApprovedDeveloper };
