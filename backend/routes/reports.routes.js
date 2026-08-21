/**
 * routes/reports.routes.js
 * Aggregate reporting used by the Reports screen — records by status/
 * department/category/folder/classification, storage capacity, capture
 * automation health, records-captured trend, claim turnaround, retention/
 * disposal status, and audit activity. Every document-based endpoint
 * accepts the same optional filters (from/to/departmentId/documentTypeId/
 * folderId/classification) via services/reports.service.js so the whole
 * screen can be sliced consistently.
 */
const express = require('express');
const { pool } = require('../config/db');
const { ok } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { getSettingInt } = require('../services/settings.service');
const { buildDocumentFilters } = require('../services/reports.service');
const { toCsv, toXlsxBuffer, toPdfBuffer } = require('../utils/exportTable');
const { logAudit } = require('../services/audit.service');
const aclService = require('../services/acl.service');

const router = express.Router();
router.use(authenticate);
router.use(requireModuleAccess('reports'));

/**
 * GET /api/reports/by-status
 * ACL-aware (unlike every other report below) — this is what feeds the
 * Dashboard's "Total records" KPI, which must match what Repository's own
 * list shows for this exact user, not a raw org-wide count. A document
 * restricted by document_acl to other users/groups (see acl.service.js)
 * would otherwise still swell this total even though it never appears in
 * that user's own Repository view.
 */
router.get('/by-status', asyncHandler(async (req, res) => {
  const { where, params } = buildDocumentFilters(req.query);
  const [rows] = await pool.query(`SELECT d.id, d.status FROM documents d ${where}`, params);
  const accessible = await aclService.filterAccessible(req.user.id, req.user.role, 'document', rows);

  const counts = new Map();
  for (const row of accessible) counts.set(row.status, (counts.get(row.status) || 0) + 1);
  return ok(res, [...counts.entries()].map(([status, total]) => ({ status, total })));
}));

/** GET /api/reports/by-department */
router.get('/by-department', asyncHandler(async (req, res) => {
  const { where, params } = buildDocumentFilters(req.query);
  const [rows] = await pool.query(
    `SELECT dep.name AS department, COUNT(*) AS total
     FROM documents d LEFT JOIN departments dep ON dep.id = d.department_id
     ${where} GROUP BY dep.name`,
    params
  );
  return ok(res, rows);
}));

/** GET /api/reports/by-category — document counts + total current-version size by document type. */
router.get('/by-category', asyncHandler(async (req, res) => {
  const { where, params } = buildDocumentFilters(req.query);
  const [rows] = await pool.query(
    `SELECT dt.name AS category, COUNT(*) AS total, COALESCE(SUM(v.size_bytes), 0) AS totalBytes
     FROM documents d
     JOIN document_types dt ON dt.id = d.document_type_id
     LEFT JOIN document_versions v ON v.id = d.current_version_id
     ${where} GROUP BY dt.name`,
    params
  );
  return ok(res, rows);
}));

/** GET /api/reports/by-folder — document counts + total current-version size by folder ("folder capacity"), top 15 by volume. */
router.get('/by-folder', asyncHandler(async (req, res) => {
  const { where, params } = buildDocumentFilters(req.query);
  const [rows] = await pool.query(
    `SELECT f.path AS folder, COUNT(*) AS total, COALESCE(SUM(v.size_bytes), 0) AS totalBytes
     FROM documents d
     JOIN folders f ON f.id = d.folder_id
     LEFT JOIN document_versions v ON v.id = d.current_version_id
     ${where} GROUP BY f.path ORDER BY total DESC LIMIT 15`,
    params
  );
  return ok(res, rows);
}));

/** GET /api/reports/by-classification — document counts by classification level. */
router.get('/by-classification', asyncHandler(async (req, res) => {
  const { where, params } = buildDocumentFilters(req.query);
  const [rows] = await pool.query(
    `SELECT d.classification, COUNT(*) AS total FROM documents d ${where} GROUP BY d.classification`,
    params
  );
  return ok(res, rows);
}));

/**
 * GET /api/reports/capacity — real storage usage (SUM of every stored
 * object, all versions, not just current) against the admin-configured
 * storage_capacity_bytes setting. Deliberately unfiltered — a point-in-time
 * global total, not meaningfully sliceable by the document filters above.
 */
