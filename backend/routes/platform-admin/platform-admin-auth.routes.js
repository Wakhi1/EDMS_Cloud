/**
 * routes/platform-admin/platform-admin-auth.routes.js
 * Login/refresh/logout for DocSecore staff (platform_admins) — mirrors
 * routes/auth.routes.js's shape (bcrypt, uuid session id, sha256-hashed
 * refresh token at rest) against the fully separate platform_admins /
 * platform_admin_sessions tables and PLATFORM_JWT_* secrets. No MFA this
 * pass — see the note in the multi-tenant licensing plan.
 */
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');
const { body, validationResult } = require('express-validator');

const { pool } = require('../../config/db');
const { ok, fail } = require('../../utils/apiResponse');
const asyncHandler = require('../../utils/asyncHandler');
const { authenticatePlatformAdmin } = require('../../middleware/platformAuth.middleware');
const { logPlatformAudit } = require('../../services/platformAudit.service');

const router = express.Router();

function signAccessToken(admin) {
  return jwt.sign(
    { sub: admin.id, scope: 'platform_admin' },
    process.env.PLATFORM_JWT_ACCESS_SECRET,
    { expiresIn: process.env.PLATFORM_JWT_ACCESS_EXPIRES_IN || '15m' }
  );
}

async function issueRefreshToken(adminId, req) {
  const sessionId = uuidv4();
  const refreshToken = jwt.sign(
    { sub: adminId, sid: sessionId },
    process.env.PLATFORM_JWT_REFRESH_SECRET,
    { expiresIn: process.env.PLATFORM_JWT_REFRESH_EXPIRES_IN || '7d' }
  );
  const refreshHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
  const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000);

  await pool.query(
    `INSERT INTO platform_admin_sessions (id, platform_admin_id, refresh_token_hash, user_agent, ip_address, expires_at)
     VALUES (?, ?, ?, ?, ?, ?)`,
    [sessionId, adminId, refreshHash, req.headers['user-agent'] || null, req.ip, expiresAt]
  );
  return refreshToken;
}

/** POST /api/platform-admin/auth/login */
router.post(
  '/login',
  [body('email').isEmail(), body('password').notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { email, password } = req.body;
    const [rows] = await pool.query(`SELECT * FROM platform_admins WHERE email = ? LIMIT 1`, [email]);
    const admin = rows[0];

    if (!admin) return fail(res, 'Invalid email or password', 401);
    if (admin.is_locked) return fail(res, 'Account is locked', 423);

    const passwordOk = await bcrypt.compare(password, admin.password_hash);
    if (!passwordOk) {
      await pool.query('UPDATE platform_admins SET failed_login_attempts = failed_login_attempts + 1 WHERE id = ?', [admin.id]);
      return fail(res, 'Invalid email or password', 401);
    }
    if (!admin.is_active) return fail(res, 'Account is not active', 401);

    await pool.query('UPDATE platform_admins SET failed_login_attempts = 0, last_login_at = NOW(), last_login_ip = ? WHERE id = ?', [req.ip, admin.id]);

    const accessToken = signAccessToken(admin);
    const refreshToken = await issueRefreshToken(admin.id, req);
    await logPlatformAudit({ platformAdminId: admin.id, action: 'auth.login', ip: req.ip });

    return ok(res, {
      accessToken, refreshToken,
      admin: { id: admin.id, fullName: admin.full_name, email: admin.email, isOwner: !!admin.is_owner },
    }, 'Logged in');
  })
);

/** POST /api/platform-admin/auth/refresh */
router.post(
  '/refresh',
  asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    if (!refreshToken) return fail(res, 'refreshToken is required', 400);

    let payload;
    try {
      payload = jwt.verify(refreshToken, process.env.PLATFORM_JWT_REFRESH_SECRET);
    } catch {
      return fail(res, 'Invalid or expired refresh token', 401);
    }

    const tokenHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
    const [sessions] = await pool.query(
      `SELECT * FROM platform_admin_sessions WHERE id = ? AND refresh_token_hash = ? AND revoked_at IS NULL AND expires_at > NOW()`,
      [payload.sid, tokenHash]
    );
    if (!sessions[0]) return fail(res, 'Session not found or revoked', 401);

    const [rows] = await pool.query(`SELECT * FROM platform_admins WHERE id = ?`, [payload.sub]);
    const admin = rows[0];
    if (!admin || !admin.is_active || admin.is_locked) return fail(res, 'Account is not active', 401);

    const accessToken = signAccessToken(admin);
    return ok(res, { accessToken }, 'Token refreshed');
  })
);

/** POST /api/platform-admin/auth/logout */
router.post(
  '/logout',
  asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    if (refreshToken) {
      try {
        const payload = jwt.verify(refreshToken, process.env.PLATFORM_JWT_REFRESH_SECRET);
        await pool.query('UPDATE platform_admin_sessions SET revoked_at = NOW() WHERE id = ?', [payload.sid]);
      } catch {
        // token already invalid — nothing to revoke
      }
    }
    return ok(res, null, 'Logged out');
  })
);

/** GET /api/platform-admin/auth/me */
router.get('/me', authenticatePlatformAdmin, asyncHandler(async (req, res) => ok(res, req.platformAdmin)));

module.exports = router;
