/**
 * routes/platform-admin/companies.routes.js
 * Company (tenant) lifecycle management for DocSecore staff — creation
 * (which also bootstraps that company's own roles/departments/permission
 * matrix, load-bearing since a company can't have a first user without a
 * role_id), status, branding assets, and the admin-user bootstrap.
 */
const express = require('express');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');

const { pool } = require('../../config/db');
const { ok, fail } = require('../../utils/apiResponse');
const asyncHandler = require('../../utils/asyncHandler');
const { authenticatePlatformAdmin } = require('../../middleware/platformAuth.middleware');
const { logPlatformAudit } = require('../../services/platformAudit.service');
const upload = require('../../middleware/upload.middleware');
const storageService = require('../../services/storage/storage.service');
const { v4: uuidv4 } = require('uuid');

const router = express.Router();
router.use(authenticatePlatformAdmin);

// Mirrors database/pspf_edms_schema.sql's SEED DATA section exactly — kept
// as plain data here (not re-derived from the SQL file) so a new company
// starts from the same known-good default roles/departments/permission
// matrix as the bootstrap 'PSPF' company.
const DEFAULT_ROLES = [
  { name: 'Records Officer', description: 'Captures and indexes records', mfaRequired: 0, isSystemRole: 0 },
  { name: 'Approving Manager', description: 'Approves claims and workflow steps', mfaRequired: 1, isSystemRole: 0 },
  { name: 'Finance Officer', description: 'Handles payouts and contributions', mfaRequired: 1, isSystemRole: 0 },
  { name: 'Records Manager', description: 'Owns retention schedules and ACL exceptions', mfaRequired: 1, isSystemRole: 1 },
  { name: 'System Administrator', description: 'Full system configuration access', mfaRequired: 1, isSystemRole: 1 },
  { name: 'Internal Auditor', description: 'Read-only access to audit trail and reports', mfaRequired: 1, isSystemRole: 0 },
];

const DEFAULT_DEPARTMENTS = [
  { name: 'Benefits', description: 'Pension claims and benefit processing' },
  { name: 'Finance', description: 'Contributions, payouts and treasury' },
  { name: 'Records Management', description: 'Registry, retention and disposal' },
  { name: 'ICT', description: 'Systems and integrations' },
  { name: 'Human Resources', description: 'Staff administration' },
];

/** [module, canView, canEdit][] per role name. */
const DEFAULT_MODULE_PERMISSIONS = {
  'Records Officer': [['approvals', 1, 1], ['capture', 1, 1], ['repository', 1, 1], ['versions', 1, 1], ['viewer', 1, 1]],
  'Approving Manager': [['approvals', 1, 1], ['reports', 1, 0], ['repository', 1, 0], ['viewer', 1, 0]],
  'Finance Officer': [['approvals', 1, 1], ['reports', 1, 0], ['repository', 1, 0], ['viewer', 1, 0]],
  'Records Manager': [
    ['audit', 1, 0], ['permissions', 1, 1], ['reports', 1, 0], ['repository', 1, 1], ['retention', 1, 1],
    ['versions', 1, 1], ['viewer', 1, 1], ['workflow', 1, 1], ['users', 1, 0], ['departments', 1, 0], ['settings', 1, 0],
  ],
  'Internal Auditor': [['audit', 1, 0], ['reports', 1, 0], ['repository', 1, 0], ['viewer', 1, 0]],
  'System Administrator': [
    ['approvals', 1, 1], ['audit', 1, 1], ['capture', 1, 1], ['integrations', 1, 1], ['permissions', 1, 1],
    ['reports', 1, 1], ['repository', 1, 1], ['retention', 1, 1], ['versions', 1, 1], ['viewer', 1, 1],
    ['workflow', 1, 1], ['users', 1, 1], ['departments', 1, 1], ['settings', 1, 1], ['backup', 1, 1],
  ],
};

