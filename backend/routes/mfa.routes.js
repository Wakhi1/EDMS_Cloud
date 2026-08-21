/**
 * routes/mfa.routes.js
 * MFA enrolment (TOTP + backup codes) and login-time MFA verification
 * (TOTP / SMS / backup code) using the short-lived mfaToken issued by
 * /api/auth/login or /api/auth/{google,microsoft}.
 */
const express = require('express');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const crypto = require('crypto');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { logAudit } = require('../services/audit.service');
const { sendMfaOtpSms, isValidE164 } = require('../services/sms.service');
const { sendMfaOtpEmail } = require('../services/email.service');
const {
  generateTotpSecret, generateTotpQrDataUrl, verifyTotpToken,
  generateNumericCode, hashCode, generateBackupCodes, consumeBackupCode,
} = require('../services/mfa.service');

const router = express.Router();

function requireMfaStage(req, res, next) {
  const token = (req.headers.authorization || '').replace('Bearer ', '') || req.body.mfaToken;
  if (!token) return fail(res, 'mfaToken is required', 401);
  try {
    const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    if (payload.stage !== 'mfa_pending') return fail(res, 'Invalid MFA challenge token', 401);
    req.mfaUserId = payload.sub;
    return next();
  } catch {
    return fail(res, 'MFA challenge expired — sign in again', 401);
  }
}

async function completeMfaLogin(req, res, userId) {
  const [rows] = await pool.query(
    `SELECT u.*, r.name AS role_name FROM users u JOIN roles r ON r.id = u.role_id WHERE u.id = ?`,
    [userId]
  );
  const user = rows[0];
  const accessToken = jwt.sign({ sub: user.id, role: user.role_name, mfa: true, cid: user.company_id }, process.env.JWT_ACCESS_SECRET, {
    expiresIn: process.env.JWT_ACCESS_EXPIRES_IN || '15m',
  });

  const sessionId = uuidv4();
  const refreshToken = jwt.sign({ sub: user.id, sid: sessionId }, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES_IN || '7d',
  });
  const refreshHash = crypto.createHash('sha256').update(refreshToken).digest('hex');
  await pool.query(
    `INSERT INTO user_sessions (id, user_id, company_id, refresh_token_hash, user_agent, ip_address, mfa_satisfied, expires_at)
     VALUES (?, ?, ?, ?, ?, ?, 1, DATE_ADD(NOW(), INTERVAL 7 DAY))`,
    [sessionId, user.id, user.company_id, refreshHash, req.headers['user-agent'] || null, req.ip]
  );

  await pool.query('UPDATE users SET last_login_at = NOW(), last_login_ip = ? WHERE id = ?', [req.ip, user.id]);
  await logAudit({ userId: user.id, companyId: user.company_id, action: 'MFA', recordType: 'user', recordId: user.id, detail: 'MFA satisfied, login complete', ip: req.ip });

  return ok(res, {
    accessToken, refreshToken,
    user: { id: user.id, fullName: user.full_name, email: user.email, role: user.role_name },
  }, 'Logged in');
}

/* ---------------------------- Enrolment (authenticated) ---------------------------- */

/**
 * Shared by the self-service `/totp/enroll` (authenticated) route and the
 * mid-login `/challenge/totp/enroll` (mfa_pending) route below — the only
 * difference between those two flows is where the user id comes from.
 */
async function enrollTotpFor(userId, email, companyId) {
  const secret = generateTotpSecret(email);
  const qrDataUrl = await generateTotpQrDataUrl(secret.otpauth_url);

  await pool.query(
    `INSERT INTO user_mfa_methods (company_id, user_id, method_type, secret_encrypted, is_primary, is_verified)
     VALUES (?, ?, 'totp', ?, 1, 0)
     ON DUPLICATE KEY UPDATE secret_encrypted = VALUES(secret_encrypted), is_verified = 0`,
    [companyId, userId, Buffer.from(secret.base32)]
  );
  // NOTE: for production, encrypt secret_encrypted via services/crypto.service
  // (envelopeEncryptFile-style AES-256-GCM) rather than storing base32 plaintext.

  return { qrDataUrl, base32Secret: secret.base32 };
}

/** Returns true/false rather than responding — callers decide what happens next. */
async function confirmTotpFor(userId, token) {
  const [rows] = await pool.query(
    `SELECT id, secret_encrypted FROM user_mfa_methods WHERE user_id = ? AND method_type = 'totp' LIMIT 1`,
    [userId]
  );
  if (!rows[0]) return false;
  if (!verifyTotpToken(rows[0].secret_encrypted.toString(), token)) return false;

  await pool.query(`UPDATE user_mfa_methods SET is_verified = 1 WHERE id = ?`, [rows[0].id]);
  await pool.query(`UPDATE users SET mfa_enabled = 1 WHERE id = ?`, [userId]);
  return true;
}

