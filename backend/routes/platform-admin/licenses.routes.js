/**
 * routes/platform-admin/licenses.routes.js
 * License issuance/revocation/validation. GET /public-key is deliberately
 * NOT gated by authenticatePlatformAdmin — a public key is safe, even
 * meant, to expose; gating it would defeat the point of the two-key design
 * (see services/license.service.js).
 */
const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { body, validationResult } = require('express-validator');

const { pool } = require('../../config/db');
const { ok, fail } = require('../../utils/apiResponse');
const asyncHandler = require('../../utils/asyncHandler');
const { authenticatePlatformAdmin } = require('../../middleware/platformAuth.middleware');
const { logPlatformAudit } = require('../../services/platformAudit.service');
const { signLicense, verifyLicenseToken, writeValidationLog, publicKeyPem } = require('../../services/license.service');
const { LICENSE_TYPES } = require('../../config/constants');

const router = express.Router();

/** GET /api/platform-admin/licenses/public-key — unauthenticated, by design. */
router.get('/public-key', (req, res) => {
  res.type('text/plain').send(publicKeyPem());
});

router.use(authenticatePlatformAdmin);

/** GET /api/platform-admin/licenses?companyId= */
router.get('/', asyncHandler(async (req, res) => {
  const { companyId } = req.query;
  const clause = companyId ? 'WHERE l.company_id = ?' : '';
  const params = companyId ? [companyId] : [];
  const [rows] = await pool.query(
    `SELECT l.id, l.license_key, l.company_id, c.name AS company_name, l.license_type, l.status,
            l.issued_at, l.expires_at, l.max_users, l.storage_quota_bytes, l.enabled_modules_json,
            l.revoked_at, l.revoke_reason
     FROM licenses l JOIN companies c ON c.id = l.company_id
     ${clause} ORDER BY l.issued_at DESC`,
    params
  );
  return ok(res, rows);
}));

/** GET /api/platform-admin/licenses/:id — includes the signed token. */
router.get('/:id', asyncHandler(async (req, res) => {
  const [[license]] = await pool.query(`SELECT * FROM licenses WHERE id = ?`, [req.params.id]);
  if (!license) return fail(res, 'License not found', 404);
  return ok(res, license);
}));

/** POST /api/platform-admin/licenses — supersedes any existing active license for the company. */
router.post(
  '/',
  [
    body('companyId').isInt(),
    body('licenseType').isIn(LICENSE_TYPES),
    body('expiresAt').isISO8601(),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { companyId, licenseType, expiresAt, maxUsers, storageQuotaBytes, enabledModules } = req.body;
    const [[company]] = await pool.query(`SELECT id, company_code FROM companies WHERE id = ?`, [companyId]);
    if (!company) return fail(res, 'Company not found', 404);

    const licenseKey = uuidv4();
    const signedToken = signLicense({
      licenseKey, companyId, companyCode: company.company_code, licenseType,
      maxUsers, storageQuotaBytes, enabledModules, expiresAt,
    });

    const conn = await pool.getConnection();
    let licenseId;
    try {
      await conn.beginTransaction();
      await conn.query(
        `UPDATE licenses SET status = 'revoked', revoked_at = NOW(), revoked_by = ?, revoke_reason = 'superseded' WHERE company_id = ? AND status = 'active'`,
        [req.platformAdmin.id, companyId]
      );
      const [result] = await conn.query(
        `INSERT INTO licenses (license_key, company_id, license_type, expires_at, max_users, storage_quota_bytes, enabled_modules_json, signed_token, issued_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [licenseKey, companyId, licenseType, expiresAt, maxUsers || null, storageQuotaBytes || null,
          enabledModules ? JSON.stringify(enabledModules) : null, signedToken, req.platformAdmin.id]
      );
      licenseId = result.insertId;
      await conn.commit();
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }

    await logPlatformAudit({ platformAdminId: req.platformAdmin.id, action: 'license.issue', companyId, detail: `${licenseType}, expires ${expiresAt}`, ip: req.ip });
    return ok(res, { id: licenseId, licenseKey, signedToken }, 'License issued', 201);
  })
);

/** POST /api/platform-admin/licenses/:id/revoke — { reason } */
router.post('/:id/revoke', asyncHandler(async (req, res) => {
  const [result] = await pool.query(
    `UPDATE licenses SET status = 'revoked', revoked_at = NOW(), revoked_by = ?, revoke_reason = ? WHERE id = ? AND status = 'active'`,
    [req.platformAdmin.id, req.body.reason || null, req.params.id]
  );
  if (!result.affectedRows) return fail(res, 'License not found or already inactive', 404);

  const [[license]] = await pool.query(`SELECT company_id FROM licenses WHERE id = ?`, [req.params.id]);
  await logPlatformAudit({ platformAdminId: req.platformAdmin.id, action: 'license.revoke', companyId: license?.company_id, detail: req.body.reason, ip: req.ip });
  return ok(res, null, 'License revoked');
}));

/**
 * POST /api/platform-admin/licenses/:id/validate — re-verifies THIS
 * license row's persisted signed_token directly (regardless of its
 * current status — this is a signature/tamper check, not the "does this
 * company currently have a valid license" login-time gate, which is
 * services/license.service.js#checkCompanyLicense instead).
 */
router.post('/:id/validate', asyncHandler(async (req, res) => {
  const [[license]] = await pool.query(`SELECT * FROM licenses WHERE id = ?`, [req.params.id]);
  if (!license) return fail(res, 'License not found', 404);

  const verification = verifyLicenseToken(license.signed_token);
  await writeValidationLog({
    licenseId: license.id,
    companyId: license.company_id,
    result: verification.valid ? 'valid' : verification.result,
    source: 'manual_admin_check',
    detail: verification.valid ? null : verification.detail,
  });

  if (!verification.valid) {
    return ok(res, { valid: false, result: verification.result }, `License check failed: ${verification.result}`);
  }
  return ok(res, { valid: true, claims: verification.claims }, 'License is valid');
}));

/** GET /api/platform-admin/licenses/:id/validation-history */
router.get('/:id/validation-history', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT * FROM license_validation_log WHERE license_id = ? ORDER BY checked_at DESC LIMIT 200`,
    [req.params.id]
  );
  return ok(res, rows);
}));

module.exports = router;
