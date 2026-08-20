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

const router = express.Router();
router.use(authenticate);
router.use(requireModuleAccess('reports'));

/** GET /api/reports/by-status */
router.get('/by-status', asyncHandler(async (req, res) => {
  const { where, params } = buildDocumentFilters(req.query);
  const [rows] = await pool.query(
    `SELECT d.status, COUNT(*) AS total FROM documents d ${where} GROUP BY d.status`,
    params
  );
  return ok(res, rows);
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

module.exports = router;