/**
 * GET /api/mfa/status — self-service equivalent of `/challenge/status` for
 * an already signed-in user viewing the Security screen: whether their
 * TOTP enrolment is actually confirmed (not just started), and whether
 * they have backup codes. Lets the UI gate "generate backup codes" behind
 * a completed authenticator confirmation instead of leaving that silently
 * disconnected from enrolment state.
 */
router.get('/status', authenticate, asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT method_type, is_verified FROM user_mfa_methods WHERE user_id = ? AND method_type IN ('totp', 'backup_codes')`,
    [req.user.id]
  );
  const totp = rows.find((r) => r.method_type === 'totp');
  const backupCodes = rows.find((r) => r.method_type === 'backup_codes');
  return ok(res, {
    totpVerified: !!totp?.is_verified,
    hasBackupCodes: !!backupCodes?.is_verified,
  });
}));

/** POST /api/mfa/totp/enroll — returns a QR code to scan in an authenticator app. */
router.post('/totp/enroll', authenticate, asyncHandler(async (req, res) => {
  const { qrDataUrl, base32Secret } = await enrollTotpFor(req.user.id, req.user.email, req.user.companyId);
  return ok(res, { qrDataUrl, base32Secret }, 'Scan the QR code, then confirm with /api/mfa/totp/confirm');
}));

/** POST /api/mfa/totp/confirm — { token } proves the app was enrolled correctly. */
router.post('/totp/confirm', authenticate, asyncHandler(async (req, res) => {
  const valid = await confirmTotpFor(req.user.id, req.body.token);
  if (!valid) return fail(res, 'Incorrect code', 400);

  await logAudit({ userId: req.user.id, action: 'MFA', recordType: 'user', recordId: req.user.id, detail: 'TOTP enrolled', ip: req.ip });
  return ok(res, null, 'Authenticator app confirmed');
}));

/** POST /api/mfa/backup-codes/generate — returns plaintext codes ONCE. */
router.post('/backup-codes/generate', authenticate, asyncHandler(async (req, res) => {
  const { plaintextCodes, hashedCodes } = await generateBackupCodes(8);
  await pool.query(
    `INSERT INTO user_mfa_methods (company_id, user_id, method_type, backup_codes_hash_json, is_verified)
     VALUES (?, ?, 'backup_codes', ?, 1)
     ON DUPLICATE KEY UPDATE backup_codes_hash_json = VALUES(backup_codes_hash_json)`,
    [req.user.companyId, req.user.id, JSON.stringify(hashedCodes)]
  );
  await logAudit({ userId: req.user.id, action: 'MFA', recordType: 'user', recordId: req.user.id, detail: 'Backup codes regenerated', ip: req.ip });
  return ok(res, { codes: plaintextCodes }, 'Store these codes securely — they will not be shown again');
}));

/* ---------------------------- Login-time challenge ---------------------------- */

/**
 * GET /api/mfa/challenge/status — lets the login UI check whether the
 * signing-in user has TOTP enrolled *before* deciding whether to show the
 * QR enrolment step or a bare code-entry step.
 */
router.get('/challenge/status', requireMfaStage, asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT 1 FROM user_mfa_methods WHERE user_id = ? AND method_type = 'totp' AND is_verified = 1 LIMIT 1`,
    [req.mfaUserId]
  );
  const [[user]] = await pool.query('SELECT phone_number FROM users WHERE id = ?', [req.mfaUserId]);
  return ok(res, { totpEnrolled: rows.length > 0, hasPhoneNumber: isValidE164(user?.phone_number) });
}));

/**
 * POST /api/mfa/challenge/totp/enroll — mid-login equivalent of
 * `/totp/enroll` for a user who hasn't set up an authenticator app yet.
 * Authenticates with the mfaToken (password already verified) rather than a
 * full session token, since the user isn't fully signed in yet.
 *
 * Refuses to run if a verified TOTP method already exists. Unlike the
 * self-service `/totp/enroll` (an explicit "Set up"/"Replace authenticator
 * app" click, where overwriting is the intended action), this endpoint is
 * triggered automatically by the login UI based on a client-side
 * `totpEnrolled` flag that can be stale/wrong (e.g. a transient failure of
 * `/challenge/status` that made the frontend assume "not enrolled"). Without
 * this guard, that false assumption would silently regenerate the secret
 * and reset `is_verified` to 0 — permanently locking a genuinely-already-
 * enrolled user out of their real authenticator app entry, even though
 * nothing was actually wrong with their account.
 */
router.post('/challenge/totp/enroll', requireMfaStage, asyncHandler(async (req, res) => {
  const [existing] = await pool.query(
    `SELECT id FROM user_mfa_methods WHERE user_id = ? AND method_type = 'totp' AND is_verified = 1 LIMIT 1`,
    [req.mfaUserId]
  );
  if (existing.length) {
    return fail(res, 'An authenticator app is already set up for this account — verify with your existing code instead.', 409);
  }

  const [rows] = await pool.query('SELECT email, company_id FROM users WHERE id = ?', [req.mfaUserId]);
  const { qrDataUrl, base32Secret } = await enrollTotpFor(req.mfaUserId, rows[0].email, rows[0].company_id);
  return ok(res, { qrDataUrl, base32Secret }, 'Scan the QR code, then confirm to finish signing in');
}));

