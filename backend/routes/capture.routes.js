/**
 * routes/capture.routes.js
 * Capture & Scan: batch list/detail/export, manual bulk upload (which
 * covers "manual" and "device" intake — a browser file picker on a mobile
 * device already opens the camera/gallery natively, so no separate device
 * API is needed), a retroactive manual stats-entry endpoint, and a narrow
 * read-only status view of the automated intake connectors. The actual
 * automated polling lives in services/capture/scheduler.js and
 * services/capture/batch.service.js; this file is the HTTP surface over
 * that plus the older manual-entry path.
 *
 * Route order matters: literal paths (/summary, /connector-status,
 * /export.csv, /upload) must be registered before /:id, same discipline as
 * integrations.routes.js and permissions.routes.js.
 */
const express = require('express');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const upload = require('../middleware/upload.middleware');
const { logAudit } = require('../services/audit.service');
const { getSettingInt } = require('../services/settings.service');
const { runBatch } = require('../services/capture/batch.service');
const { CONNECTORS: INTAKE_CONNECTORS } = require('../services/capture/scheduler');

const router = express.Router();
router.use(authenticate);

/** GET /api/capture-batches/summary — throughput per intake source, for the KPI dashboard. */
router.get('/summary', requireModuleAccess('capture'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT source, COUNT(*) AS batches, SUM(pages) AS total_pages, SUM(documents) AS total_documents,
            ROUND(AVG(success_rate), 1) AS avg_success_rate
     FROM capture_batches GROUP BY source`
  );
  return ok(res, rows);
}));

/**
 * GET /api/capture-batches/connector-status — id/name/status/last_sync_at
 * only for the three automated intake connectors, deliberately narrower
 * than GET /api/integrations (admin-only, includes config_json) — same
 * pattern as integrations.routes.js's /storage-options. Lets a Records
 * Officer see "last run 2 min ago" without seeing connection credentials.
 */
router.get('/connector-status', requireModuleAccess('capture'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT id, name, status, last_sync_at FROM integrations WHERE id IN (?) ORDER BY name`,
    [Object.keys(INTAKE_CONNECTORS)]
  );
  return ok(res, rows);
}));

/** GET /api/capture-batches/export.csv */
router.get('/export.csv', requireModuleAccess('capture'), asyncHandler(async (req, res) => {
  const limit = await getSettingInt('bulk_export_limit', 500);
  const [rows] = await pool.query(
    `SELECT b.id, b.batch_no, b.source, b.status, b.pages, b.documents, b.success_rate,
            b.started_at, b.completed_at, u.full_name AS created_by
     FROM capture_batches b LEFT JOIN users u ON u.id = b.created_by
     ORDER BY b.id DESC LIMIT ?`,
    [limit]
  );
  const header = 'id,batch_no,source,status,pages,documents,success_rate,started_at,completed_at,created_by\n';
  const csvEscape = (v) => (v === null || v === undefined ? '' : `"${String(v).replace(/"/g, '""')}"`);
  const body = rows.map((r) => Object.values(r).map(csvEscape).join(',')).join('\n');

  await logAudit({ userId: req.user.id, action: 'Download', recordType: 'capture_batch', recordId: 'export', ip: req.ip });

  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename="capture-batches-export.csv"');
  return res.send(header + body);
}));

/**
 * POST /api/capture-batches/upload — multipart, multiple files. Manual or
 * device bulk upload: "batching of documents (uploading in bulk)". Each
 * file is auto-classified and registered through the same pipeline as
 * automated intake (services/capture/batch.service.js), synchronously —
 * fine for the small batches a human uploads in one sitting.
 */
router.post(
  '/upload',
  requireModuleAccess('capture', true),
  upload.array('files', 50),
  asyncHandler(async (req, res) => {
    if (!req.files || req.files.length === 0) return fail(res, 'At least one file is required', 400);

    const source = req.body.source === 'device_upload' ? 'device_upload' : 'manual_upload';
    const defaultFolderId = req.body.folderId ? Number(req.body.folderId) : undefined;

    const result = await runBatch({
      source,
      files: req.files.map((f) => ({ fileName: f.originalname, buffer: f.buffer, mimeType: f.mimetype })),
      defaultFolderId,
      createdBy: req.user.id,
      ip: req.ip,
    });
    return ok(res, result, 'Batch uploaded', 201);
  })
);

/** GET /api/capture-batches?source=&status=&from=&to= — real batch rows (not just the aggregate summary). */
router.get('/', requireModuleAccess('capture'), asyncHandler(async (req, res) => {
  const { source, status, from, to } = req.query;
  const clauses = [];
  const params = [];
  if (source) { clauses.push('b.source = ?'); params.push(source); }
  if (status) { clauses.push('b.status = ?'); params.push(status); }
  if (from) { clauses.push('b.created_at >= ?'); params.push(from); }
  if (to) { clauses.push('b.created_at <= ?'); params.push(to); }
  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';

  const [rows] = await pool.query(
    `SELECT b.id, b.batch_no, b.source, b.status, b.pages, b.documents, b.success_rate,
            b.started_at, b.completed_at, b.created_at, u.full_name AS created_by
     FROM capture_batches b LEFT JOIN users u ON u.id = b.created_by
     ${where} ORDER BY b.created_at DESC LIMIT 200`,
    params
  );
  return ok(res, rows);
}));

/**
 * POST /api/capture-batches — retroactive manual stats-entry (e.g. logging
 * a scanning session that had no network integration, after the fact). No
 * file upload, no per-document linkage — kept alongside the real /upload
 * path for cases where there's genuinely nothing to upload.
 */
router.post('/', requireModuleAccess('capture', true), asyncHandler(async (req, res) => {
  const { batchNo, source, pages, documents, successRate } = req.body;
  const [result] = await pool.query(
    `INSERT INTO capture_batches (company_id, batch_no, source, status, pages, documents, success_rate, created_by, started_at, completed_at)
     VALUES (?, ?, ?, 'completed', ?, ?, ?, ?, NOW(), NOW())`,
    [req.user.companyId, batchNo, source, pages || 0, documents || 0, successRate || 0, req.user.id]
  );
  await logAudit({ userId: req.user.id, action: 'Capture', recordType: 'capture_batch', recordId: result.insertId, detail: `${source}: ${documents} records (manual log)`, ip: req.ip });
  return ok(res, { id: result.insertId }, 'Batch recorded', 201);
}));

/**
 * GET /api/capture-batches/:id — batch detail with per-item outcomes.
 * Selects the same shape as GET / (created_by aliased to the user's name,
 * not the raw id) so CaptureBatchRow.fromJson on the frontend can parse
 * both responses identically.
 */
router.get('/:id', requireModuleAccess('capture'), asyncHandler(async (req, res) => {
  const [[batch]] = await pool.query(
    `SELECT b.id, b.batch_no, b.source, b.status, b.pages, b.documents, b.success_rate,
            b.started_at, b.completed_at, b.created_at, u.full_name AS created_by
     FROM capture_batches b LEFT JOIN users u ON u.id = b.created_by WHERE b.id = ?`,
    [req.params.id]
  );
  if (!batch) return fail(res, 'Batch not found', 404);

  const [items] = await pool.query(
    `SELECT i.id, i.source_file_name, i.status, i.error_message, i.document_id,
            d.record_no, d.title
     FROM capture_batch_items i LEFT JOIN documents d ON d.id = i.document_id
     WHERE i.batch_id = ? ORDER BY i.id`,
    [req.params.id]
  );
  return ok(res, { ...batch, items });
}));

module.exports = router;
