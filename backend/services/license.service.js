/**
 * services/license.service.js
 * "Two-key" license signing/verification: a private key (env-only, never
 * in the DB or an API response) signs a license as an RS256 JWT; the
 * matching public key verifies it and is safe to expose (served
 * unauthenticated at GET /api/platform-admin/licenses/public-key).
 */
const jwt = require('jsonwebtoken');
const { pool } = require('../config/db');
const logger = require('../config/logger');

/** .env stores PEMs as single-line, \n-escaped strings — see .env.example. */
function unescapePem(value) {
  return value ? value.replace(/\\n/g, '\n') : value;
}

function privateKeyPem() {
  return unescapePem(process.env.LICENSE_SIGNING_PRIVATE_KEY_PEM);
}

function publicKeyPem() {
  return unescapePem(process.env.LICENSE_SIGNING_PUBLIC_KEY_PEM);
}

/**
 * Signs a new license token. Does not touch the database — callers
 * (routes/platform-admin/licenses.routes.js) persist the returned token
 * into `licenses.signed_token` themselves, in the same transaction as
 * the row insert.
 */
function signLicense({ licenseKey, companyId, companyCode, licenseType, maxUsers, storageQuotaBytes, enabledModules, expiresAt }) {
  const payload = {
    jti: licenseKey,
    sub: `company:${companyId}`,
    companyId,
    companyCode,
    licenseType,
    maxUsers: maxUsers ?? null,
    storageQuotaBytes: storageQuotaBytes ?? null,
    enabledModules: enabledModules ?? [],
  };
  const expiresInMs = new Date(expiresAt).getTime() - Date.now();
  return jwt.sign(payload, privateKeyPem(), {
    algorithm: 'RS256',
    issuer: process.env.LICENSE_ISSUER,
    expiresIn: Math.max(Math.floor(expiresInMs / 1000), 1),
  });
}

/**
 * Verifies a persisted license token's signature/expiry against the
 * public key. Returns { valid, claims } or { valid: false, result, detail }
 * where `result` matches the license_validation_log.result enum.
 */
function verifyLicenseToken(token) {
  try {
    const claims = jwt.verify(token, publicKeyPem(), {
      algorithms: ['RS256'],
      issuer: process.env.LICENSE_ISSUER,
    });
    return { valid: true, claims };
  } catch (err) {
    if (err.name === 'TokenExpiredError') return { valid: false, result: 'expired', detail: err.message };
    if (err.name === 'JsonWebTokenError') return { valid: false, result: 'signature_invalid', detail: err.message };
    return { valid: false, result: 'malformed', detail: err.message };
  }
}

async function writeValidationLog({ licenseId = null, companyId = null, result, source, detail = null }) {
  try {
    await pool.query(
      `INSERT INTO license_validation_log (license_id, company_id, result, source, detail) VALUES (?, ?, ?, ?, ?)`,
      [licenseId, companyId, result, source, detail]
    );
  } catch (err) {
    logger.error('Failed to write license_validation_log entry', { error: err.message, licenseId, companyId, result });
  }
}

/**
 * The actual enforcement point — called from POST /api/auth/login (and
 * the federated sign-in tail) before tokens are issued, and on-demand via
 * POST /api/platform-admin/licenses/:id/validate. `source` is
 * 'login' | 'manual_admin_check' (the third value, 'scheduled_check', is
 * written directly by services/license/scheduler.js instead).
 */
async function checkCompanyLicense(companyId, source = 'login') {
  const [[license]] = await pool.query(
    `SELECT * FROM licenses WHERE company_id = ? AND status = 'active' ORDER BY issued_at DESC LIMIT 1`,
    [companyId]
  );
  if (!license) {
    await writeValidationLog({ companyId, result: 'not_found', source, detail: 'No active license row' });
    return { ok: false, reason: 'not_found' };
  }

  const verification = verifyLicenseToken(license.signed_token);
  if (!verification.valid) {
    // A token failing signature/expiry verification while the DB row still
    // says 'active' means the row is stale (e.g. the scheduler hasn't
    // ticked yet for an expiry) — flip it here too, not just in the
    // scheduler, so enforcement is never a step behind the log.
    if (verification.result === 'expired') {
      await pool.query(`UPDATE licenses SET status = 'expired' WHERE id = ?`, [license.id]);
    }
    await writeValidationLog({ licenseId: license.id, companyId, result: verification.result, source, detail: verification.detail });
    return { ok: false, reason: verification.result };
  }

  await writeValidationLog({ licenseId: license.id, companyId, result: 'valid', source });
  return { ok: true, license, claims: verification.claims };
}

module.exports = { signLicense, verifyLicenseToken, checkCompanyLicense, writeValidationLog, privateKeyPem, publicKeyPem };
