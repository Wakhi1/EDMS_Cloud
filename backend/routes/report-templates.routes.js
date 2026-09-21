/**
 * routes/report-templates.routes.js
 * Personal saved "which KPI/graph sections to show" views for the Reports
 * screen — per-user (not an org-wide admin list like watermark-templates
 * or record-indexes), since this is "how I like my own report to look."
 * `sections` values are validated against reports.service.js's
 * REPORT_SECTION_KEYS, the same registry GET /api/reports/export filters
 * by, so a saved template can never reference a section that doesn't exist.
 */
const express = require('express');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { REPORT_SECTION_KEYS } = require('../services/reports.service');

const router = express.Router();
router.use(authenticate);
router.use(requireModuleAccess('reports'));

// mysql2 returns JSON columns as already-parsed values in most cases, but
// this codebase has hit the stringly-typed-JSON-column gotcha before
// (Phase 3's record_indexes) — parse defensively rather than assume.
function parseSections(value) {
  return typeof value === 'string' ? JSON.parse(value) : value;
}

function validateSections(sections) {
  if (!Array.isArray(sections) || !sections.length) return 'sections must be a non-empty array';
  const invalid = sections.filter((s) => !REPORT_SECTION_KEYS.includes(s));
  if (invalid.length) return `Unknown section(s): ${invalid.join(', ')}`;
  return null;
}

/** GET / — this user's saved report templates. */
router.get('/', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    'SELECT id, name, sections, created_at AS createdAt FROM report_templates WHERE user_id = ? ORDER BY name',
    [req.user.id]
  );
  return ok(res, rows.map((r) => ({ ...r, sections: parseSections(r.sections) })));
}));

/** POST / — { name, sections: string[] } */
router.post('/', asyncHandler(async (req, res) => {
  const { name, sections } = req.body;
  if (!name || !String(name).trim()) return fail(res, 'name is required', 422);
  const sectionsError = validateSections(sections);
  if (sectionsError) return fail(res, sectionsError, 422);

  try {
    const [result] = await pool.query(
      'INSERT INTO report_templates (company_id, user_id, name, sections) VALUES (?, ?, ?, ?)',
      [req.user.companyId, req.user.id, String(name).trim(), JSON.stringify(sections)]
    );
    return ok(res, { id: result.insertId }, 'Report template saved');
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') return fail(res, 'You already have a saved view with this name', 409);
    throw err;
  }
}));

/** PUT /:id — { name?, sections? } */
router.put('/:id', asyncHandler(async (req, res) => {
  const [[row]] = await pool.query('SELECT id FROM report_templates WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
  if (!row) return fail(res, 'Report template not found', 404);

  const { name, sections } = req.body;
  if (sections !== undefined) {
    const sectionsError = validateSections(sections);
    if (sectionsError) return fail(res, sectionsError, 422);
  }

  await pool.query(
    'UPDATE report_templates SET name = COALESCE(?, name), sections = COALESCE(?, sections) WHERE id = ?',
    [name ? String(name).trim() : null, sections ? JSON.stringify(sections) : null, req.params.id]
  );
  return ok(res, null, 'Report template updated');
}));

/** DELETE /:id */
router.delete('/:id', asyncHandler(async (req, res) => {
  const [result] = await pool.query('DELETE FROM report_templates WHERE id = ? AND user_id = ?', [req.params.id, req.user.id]);
  if (!result.affectedRows) return fail(res, 'Report template not found', 404);
  return ok(res, null, 'Report template deleted');
}));

module.exports = router;