/** GET /api/platform-admin/companies */
router.get('/', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT c.*, l.id AS current_license_id, l.license_type, l.status AS license_status, l.expires_at AS license_expires_at
     FROM companies c
     LEFT JOIN licenses l ON l.company_id = c.id AND l.status = 'active'
     ORDER BY c.created_at DESC`
  );
  return ok(res, rows);
}));

/** GET /api/platform-admin/companies/:id */
router.get('/:id', asyncHandler(async (req, res) => {
  const [[company]] = await pool.query(`SELECT * FROM companies WHERE id = ?`, [req.params.id]);
  if (!company) return fail(res, 'Company not found', 404);
  const [licenses] = await pool.query(`SELECT * FROM licenses WHERE company_id = ? ORDER BY issued_at DESC`, [req.params.id]);
  const [userCount] = await pool.query(`SELECT COUNT(*) AS n FROM users WHERE company_id = ?`, [req.params.id]);
  return ok(res, { ...company, licenses, userCount: userCount[0].n });
}));

/** POST /api/platform-admin/companies */
router.post(
  '/',
  [body('companyCode').trim().notEmpty(), body('name').trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const {
      companyCode, name, registrationNo, taxId, contactName, contactEmail, contactPhone,
      enabledModules, storageQuotaBytes, maxUsers,
    } = req.body;

    const [existing] = await pool.query(`SELECT id FROM companies WHERE company_code = ?`, [companyCode]);
    if (existing.length) return fail(res, 'That company code is already in use', 409);

    const conn = await pool.getConnection();
    let companyId;
    try {
      await conn.beginTransaction();

      const [result] = await conn.query(
        `INSERT INTO companies (company_code, name, registration_no, tax_id, contact_name, contact_email, contact_phone, enabled_modules_json, storage_quota_bytes, max_users, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [companyCode, name, registrationNo || null, taxId || null, contactName || null, contactEmail || null, contactPhone || null,
          enabledModules ? JSON.stringify(enabledModules) : null, storageQuotaBytes || null, maxUsers || null, req.platformAdmin.id]
      );
      companyId = result.insertId;

      for (const dept of DEFAULT_DEPARTMENTS) {
        // eslint-disable-next-line no-await-in-loop
        await conn.query(`INSERT INTO departments (company_id, name, description) VALUES (?, ?, ?)`, [companyId, dept.name, dept.description]);
      }

      const roleIds = {};
      for (const role of DEFAULT_ROLES) {
        // eslint-disable-next-line no-await-in-loop
        const [roleResult] = await conn.query(
          `INSERT INTO roles (company_id, name, description, mfa_required, is_system_role) VALUES (?, ?, ?, ?, ?)`,
          [companyId, role.name, role.description, role.mfaRequired, role.isSystemRole]
        );
        roleIds[role.name] = roleResult.insertId;
      }

      for (const [roleName, perms] of Object.entries(DEFAULT_MODULE_PERMISSIONS)) {
        for (const [module, canView, canEdit] of perms) {
          // eslint-disable-next-line no-await-in-loop
          await conn.query(
            `INSERT INTO role_module_permissions (company_id, role_id, module, can_view, can_edit) VALUES (?, ?, ?, ?, ?)`,
            [companyId, roleIds[roleName], module, canView, canEdit]
          );
        }
      }

      await conn.commit();
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }

    await logPlatformAudit({ platformAdminId: req.platformAdmin.id, action: 'company.create', companyId, detail: name, ip: req.ip });
    return ok(res, { id: companyId }, 'Company created', 201);
  })
);

/** PUT /api/platform-admin/companies/:id */
router.put('/:id', asyncHandler(async (req, res) => {
  const { name, registrationNo, taxId, contactName, contactEmail, contactPhone, enabledModules, storageQuotaBytes, maxUsers } = req.body;
  const [result] = await pool.query(
    `UPDATE companies SET
       name = COALESCE(?, name), registration_no = ?, tax_id = ?, contact_name = ?, contact_email = ?, contact_phone = ?,
       enabled_modules_json = COALESCE(?, enabled_modules_json), storage_quota_bytes = ?, max_users = ?
     WHERE id = ?`,
    [name || null, registrationNo ?? null, taxId ?? null, contactName ?? null, contactEmail ?? null, contactPhone ?? null,
      enabledModules ? JSON.stringify(enabledModules) : null, storageQuotaBytes ?? null, maxUsers ?? null, req.params.id]
  );
  if (!result.affectedRows) return fail(res, 'Company not found', 404);

  await logPlatformAudit({ platformAdminId: req.platformAdmin.id, action: 'company.update', companyId: req.params.id, ip: req.ip });
  return ok(res, null, 'Company updated');
}));

