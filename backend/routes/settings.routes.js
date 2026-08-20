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