/**
 * POST /api/mfa/challenge/totp/confirm — { token }. Confirming a
 * mid-login enrolment also finishes the login (unlike the self-service
 * `/totp/confirm`, which just marks the method verified for an already
 * signed-in user).
 */
router.post('/challenge/totp/confirm', requireMfaStage, asyncHandler(async (req, res) => {
  const valid = await confirmTotpFor(req.mfaUserId, req.body.token);
  if (!valid) return fail(res, 'Incorrect code', 400);

  await logAudit({ userId: req.mfaUserId, action: 'MFA', recordType: 'user', recordId: req.mfaUserId, detail: 'TOTP enrolled during login', ip: req.ip });
  return completeMfaLogin(req, res, req.mfaUserId);
}));

/** POST /api/mfa/challenge/sms/send — sends an OTP to the user's registered phone. */
router.post('/challenge/sms/send', requireMfaStage, asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT phone_number, company_id FROM users WHERE id = ?', [req.mfaUserId]);
  if (!rows[0] || !isValidE164(rows[0].phone_number)) {
    return fail(res, 'No valid phone number on file for SMS MFA', 400);
  }

  const code = generateNumericCode(6);
  await pool.query(
    `INSERT INTO otp_codes (company_id, user_id, channel, purpose, code_hash, expires_at)
     VALUES (?, ?, 'sms', 'login_mfa', ?, DATE_ADD(NOW(), INTERVAL 5 MINUTE))`,
    [rows[0].company_id, req.mfaUserId, hashCode(code)]
  );
  try {
    await sendMfaOtpSms(rows[0].phone_number, code);
  } catch (err) {
    return fail(res, err.message, 502);
  }
  return ok(res, null, 'Code sent by SMS');
}));

/** POST /api/mfa/challenge/email/send */
router.post('/challenge/email/send', requireMfaStage, asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT email, company_id FROM users WHERE id = ?', [req.mfaUserId]);
  const code = generateNumericCode(6);
  await pool.query(
    `INSERT INTO otp_codes (company_id, user_id, channel, purpose, code_hash, expires_at)
     VALUES (?, ?, 'email', 'login_mfa', ?, DATE_ADD(NOW(), INTERVAL 5 MINUTE))`,
    [rows[0].company_id, req.mfaUserId, hashCode(code)]
  );
  await sendMfaOtpEmail(rows[0].email, code);
  return ok(res, null, 'Code sent by email');
}));

/** POST /api/mfa/verify/totp — { mfaToken, token } */
router.post('/verify/totp', requireMfaStage, asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT secret_encrypted FROM user_mfa_methods WHERE user_id = ? AND method_type = 'totp' AND is_verified = 1 LIMIT 1`,
    [req.mfaUserId]
  );
  if (!rows[0]) return fail(res, 'TOTP is not enrolled for this account', 400);
  if (!verifyTotpToken(rows[0].secret_encrypted.toString(), req.body.token)) {
    await logAudit({ userId: req.mfaUserId, action: 'Login failed', recordType: 'user', recordId: req.mfaUserId, detail: 'Bad TOTP code', ip: req.ip });
    return fail(res, 'Incorrect code', 400);
  }
  return completeMfaLogin(req, res, req.mfaUserId);
}));

/** POST /api/mfa/verify/otp — { mfaToken, code } for SMS or email OTP */
router.post('/verify/otp', requireMfaStage, asyncHandler(async (req, res) => {
  const { code } = req.body;
  const [rows] = await pool.query(
    `SELECT id, attempts FROM otp_codes
     WHERE user_id = ? AND purpose = 'login_mfa' AND code_hash = ? AND consumed_at IS NULL AND expires_at > NOW()
     ORDER BY id DESC LIMIT 1`,
    [req.mfaUserId, hashCode(code)]
  );
  if (!rows[0]) return fail(res, 'Code is incorrect or has expired', 400);

  await pool.query('UPDATE otp_codes SET consumed_at = NOW() WHERE id = ?', [rows[0].id]);
  return completeMfaLogin(req, res, req.mfaUserId);
}));

/** POST /api/mfa/verify/backup-code — { mfaToken, code } */
router.post('/verify/backup-code', requireMfaStage, asyncHandler(async (req, res) => {
  const valid = await consumeBackupCode(req.mfaUserId, req.body.code);
  if (!valid) return fail(res, 'Backup code is invalid or already used', 400);
  await logAudit({ userId: req.mfaUserId, action: 'MFA', recordType: 'user', recordId: req.mfaUserId, detail: 'Logged in with backup code', ip: req.ip });
  return completeMfaLogin(req, res, req.mfaUserId);
}));

module.exports = router;