router.get('/capacity', asyncHandler(async (req, res) => {
  const [[{ usedBytes, objectCount }]] = await pool.query(
    'SELECT COALESCE(SUM(size_bytes), 0) AS usedBytes, COUNT(*) AS objectCount FROM document_storage_objects'
  );
  const [[{ documentCount }]] = await pool.query('SELECT COUNT(*) AS documentCount FROM documents');
  const capacityBytes = await getSettingInt('storage_capacity_bytes', 107374182400);
  return ok(res, { usedBytes: Number(usedBytes), objectCount: Number(objectCount), documentCount: Number(documentCount), capacityBytes });
}));

/** GET /api/reports/captured-over-time — documents registered per month, a growth trend. */
router.get('/captured-over-time', asyncHandler(async (req, res) => {
  const { where, params } = buildDocumentFilters(req.query);
  const [rows] = await pool.query(
    `SELECT DATE_FORMAT(d.created_at, '%Y-%m') AS month, COUNT(*) AS total
     FROM documents d ${where} GROUP BY month ORDER BY month`,
    params
  );
  return ok(res, rows);
}));

/**
 * GET /api/reports/capture-by-source — automated/manual intake health:
 * volume and average success rate per capture channel.
 */
router.get('/capture-by-source', asyncHandler(async (req, res) => {
  const clauses = [];
  const params = [];
  if (req.query.from) { clauses.push('created_at >= ?'); params.push(req.query.from); }
  if (req.query.to) { clauses.push('created_at <= ?'); params.push(req.query.to); }
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';

  const [rows] = await pool.query(
    `SELECT source, COUNT(*) AS total, ROUND(AVG(success_rate), 1) AS avgSuccessRate
     FROM capture_batches ${where} GROUP BY source ORDER BY total DESC`,
    params
  );
  return ok(res, rows.map((r) => ({ ...r, total: Number(r.total), avgSuccessRate: Number(r.avgSuccessRate) })));
}));

/**
 * GET /api/reports/retention-status — documents per retention class, with
 * how many of each have actually reached disposal.
 */
router.get('/retention-status', asyncHandler(async (req, res) => {
  const { where, params } = buildDocumentFilters(req.query);
  const [rows] = await pool.query(
    `SELECT COALESCE(rc.name, 'No retention class') AS retentionClass,
            COUNT(*) AS total, SUM(d.status = 'disposed') AS disposed
     FROM documents d LEFT JOIN retention_classes rc ON rc.id = d.retention_class_id
     ${where} GROUP BY rc.name`,
    params
  );
  return ok(res, rows.map((r) => ({ ...r, total: Number(r.total), disposed: Number(r.disposed) })));
}));

/** GET /api/reports/claim-turnaround — avg days from registration to first approval decision, by month. */
router.get('/claim-turnaround', asyncHandler(async (req, res) => {
  const clauses = [];
  const params = [];
  if (req.query.from) { clauses.push('d.created_at >= ?'); params.push(req.query.from); }
  if (req.query.to) { clauses.push('d.created_at <= ?'); params.push(req.query.to); }
  const where = clauses.length ? `AND ${clauses.join(' AND ')}` : '';

  const [rows] = await pool.query(
    `SELECT DATE_FORMAT(d.created_at, '%Y-%m') AS month,
            ROUND(AVG(DATEDIFF(wa.decided_at, dwi.started_at)), 1) AS avg_days_to_first_decision
     FROM documents d
     JOIN document_workflow_instances dwi ON dwi.document_id = d.id
     JOIN workflow_approvals wa ON wa.instance_id = dwi.id AND wa.decision <> 'pending'
     WHERE 1=1 ${where}
     GROUP BY month ORDER BY month`,
    params
  );
  return ok(res, rows);
}));

/** GET /api/reports/audit-actions — action counts, for a quick activity chart. */
router.get('/audit-actions', asyncHandler(async (req, res) => {
  const clauses = [];
  const params = [];
  if (req.query.from) { clauses.push('created_at >= ?'); params.push(req.query.from); }
  if (req.query.to) { clauses.push('created_at <= ?'); params.push(req.query.to); }
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';

  const [rows] = await pool.query(`SELECT action, COUNT(*) AS total FROM audit_log ${where} GROUP BY action ORDER BY total DESC`, params);
  return ok(res, rows);
}));

