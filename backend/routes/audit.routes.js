/**
 * routes/audit.routes.js
 * Audit trail viewing, CSV export, and hash-chain verification —
 * Internal Auditor / Records Manager / System Administrator only.
 */
const express = require('express');
const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { verifyChain, logAudit } = require('../services/audit.service');
const { getSettingInt } = require('../services/settings.service');

const router = express.Router();
router.use(authenticate);
router.use(requireModuleAccess('audit'));

/**
 * Shared by GET / and GET /export.csv so the export can never drift from
 * what the on-screen filters actually show — previously export.csv ignored
 * every filter and always dumped the same unfiltered top-N rows.
 */
function buildAuditFilters({ action, recordType, q, from, to }) {
  const clauses = [];
  const params = [];
  if (action && action !== 'All actions') { clauses.push('a.action = ?'); params.push(action); }
  if (recordType) { clauses.push('a.record_type = ?'); params.push(recordType); }
  if (q) { clauses.push('(u.full_name LIKE ? OR a.record_id LIKE ? OR a.detail LIKE ? OR a.ip_address LIKE ?)'); params.push(`%${q}%`, `%${q}%`, `%${q}%`, `%${q}%`); }
  if (from) { clauses.push('a.created_at >= ?'); params.push(from); }
  if (to) { clauses.push('a.created_at <= ?'); params.push(to); }
  return { where: clauses.length ? `WHERE ${clauses.join(' AND ')}` : '', params };
}

/** GET /api/audit?action=&recordType=&q=&from=&to= */
router.get('/', asyncHandler(async (req, res) => {
  const { where, params } = buildAuditFilters(req.query);
  const [rows] = await pool.query(
    `SELECT a.id, a.created_at, u.full_name AS user_name, a.action, a.record_type, a.record_id, a.detail, a.ip_address
     FROM audit_log a LEFT JOIN users u ON u.id = a.user_id
     ${where} ORDER BY a.id DESC LIMIT 500`,
    params
  );
  return ok(res, rows);
}));

/** GET /api/audit/record-types — distinct record_type values seen so far, for the filter dropdown. */
router.get('/record-types', asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT DISTINCT record_type FROM audit_log WHERE record_type IS NOT NULL ORDER BY record_type`
  );
  return ok(res, rows.map((r) => r.record_type));
}));

/**
 * GET /api/audit/export.csv?action=&recordType=&q=&from=&to=
 * Now respects the same filters as the on-screen list (previously always
 * exported the unfiltered top bulk_export_limit rows regardless of what
 * was showing on screen).
 */
router.get('/export.csv', asyncHandler(async (req, res) => {
  const limit = await getSettingInt('bulk_export_limit', 500);
  const { where, params } = buildAuditFilters(req.query);
  const [rows] = await pool.query(
    `SELECT a.id, a.created_at, u.full_name AS user_name, a.action, a.record_type, a.record_id, a.detail, a.ip_address
     FROM audit_log a LEFT JOIN users u ON u.id = a.user_id
     ${where} ORDER BY a.id DESC LIMIT ?`,
    [...params, limit]
  );
  const header = 'id,created_at,user_name,action,record_type,record_id,detail,ip_address\n';
  const csvEscape = (v) => (v === null || v === undefined ? '' : `"${String(v).replace(/"/g, '""')}"`);
  const body = rows.map((r) => Object.values(r).map(csvEscape).join(',')).join('\n');

  await logAudit({ userId: req.user.id, action: 'Download', recordType: 'audit_log', recordId: 'export', detail: `${rows.length} rows`, ip: req.ip });

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename="audit-export.csv"');
  return res.send(header + body);
}));

/** GET /api/audit/verify-chain */
router.get('/verify-chain', asyncHandler(async (req, res) => {
  const result = await verifyChain();
  return ok(res, result, result.valid ? 'Hash chain verified — no gaps' : 'Hash chain broken');
}));

module.exports = router;
