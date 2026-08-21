/**
 * routes/auth.routes.js
 * Registration, password login, refresh/logout, and social sign-in
 * (Google / Microsoft). Business logic lives inline in the route
 * handlers per project convention (no separate controllers layer);
 * shared work is delegated to services/.
 */
const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const logger = require('../config/logger');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { logAudit } = require('../services/audit.service');
const { verifyGoogleIdToken, verifyMicrosoftIdToken } = require('../services/socialAuth.service');
const adService = require('../services/ad.service');
const { sendPasswordResetEmail } = require('../services/email.service');
const { authenticate } = require('../middleware/auth.middleware');
const { checkDeploymentLicense, HOME_COMPANY_ID } = require('../services/license.service');

const router = express.Router();

function signAccessToken(user, mfaSatisfied) {
  return jwt.sign(
    { sub: user.id, role: user.role_name, mfa: mfaSatisfied, cid: user.company_id },
    process.env.JWT_ACCESS_SECRET,
    { expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m' }
  );
}

async function issueRefreshToken(userId, companyId, req, mfaSatisfied) {
  const sessionId = uuidv4();
  const refreshToken = jwt.sign(
    { sub: userId, sid: sessionId },
    process.env.JWT_REFRESH_SECRET,
    { expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d' }
  );
  const refreshHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
  const expiresAt = new Date(Date.now() + 7 * 24 * 3600 * 1000);

  await pool.query(
    `INSERT INTO user_sessions (id, user_id, company_id, refresh_token_hash, user_agent, ip_address, mfa_satisfied, expires_at)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
    [sessionId, userId, companyId, refreshHash, req.headers['user-agent'] || null, req.ip, mfaSatisfied ? 1 : 0, expiresAt]
  );
  return refreshToken;
}

// This deployment is single-tenant — docsecure-platform-provider owns
// company identity outright (see services/license.service.js). Every
// user row here still carries a company_id (HOME_COMPANY_ID), but it's
// no longer a foreign key to anything local; companyCode on the wire
// (register/login bodies below) is accepted for backward compatibility
// with the existing request shape but no longer used to look anything
// up — there's nothing local left to disambiguate against.

/**
 * POST /api/auth/register
 * Self-registration is typically disabled in production (accounts are
 * provisioned by a System Administrator / synced from Active Directory);
 * kept here for a working dev/demo flow.
 */
router.post(
  '/register',
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
    const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
    if (existing.length) return fail(res, 'An account with this email already exists', 409);

    const passwordHash = await bcrypt.hash(password, 12);
    const [result] = await pool.query(
      `INSERT INTO users (company_id, full_name, email, phone_number, password_hash, role_id, department_id, password_changed_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, NOW())`,
      [HOME_COMPANY_ID, fullName, email, phoneNumber || null, passwordHash, roleId, departmentId || null]
    );

    await logAudit({ userId: result.insertId, companyId: HOME_COMPANY_ID, action: 'Create', recordType: 'user', recordId: result.insertId, detail: 'Account registered', ip: req.ip });
    return ok(res, { userId: result.insertId }, 'Account created', 201);
  })
);

/**
 * POST /api/auth/login
 * Password login. If the resolved role requires MFA (or the user has
 * MFA enabled), returns { mfaRequired: true, mfaToken } instead of full
 * tokens — the client then calls /api/mfa/verify with that token.
 */
router.post(
  '/login',
  [body('companyCode').optional().trim(), body('email').isEmail(), body('password').notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    // companyCode is accepted (frontend still sends it) but no longer
    // used to look anything up — this deployment is single-tenant, and
    // its license (not a local companies row) is what's actually being
    // verified below.
    const { email, password } = req.body;
    const [rows] = await pool.query(
      `SELECT u.*, r.name AS role_name, r.mfa_required
       FROM users u
       JOIN roles r ON r.id = u.role_id
       WHERE u.email = ? LIMIT 1`,
      [email]
    );
    const user = rows[0];

    if (!user || !user.password_hash) {
      await logAudit({ action: 'Login failed', recordType: 'user', recordId: email, detail: 'Unknown account', ip: req.ip });
      return fail(res, 'Invalid organization code, email, or password', 401);
    }
    if (user.is_locked) return fail(res, 'Account is locked — contact your System Administrator', 423);

    const passwordOk = await bcrypt.compare(password, user.password_hash);
    if (!passwordOk) {
      await pool.query('UPDATE users SET failed_login_attempts = failed_login_attempts + 1 WHERE id = ?', [user.id]);
      await logAudit({ userId: user.id, companyId: user.company_id, action: 'Login failed', recordType: 'user', recordId: user.id, detail: 'Bad password', ip: req.ip });
      return fail(res, 'Invalid organization code, email, or password', 401);
    }

    const licenseCheck = await checkDeploymentLicense('login');
    if (!licenseCheck.ok) {
      await logAudit({ userId: user.id, companyId: user.company_id, action: 'Login failed', recordType: 'user', recordId: user.id, detail: `License check failed: ${licenseCheck.reason}`, ip: req.ip });
      return fail(res, 'This deployment\'s license is not active. Contact your administrator.', 403);
    }

    await pool.query('UPDATE users SET failed_login_attempts = 0, last_login_at = NOW(), last_login_ip = ? WHERE id = ?', [req.ip, user.id]);

    const mfaMandatory = !!user.mfa_required || !!user.mfa_enabled;
    if (mfaMandatory) {
      const mfaToken = jwt.sign({ sub: user.id, stage: 'mfa_pending' }, process.env.JWT_ACCESS_SECRET, { expiresIn: '10m' });
      await logAudit({ userId: user.id, companyId: user.company_id, action: 'Login', recordType: 'user', recordId: user.id, detail: 'Password OK, MFA challenge issued', ip: req.ip });
      return ok(res, { mfaRequired: true, mfaToken }, 'MFA verification required');
    }

    const accessToken = signAccessToken(user, false);
    const refreshToken = await issueRefreshToken(user.id, user.company_id, req, false);
    await logAudit({ userId: user.id, companyId: user.company_id, action: 'Login', recordType: 'user', recordId: user.id, detail: 'Login successful', ip: req.ip });

    return ok(res, {
      accessToken, refreshToken,
      user: { id: user.id, fullName: user.full_name, email: user.email, role: user.role_name },
    }, 'Logged in');
  })
);

/**
 * POST /api/auth/refresh
 * Rotates a refresh token for a new access token.
 */
router.post(
  '/refresh',
  asyncHandler(async (req, res) => {
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

    const [rows] = await pool.query(
      `SELECT u.*, r.name AS role_name FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = ?`,
      [payload.sub]
    );
    const user = rows[0];
    if (!user || !user.is_active || user.is_locked) return fail(res, 'Account is not active', 401);
    if (sessions[0].company_id !== user.company_id) return fail(res, 'Session is out of date — please sign in again', 401);

    const accessToken = signAccessToken(user, !!sessions[0].mfa_satisfied);
    return ok(res, { accessToken }, 'Token refreshed');
  })
);

/** POST /api/auth/logout — revokes the current refresh session. */
router.post(
  '/logout',
  asyncHandler(async (req, res) => {
    const { refreshToken } = req.body;
    if (refreshToken) {
      try {
        const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
        await pool.query('UPDATE user_sessions SET revoked_at = NOW() WHERE id = ?', [payload.sid]);
        await logAudit({ userId: payload.sub, action: 'Logout', recordType: 'user', recordId: payload.sub, ip: req.ip });
      } catch {
        // token already invalid — nothing to revoke
      }
    }
    return ok(res, null, 'Logged out');
  })
);

/**
 * POST /api/auth/google
 * Body: { idToken } — the ID token from Google Identity Services on the
 * frontend. Creates the account on first sign-in ("just-in-time" linking).
 */
router.post(
  '/google',
  asyncHandler(async (req, res) => socialSignIn(req, res, verifyGoogleIdToken, 'google'))
);

/**
 * POST /api/auth/microsoft
 * Body: { idToken } — the ID token from MSAL.js / Microsoft Entra ID on
 * the frontend.
 */
router.post(
  '/microsoft',
  asyncHandler(async (req, res) => socialSignIn(req, res, verifyMicrosoftIdToken, 'microsoft'))
);

/**
 * POST /api/auth/ad
 * Body: { email, password } — the user's directory (domain) credentials,
 * verified via a real LDAP bind against the configured Active Directory
 * server (services/ad.service.js), not a redirect/token flow like Google/
 * Microsoft above. Same fail-closed linking-by-email as socialSignIn: a
 * successful directory bind only signs someone in if a matching EDMS
 * account already exists.
 */
router.post(
  '/ad',
  [body('email').isEmail(), body('password').notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { email, password } = req.body;
    const config = await adService.getAdConfig();
    const result = await adService.authenticateUser(email, password, config);
    if (!result.ok) {
      await logAudit({ action: 'Login failed', recordType: 'user', recordId: email, detail: `AD bind failed: ${result.message}`, ip: req.ip });
      return fail(res, 'Invalid email or password', 401);
    }

    const profile = { providerUserId: result.providerUserId, email, raw: result.raw };
    return completeFederatedSignIn(req, res, profile, 'active_directory');
  })
);

async function socialSignIn(req, res, verifyFn, providerName) {
  const { idToken } = req.body;
  if (!idToken) return fail(res, 'idToken is required', 400);

  const profile = await verifyFn(idToken);
  if (!profile.emailVerified) return fail(res, 'Email on the identity provider is not verified', 401);

  return completeFederatedSignIn(req, res, profile, providerName);
}

/**
 * Shared tail for every federated (non-password) sign-in method — Google,
 * Microsoft, and Active Directory all funnel here once the identity
 * provider itself has confirmed `profile.email`/`profile.providerUserId`.
 * Deliberately fail-closed: a first-time identity is linked only to an
 * EXISTING account matched by email, never auto-created with a default
 * role — provisioning stays an explicit System Administrator action
 * (Users & Groups), regardless of which external identity a user proves.
 */
async function completeFederatedSignIn(req, res, profile, providerName) {
  const [identityRows] = await pool.query(
    `SELECT u.*, r.name AS role_name, r.mfa_required
     FROM user_social_identities si
     JOIN users u ON u.id = si.user_id
     JOIN roles r ON r.id = u.role_id
     WHERE si.provider = ? AND si.provider_user_id = ? LIMIT 1`,
    [providerName, profile.providerUserId]
  );

  let user = identityRows[0];

  if (!user) {
    // First-time sign-in with this provider: link to an existing account
    // by email, or fail closed — new EDMS accounts must be provisioned
    // by an administrator with an explicit role, never auto-created with
    // a default privileged role.
    const [byEmail] = await pool.query(
      `SELECT u.*, r.name AS role_name, r.mfa_required FROM users u JOIN roles r ON r.id = u.role_id WHERE u.email = ? LIMIT 1`,
      [profile.email]
    );
    if (!byEmail[0]) {
      return fail(res, 'No PSPF EDMS account exists for this identity. Ask a System Administrator to provision one.', 403);
    }
    user = byEmail[0];
    await pool.query(
      `INSERT INTO user_social_identities (company_id, user_id, provider, provider_user_id, provider_email, raw_profile_json)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [user.company_id, user.id, providerName, profile.providerUserId, profile.email, JSON.stringify(profile.raw)]
    );
  }

  if (!user.is_active || user.is_locked) return fail(res, 'Account is not active', 401);

  const licenseCheck = await checkDeploymentLicense('login');
  if (!licenseCheck.ok) {
    await logAudit({ userId: user.id, companyId: user.company_id, action: 'Login failed', recordType: 'user', recordId: user.id, detail: `License check failed: ${licenseCheck.reason}`, ip: req.ip });
    return fail(res, 'This deployment\'s license is not active. Contact your administrator.', 403);
  }

  const mfaMandatory = !!user.mfa_required || !!user.mfa_enabled;
  if (mfaMandatory) {
    const mfaToken = jwt.sign({ sub: user.id, stage: 'mfa_pending' }, process.env.JWT_ACCESS_SECRET, { expiresIn: '10m' });
    await logAudit({ userId: user.id, companyId: user.company_id, action: 'Login', recordType: 'user', recordId: user.id, detail: `${providerName} sign-in, MFA challenge issued`, ip: req.ip });
    return ok(res, { mfaRequired: true, mfaToken }, 'MFA verification required');
  }

  const accessToken = signAccessToken(user, false);
  const refreshToken = await issueRefreshToken(user.id, user.company_id, req, false);
  await pool.query('UPDATE users SET last_login_at = NOW(), last_login_ip = ? WHERE id = ?', [req.ip, user.id]);
  await logAudit({ userId: user.id, companyId: user.company_id, action: 'Login', recordType: 'user', recordId: user.id, detail: `${providerName} sign-in successful`, ip: req.ip });

  return ok(res, {
    accessToken, refreshToken,
    user: { id: user.id, fullName: user.full_name, email: user.email, role: user.role_name },
  }, 'Logged in');
}

/** POST /api/auth/password-reset/request */
router.post(
  '/password-reset/request',
  asyncHandler(async (req, res) => {
    const { email } = req.body;
    const [rows] = await pool.query(`SELECT id FROM users WHERE email = ? LIMIT 1`, [email]);
    // Always respond 200 to avoid leaking which emails are registered.
    if (rows[0]) {
      const token = jwt.sign({ sub: rows[0].id, purpose: 'password_reset' }, process.env.JWT_ACCESS_SECRET, { expiresIn: '30m' });
      const link = `${process.env.CLIENT_URL}/reset-password?token=${token}`;
      await sendPasswordResetEmail(email, link);
      logger.info('Password reset link issued', { userId: rows[0].id });
    }
    return ok(res, null, 'If that account exists, a reset link has been sent');
  })
);

/** POST /api/auth/password-reset/confirm */
router.post(
  '/password-reset/confirm',
  [body('token').notEmpty(), body('newPassword').isLength({ min: 10 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { token, newPassword } = req.body;
    let payload;
    try {
      payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    } catch {
      return fail(res, 'Reset link is invalid or expired', 400);
    }
    if (payload.purpose !== 'password_reset') return fail(res, 'Invalid token', 400);

    const passwordHash = await bcrypt.hash(newPassword, 12);
    await pool.query('UPDATE users SET password_hash = ?, password_changed_at = NOW() WHERE id = ?', [passwordHash, payload.sub]);
    await pool.query('UPDATE user_sessions SET revoked_at = NOW() WHERE user_id = ? AND revoked_at IS NULL', [payload.sub]);
    await logAudit({ userId: payload.sub, action: 'Edit', recordType: 'user', recordId: payload.sub, detail: 'Password reset', ip: req.ip });

    return ok(res, null, 'Password updated — please sign in again');
  })
);

/** GET /api/auth/me */
router.get('/me', authenticate, asyncHandler(async (req, res) => ok(res, req.user)));

module.exports = router;