/**
 * GET /api/reports/overdue-retention — how many declared-final records
 * have passed their retention_due_at without being disposed yet. A
 * records manager's "needs action" number — deliberately unfiltered by
 * the document filters above, same reasoning as /capacity.
 */
router.get('/overdue-retention', asyncHandler(async (req, res) => {
  const [[{ count }]] = await pool.query(
    `SELECT COUNT(*) AS count FROM documents
     WHERE status = 'declared_final' AND retention_due_at IS NOT NULL AND retention_due_at < NOW()`
  );
  return ok(res, { count: Number(count) });
}));

/** GET /api/reports/top-users — the 10 most active audit actors. */
router.get('/top-users', asyncHandler(async (req, res) => {
  const clauses = [];
  const params = [];
  if (req.query.from) { clauses.push('a.created_at >= ?'); params.push(req.query.from); }
  if (req.query.to) { clauses.push('a.created_at <= ?'); params.push(req.query.to); }
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';

  const [rows] = await pool.query(
    `SELECT COALESCE(u.full_name, 'System') AS userName, COUNT(*) AS total
     FROM audit_log a LEFT JOIN users u ON u.id = a.user_id
     ${where} GROUP BY userName ORDER BY total DESC LIMIT 10`,
    params
  );
  return ok(res, rows);
}));

/**
 * Runs every section this screen shows, respecting the same document
 * filters as the on-screen cards, so the export can never drift from what
 * "Reports" is currently displaying. Shared by GET /export's csv/xlsx/pdf
 * branches below.
 */
