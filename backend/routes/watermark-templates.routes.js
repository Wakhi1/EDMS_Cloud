/**
 * routes/watermark-templates.routes.js
 * Admin-managed watermark text templates + which one is currently active —
 * see services/watermark.service.js for how the active one actually gets
 * stamped onto downloaded PDFs. Same read/write RBAC split as
 * settings.routes.js (which this conceptually lives next to):
 * requireModuleAccess('settings') to view, System-Administrator-only to
 * write — this deployment's watermark text is a security/branding setting,
 * not a per-user preference.
 *
 * Route order matters: GET /active and PUT /active (literal paths) are
 * registered before the /:id-shaped routes below them, same discipline as
 * integrations.routes.js/permissions.routes.js.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess, allowRoles } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { getSettingInt } = require('../services/settings.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/watermark-templates */
router.get('/', requireModuleAccess('settings'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    'SELECT id, label, text, created_at AS createdAt FROM watermark_templates WHERE company_id = ? ORDER BY label',
    [req.user.companyId]
  );
  return ok(res, rows);
}));

/** GET /api/watermark-templates/active — the template every new watermark uses right now, or null if none configured. */
router.get('/active', requireModuleAccess('settings'), asyncHandler(async (req, res) => {
  const templateId = await getSettingInt('active_watermark_template_id', 0);
  if (!templateId) return ok(res, null);

  const [[row]] = await pool.query(
    'SELECT id, label, text, created_at AS createdAt FROM watermark_templates WHERE id = ? AND company_id = ?',
    [templateId, req.user.companyId]
  );
  return ok(res, row || null);
}));

/** PUT /api/watermark-templates/active — { templateId } */
router.put(
  '/active',
  allowRoles('System Administrator'),
  [body('templateId').isInt()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[template]] = await pool.query(
      'SELECT id, label FROM watermark_templates WHERE id = ? AND company_id = ?',
      [req.body.templateId, req.user.companyId]
    );
    if (!template) return fail(res, 'Unknown watermark template', 404);

    await pool.query(
      `INSERT INTO system_settings (company_id, setting_key, setting_value) VALUES (?, 'active_watermark_template_id', ?)
       ON DUPLICATE KEY UPDATE setting_value = VALUES(setting_value)`,
      [req.user.companyId, String(template.id)]
    );
    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'watermark_template', recordId: template.id, detail: `Set active: ${template.label}`, ip: req.ip });
    return ok(res, { id: template.id }, 'Active watermark updated');
  })
);

/** POST /api/watermark-templates — { label, text } */
router.post(
  '/',
  allowRoles('System Administrator'),
  [body('label').trim().notEmpty(), body('text').trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { label, text } = req.body;
    const [[existing]] = await pool.query('SELECT id FROM watermark_templates WHERE company_id = ? AND label = ?', [req.user.companyId, label]);
    if (existing) return fail(res, 'A watermark template with this label already exists', 409);

    const [result] = await pool.query(
      'INSERT INTO watermark_templates (company_id, label, text, created_by) VALUES (?, ?, ?, ?)',
      [req.user.companyId, label, text, req.user.id]
    );
    await logAudit({ userId: req.user.id, action: 'Create', recordType: 'watermark_template', recordId: result.insertId, detail: label, ip: req.ip });
    return ok(res, { id: result.insertId }, 'Watermark template created', 201);
  })
);

/** PUT /api/watermark-templates/:id — { label?, text? } */
router.put(
  '/:id',
  allowRoles('System Administrator'),
  [body('label').optional().trim().notEmpty(), body('text').optional().trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[row]] = await pool.query('SELECT id FROM watermark_templates WHERE id = ? AND company_id = ?', [req.params.id, req.user.companyId]);
    if (!row) return fail(res, 'Watermark template not found', 404);

    const { label, text } = req.body;
    await pool.query(
      'UPDATE watermark_templates SET label = COALESCE(?, label), text = COALESCE(?, text) WHERE id = ?',
      [label || null, text || null, req.params.id]
    );
    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'watermark_template', recordId: req.params.id, ip: req.ip });
    return ok(res, null, 'Watermark template updated');
  })
);

/** DELETE /api/watermark-templates/:id — refuses if it's the currently-active template. */
router.delete('/:id', allowRoles('System Administrator'), asyncHandler(async (req, res) => {
  const [[row]] = await pool.query('SELECT id, label FROM watermark_templates WHERE id = ? AND company_id = ?', [req.params.id, req.user.companyId]);
  if (!row) return fail(res, 'Watermark template not found', 404);

  const activeId = await getSettingInt('active_watermark_template_id', 0);
  if (activeId === Number(req.params.id)) {
    return fail(res, 'Cannot delete the currently active watermark template', 400);
  }

  await pool.query('DELETE FROM watermark_templates WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'watermark_template', recordId: req.params.id, detail: row.label, ip: req.ip });
  return ok(res, null, 'Watermark template deleted');
}));

module.exports = router;