/** PUT /api/platform-admin/companies/:id/status — { status: 'active'|'suspended' } */
router.put(
  '/:id/status',
  [body('status').isIn(['active', 'suspended'])],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [result] = await pool.query(`UPDATE companies SET status = ? WHERE id = ?`, [req.body.status, req.params.id]);
    if (!result.affectedRows) return fail(res, 'Company not found', 404);

    if (req.body.status === 'suspended') {
      await pool.query(`UPDATE user_sessions SET revoked_at = NOW() WHERE company_id = ? AND revoked_at IS NULL`, [req.params.id]);
    }

    await logPlatformAudit({ platformAdminId: req.platformAdmin.id, action: 'company.status', companyId: req.params.id, detail: req.body.status, ip: req.ip });
    return ok(res, null, `Company ${req.body.status}`);
  })
);

/** POST /api/platform-admin/companies/:id/admin-user — bootstrap the company's first System Administrator. */
router.post(
  '/:id/admin-user',
  [body('fullName').trim().notEmpty(), body('email').isEmail(), body('password').isLength({ min: 10 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const companyId = req.params.id;
    const [[company]] = await pool.query(`SELECT id FROM companies WHERE id = ?`, [companyId]);
    if (!company) return fail(res, 'Company not found', 404);

    const [[role]] = await pool.query(`SELECT id FROM roles WHERE company_id = ? AND name = 'System Administrator'`, [companyId]);
    if (!role) return fail(res, 'Company has no System Administrator role — was it created before this feature existed?', 409);

    const { fullName, email, password } = req.body;
    const [existing] = await pool.query(`SELECT id FROM users WHERE company_id = ? AND email = ?`, [companyId, email]);
    if (existing.length) return fail(res, 'An account with this email already exists in this company', 409);

    const passwordHash = await bcrypt.hash(password, 12);
    const [result] = await pool.query(
      `INSERT INTO users (company_id, full_name, email, password_hash, role_id, password_changed_at) VALUES (?, ?, ?, ?, ?, NOW())`,
      [companyId, fullName, email, passwordHash, role.id]
    );

    await logPlatformAudit({ platformAdminId: req.platformAdmin.id, action: 'admin_user.create', companyId, detail: email, ip: req.ip });
    return ok(res, { userId: result.insertId }, 'Admin user created', 201);
  })
);

async function recordBrandingChange(companyId, changedField, oldValue, newValue, platformAdminId) {
  await pool.query(
    `INSERT INTO company_branding_history (company_id, changed_field, old_value, new_value, changed_by) VALUES (?, ?, ?, ?, ?)`,
    [companyId, changedField, oldValue, newValue, platformAdminId]
  );
}

/** POST /api/platform-admin/companies/:id/branding/logo — multipart/form-data, field "file". */
router.post('/:id/branding/logo', upload.single('file'), asyncHandler(async (req, res) => {
  if (!req.file) return fail(res, 'file is required', 400);
  const [[company]] = await pool.query(`SELECT logo_object_key FROM companies WHERE id = ?`, [req.params.id]);
  if (!company) return fail(res, 'Company not found', 404);

  const objectKey = `branding/${req.params.id}/logo-${uuidv4()}-${req.file.originalname}`;
  const { key: providerKey } = await storageService.uploadEncrypted(objectKey, req.file.buffer, req.file.mimetype);

  await pool.query(
    `UPDATE companies SET logo_provider = ?, logo_object_key = ?, logo_content_type = ? WHERE id = ?`,
    [providerKey, objectKey, req.file.mimetype, req.params.id]
  );
  await recordBrandingChange(req.params.id, 'logo', company.logo_object_key, objectKey, req.platformAdmin.id);
  await logPlatformAudit({ platformAdminId: req.platformAdmin.id, action: 'branding.update', companyId: req.params.id, detail: 'logo', ip: req.ip });

  return ok(res, { objectKey }, 'Logo uploaded');
}));

/** POST /api/platform-admin/companies/:id/branding/favicon — multipart/form-data, field "file". */
router.post('/:id/branding/favicon', upload.single('file'), asyncHandler(async (req, res) => {
  if (!req.file) return fail(res, 'file is required', 400);
  const [[company]] = await pool.query(`SELECT favicon_object_key FROM companies WHERE id = ?`, [req.params.id]);
  if (!company) return fail(res, 'Company not found', 404);

  const objectKey = `branding/${req.params.id}/favicon-${uuidv4()}-${req.file.originalname}`;
  const { key: providerKey } = await storageService.uploadEncrypted(objectKey, req.file.buffer, req.file.mimetype);

  await pool.query(
    `UPDATE companies SET favicon_provider = ?, favicon_object_key = ?, favicon_content_type = ? WHERE id = ?`,
    [providerKey, objectKey, req.file.mimetype, req.params.id]
  );
  await recordBrandingChange(req.params.id, 'favicon', company.favicon_object_key, objectKey, req.platformAdmin.id);
  await logPlatformAudit({ platformAdminId: req.platformAdmin.id, action: 'branding.update', companyId: req.params.id, detail: 'favicon', ip: req.ip });

  return ok(res, { objectKey }, 'Favicon uploaded');
}));

/** PUT /api/platform-admin/companies/:id/branding/theme */
router.put('/:id/branding/theme', asyncHandler(async (req, res) => {
  const [[company]] = await pool.query(
    `SELECT theme_primary_color, theme_secondary_color, theme_accent_color, custom_domain FROM companies WHERE id = ?`,
    [req.params.id]
  );
  if (!company) return fail(res, 'Company not found', 404);

  const { primaryColor, secondaryColor, accentColor, customDomain } = req.body;
  const changes = [
    ['theme_primary_color', 'theme_primary_color', company.theme_primary_color, primaryColor],
    ['theme_secondary_color', 'theme_secondary_color', company.theme_secondary_color, secondaryColor],
    ['theme_accent_color', 'theme_accent_color', company.theme_accent_color, accentColor],
    ['custom_domain', 'custom_domain', company.custom_domain, customDomain],
  ].filter(([, , , newVal]) => newVal !== undefined);

  if (!changes.length) return fail(res, 'No fields to update', 400);

  await pool.query(
    `UPDATE companies SET ${changes.map(([col]) => `${col} = ?`).join(', ')} WHERE id = ?`,
    [...changes.map(([, , , newVal]) => newVal), req.params.id]
  );
  for (const [, historyField, oldVal, newVal] of changes) {
    // eslint-disable-next-line no-await-in-loop
    await recordBrandingChange(req.params.id, historyField, oldVal, newVal, req.platformAdmin.id);
  }
  await logPlatformAudit({ platformAdminId: req.platformAdmin.id, action: 'branding.update', companyId: req.params.id, detail: 'theme', ip: req.ip });

  return ok(res, null, 'Branding updated');
}));

/** GET /api/platform-admin/companies/:id/branding/history */
router.get('/:id/branding/history', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT h.*, a.full_name AS changed_by_name FROM company_branding_history h
     LEFT JOIN platform_admins a ON a.id = h.changed_by
     WHERE h.company_id = ? ORDER BY h.changed_at DESC`,
    [req.params.id]
  );
  return ok(res, rows);
}));

/** GET /api/platform-admin/companies/:id/audit */
router.get('/:id/audit', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT l.*, a.full_name AS platform_admin_name FROM platform_admin_audit_log l
     LEFT JOIN platform_admins a ON a.id = l.platform_admin_id
     WHERE l.company_id = ? ORDER BY l.created_at DESC LIMIT 500`,
    [req.params.id]
  );
  return ok(res, rows);
}));

module.exports = router;