async function buildReportSections(query) {
  const { where, params } = buildDocumentFilters(query);
  const dateWhere = [];
  const dateParams = [];
  if (query.from) { dateWhere.push('created_at >= ?'); dateParams.push(query.from); }
  if (query.to) { dateWhere.push('created_at <= ?'); dateParams.push(query.to); }
  const dateClause = dateWhere.length ? `WHERE ${dateWhere.join(' AND ')}` : '';

  const [byStatus] = await pool.query(`SELECT d.status, COUNT(*) AS total FROM documents d ${where} GROUP BY d.status`, params);
  const [byDepartment] = await pool.query(
    `SELECT dep.name AS department, COUNT(*) AS total FROM documents d LEFT JOIN departments dep ON dep.id = d.department_id ${where} GROUP BY dep.name`,
    params
  );
  const [byCategory] = await pool.query(
    `SELECT dt.name AS category, COUNT(*) AS total, COALESCE(SUM(v.size_bytes), 0) AS totalBytes
     FROM documents d JOIN document_types dt ON dt.id = d.document_type_id LEFT JOIN document_versions v ON v.id = d.current_version_id
     ${where} GROUP BY dt.name`,
    params
  );
  const [byFolder] = await pool.query(
    `SELECT f.path AS folder, COUNT(*) AS total, COALESCE(SUM(v.size_bytes), 0) AS totalBytes
     FROM documents d JOIN folders f ON f.id = d.folder_id LEFT JOIN document_versions v ON v.id = d.current_version_id
     ${where} GROUP BY f.path ORDER BY total DESC LIMIT 15`,
    params
  );
  const [byClassification] = await pool.query(`SELECT d.classification, COUNT(*) AS total FROM documents d ${where} GROUP BY d.classification`, params);
  const [[capacity]] = await pool.query('SELECT COALESCE(SUM(size_bytes), 0) AS usedBytes, COUNT(*) AS objectCount FROM document_storage_objects');
  const [[{ documentCount }]] = await pool.query('SELECT COUNT(*) AS documentCount FROM documents');
  const capacityBytes = await getSettingInt('storage_capacity_bytes', 107374182400);
  const [capturedOverTime] = await pool.query(
    `SELECT DATE_FORMAT(d.created_at, '%Y-%m') AS month, COUNT(*) AS total FROM documents d ${where} GROUP BY month ORDER BY month`,
    params
  );
  const [captureBySource] = await pool.query(
    `SELECT source, COUNT(*) AS total, ROUND(AVG(success_rate), 1) AS avgSuccessRate FROM capture_batches ${dateClause} GROUP BY source ORDER BY total DESC`,
    dateParams
  );
  const [retentionStatus] = await pool.query(
    `SELECT COALESCE(rc.name, 'No retention class') AS retentionClass, COUNT(*) AS total, SUM(d.status = 'disposed') AS disposed
     FROM documents d LEFT JOIN retention_classes rc ON rc.id = d.retention_class_id ${where} GROUP BY rc.name`,
    params
  );
  const [[overdue]] = await pool.query(
    `SELECT COUNT(*) AS count FROM documents WHERE status = 'declared_final' AND retention_due_at IS NOT NULL AND retention_due_at < NOW()`
  );
  const [auditActions] = await pool.query(`SELECT action, COUNT(*) AS total FROM audit_log ${dateClause} GROUP BY action ORDER BY total DESC`, dateParams);
  const [topUsers] = await pool.query(
    `SELECT COALESCE(u.full_name, 'System') AS userName, COUNT(*) AS total FROM audit_log a LEFT JOIN users u ON u.id = a.user_id
     ${dateClause.replace(/created_at/g, 'a.created_at')} GROUP BY userName ORDER BY total DESC LIMIT 10`,
    dateParams
  );

  return [
    { name: 'Records by status', title: 'Records by status', headers: ['status', 'total'], rows: byStatus },
    { name: 'Records by department', title: 'Records by department', headers: ['department', 'total'], rows: byDepartment },
    { name: 'Records by category', title: 'Records by category', headers: ['category', 'total', 'totalBytes'], rows: byCategory },
    { name: 'Records by folder', title: 'Records by folder (top 15)', headers: ['folder', 'total', 'totalBytes'], rows: byFolder },
    { name: 'Records by classification', title: 'Records by classification', headers: ['classification', 'total'], rows: byClassification },
    { name: 'Storage capacity', title: 'Storage capacity', headers: ['usedBytes', 'objectCount', 'documentCount', 'capacityBytes'], rows: [{ ...capacity, documentCount, capacityBytes }] },
    { name: 'Captured over time', title: 'Records captured over time', headers: ['month', 'total'], rows: capturedOverTime },
    { name: 'Capture by source', title: 'Capture success by source', headers: ['source', 'total', 'avgSuccessRate'], rows: captureBySource },
    { name: 'Retention status', title: 'Retention & disposal status', headers: ['retentionClass', 'total', 'disposed'], rows: retentionStatus },
    { name: 'Overdue retention', title: 'Overdue for disposal', headers: ['count'], rows: [overdue] },
    { name: 'Audit actions', title: 'Audit actions breakdown', headers: ['action', 'total'], rows: auditActions },
    { name: 'Top audit actors', title: 'Top audit actors', headers: ['userName', 'total'], rows: topUsers },
  ];
}

/** GET /api/reports/export?format=csv|xlsx|pdf — every card on this screen, respecting the same filters, as one document. */
router.get('/export', asyncHandler(async (req, res) => {
  const format = ['csv', 'xlsx', 'pdf'].includes(req.query.format) ? req.query.format : 'csv';
  const sections = await buildReportSections(req.query);

  await logAudit({ userId: req.user.id, action: 'Download', recordType: 'report', recordId: 'export', detail: `format=${format}`, ip: req.ip });

  if (format === 'xlsx') {
    res.setHeader('Content-Type', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    res.setHeader('Content-Disposition', 'attachment; filename="reports-export.xlsx"');
    return res.send(toXlsxBuffer(sections));
  }
  if (format === 'pdf') {
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', 'attachment; filename="reports-export.pdf"');
    return res.send(await toPdfBuffer('Reports Export', sections));
  }
  // csv: one section per block, separated by a blank line and its own header row — a single flat CSV can't represent multiple differently-shaped tables otherwise.
  const csv = sections.map((s) => `${s.name}\n${toCsv(s.headers, s.rows)}`).join('\n\n');
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename="reports-export.csv"');
  return res.send(csv);
}));

module.exports = router;
