/**
 * routes/settings.routes.js
 * System Settings, backed directly by `system_settings` — System
 * Administrator edits, System Administrator + Records Manager view (same
 * split as retention.routes.js's schedule editing).
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess, allowRoles } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { getStoredLicenseKey, verifyLicenseKeyWithProvider } = require('../services/license.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/settings */
router.get('/', requireModuleAccess('settings'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM system_settings ORDER BY setting_key');
  return ok(res, rows);
}));

/** GET /api/settings/me/preferences — per-user appearance/UX settings. Registered before PUT /:key (a wildcard route) so it isn't shadowed. */
router.get('/me/preferences', asyncHandler(async (req, res) => {
  const [[row]] = await pool.query('SELECT theme_mode, density FROM user_preferences WHERE user_id = ?', [req.user.id]);
  return ok(res, row || { theme_mode: 'system', density: 'comfortable' });
}));

/** PUT /api/settings/me/preferences — { themeMode?, density? } */
router.put(
  '/me/preferences',
  [
    body('themeMode').optional().isIn(['system', 'light', 'dark']),
    body('density').optional().isIn(['comfortable', 'compact']),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { themeMode, density } = req.body;
    await pool.query(
      `INSERT INTO user_preferences (user_id, company_id, theme_mode, density) VALUES (?, ?, COALESCE(?, 'system'), COALESCE(?, 'comfortable'))
       ON DUPLICATE KEY UPDATE
         theme_mode = COALESCE(?, theme_mode),
         density = COALESCE(?, density)`,
      [req.user.id, req.user.companyId, themeMode || null, density || null, themeMode || null, density || null]
    );
    return ok(res, null, 'Preferences updated');
  })
);

/**
 * PUT /api/settings/theme — { primaryColor?, secondaryColor?, accentColor? }
 * (each "#RRGGBB" or omitted to leave unchanged). Pushes this company's
 * brand colors up to docsecure-platform-provider — the actual owner of
 * branding — authenticated by this deployment's own stored license key,
 * not a separate credential. Registered before PUT /:key (a wildcard
 * route) so it isn't shadowed.
 */
router.put(
  '/theme',
  allowRoles('System Administrator'),
  [
    body('primaryColor').optional({ checkFalsy: true }).matches(/^#[0-9a-fA-F]{6}$/),
    body('secondaryColor').optional({ checkFalsy: true }).matches(/^#[0-9a-fA-F]{6}$/),
    body('accentColor').optional({ checkFalsy: true }).matches(/^#[0-9a-fA-F]{6}$/),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Enter colors as #RRGGBB.', 422, errors.array());

    const licenseKey = await getStoredLicenseKey();
    if (!licenseKey) return fail(res, 'This deployment has no active license to update branding for.', 409);

    const baseUrl = process.env.PLATFORM_PROVIDER_BASE_URL;
    if (!baseUrl) return fail(res, 'This deployment is not configured to reach DocSecure’s licensing platform.', 502);

    const verification = await verifyLicenseKeyWithProvider(licenseKey);
    if (!verification.valid) return fail(res, 'This deployment’s license is not currently valid.', 403);

    let payload;
    try {
      const response = await fetch(`${baseUrl}/companies/${encodeURIComponent(verification.companyCode)}/theme`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ licenseKey, ...req.body }),
      });
      payload = await response.json();
      if (!response.ok) return fail(res, payload.error || 'Could not update theme.', response.status);
    } catch {
      return fail(res, 'Could not reach DocSecure’s licensing platform.', 502);
    }

    await logAudit({ userId: req.user.id, companyId: req.user.companyId, action: 'Edit', recordType: 'branding_theme', recordId: 'theme', ip: req.ip });
    return ok(res, null, 'Theme updated');
  })
);

/** PUT /api/settings/:key — { value }. Registered last since it's a wildcard route. */
router.put(
  '/:key',
  allowRoles('System Administrator'),
  [body('value').exists()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[before]] = await pool.query('SELECT setting_value FROM system_settings WHERE setting_key = ?', [req.params.key]);
    if (!before) return fail(res, 'Unknown setting key', 404);

    await pool.query('UPDATE system_settings SET setting_value = ? WHERE setting_key = ?', [String(req.body.value), req.params.key]);
    await logAudit({
      userId: req.user.id, action: 'Edit', recordType: 'system_setting', recordId: req.params.key,
      detail: `${before.setting_value} -> ${req.body.value}`, ip: req.ip,
    });
    return ok(res, null, 'Setting updated');
  })
);

module.exports = router;
