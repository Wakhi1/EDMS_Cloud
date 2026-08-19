/**
 * routes/auth.routes.js
 * Registration (developer accounts start 'pending'), login, refresh,
 * logout, profile, and a self-service view of your own API keys
 * (issuing/revoking those stays admin-only — see admin.routes.js).
 */
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { logAudit } = require('../services/audit.service');

const router = express.Router();

function signAccessToken(user) {
  return jwt.sign({ sub: user.id, role: user.role }, process.env.JWT_ACCESS_SECRET, { expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '30m' });
}

async function issueRefreshToken(userId, req) {
  const sessionId = uuidv4();
  const refreshToken = jwt.sign({ sub: userId, sid: sessionId }, process.env.JWT_REFRESH_SECRET, { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '14d' });
  const refreshHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
  await pool.query(
    `INSERT INTO user_sessions (id, user_id, refresh_token_hash, user_agent, ip_address, expires_at)
     VALUES (?, ?, ?, ?, ?, DATE_ADD(NOW(), INTERVAL 14 DAY))`,
    [sessionId, userId, refreshHash, req.headers['user-agent'] || null, req.ip]
  );
  return refreshToken;
}

/**
 * POST /api/auth/register
 * Creates a 'developer' account in 'pending' status. No session is
 * issued — nothing works until an admin approves the account (see
 * PUT /api/admin/developers/:id/approve) and issues an API key.
 */
router.post(
  '/register',
  [body('fullName').trim().notEmpty(), body('email').isEmail(), body('password').isLength({ min: 10 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { fullName, email, password, company, reason } = req.body;
    const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length) return fail(res, 'An account with this email already exists', 409);

    const passwordHash = await bcrypt.hash(password, 12);
    const [result] = await pool.query(
      `INSERT INTO users (full_name, email, password_hash, role, status, company, reason) VALUES (?, ?, ?, 'developer', 'pending', ?, ?)`,
      [fullName, email, passwordHash, company || null, reason || null]
    );

    await logAudit({ actorUserId: result.insertId, action: 'Register', recordType: 'user', recordId: result.insertId, ip: req.ip });
    return ok(res, { id: result.insertId }, 'Account created — an administrator needs to approve it before you can use the sandbox', 201);
  })
);

/** POST /api/auth/login */
router.post(
  '/login',
  [body('email').isEmail(), body('password').notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { email, password } = req.body;
    const [rows] = await pool.query('SELECT * FROM users WHERE email = ? LIMIT 1', [email]);
    const user = rows[0];
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
      return fail(res, 'Invalid email or password', 401);
    }
    if (user.status === 'rejected' || user.status === 'suspended') {
      return fail(res, 'This account does not have portal access', 403);
    }

    const accessToken = signAccessToken(user);
    const refreshToken = await issueRefreshToken(user.id, req);
    await logAudit({ actorUserId: user.id, action: 'Login', recordType: 'user', recordId: user.id, ip: req.ip });

    return ok(res, {
      accessToken, refreshToken,
      user: { id: user.id, fullName: user.full_name, email: user.email, role: user.role, status: user.status },
    }, 'Logged in');
  })
);

/** POST /api/auth/refresh */
router.post('/refresh', asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return fail(res, 'refreshToken is required', 400);

  let payload;
  try {
    payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
  } catch {
    return fail(res, 'Invalid or expired refresh token', 401);
  }

  const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
  const [sessions] = await pool.query(
    `SELECT * FROM user_sessions WHERE id = ? AND refresh_token_hash = ? AND revoked_at IS NULL AND expires_at > NOW()`,
    [payload.sid, tokenHash]
  );
  if (!sessions[0]) return fail(res, 'Session not found or revoked', 401);

  const [rows] = await pool.query('SELECT * FROM users WHERE id = ?', [payload.sub]);
  const user = rows[0];
  if (!user) return fail(res, 'Account not found', 401);

  return ok(res, { accessToken: signAccessToken(user) }, 'Token refreshed');
}));

/** POST /api/auth/logout */
router.post('/logout', asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;
  if (refreshToken) {
    try {
      const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
      await pool.query('UPDATE user_sessions SET revoked_at = NOW() WHERE id = ?', [payload.sid]);
    } catch {
      /* already invalid */
    }
  }
  return ok(res, null, 'Logged out');
}));

/** GET /api/auth/me */
router.get('/me', authenticate, asyncHandler(async (req, res) => ok(res, req.user)));

/** GET /api/auth/me/api-keys — masked list of your own sandbox keys. */
router.get('/me/api-keys', authenticate, asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT id, label, key_prefix, last_used_at, revoked_at, created_at FROM api_keys WHERE user_id = ? ORDER BY created_at DESC`,
    [req.user.id]
  );
  return ok(res, rows);
}));

module.exports = router;
