/**
 * routes/retention.routes.js
 * Retention & disposal schedules and the disposal queue (records past
 * their retention_due_at), gated behind Records Manager approval.
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { createNotification } = require('../services/notifications.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/retention/classes */
router.get('/classes', requireModuleAccess('retention'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT * FROM retention_classes ORDER BY name');
  return ok(res, rows);
}));

/** PUT /api/retention/classes/:id — Records Manager approval required (per prototype). */
router.put(
  '/classes/:id',
  requireModuleAccess('retention', true),
  [body('retentionYears').optional().isInt({ min: 1 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { retentionYears, disposalAction, name } = req.body;
    await pool.query(
      `UPDATE retention_classes SET
         retention_years = COALESCE(?, retention_years),
         disposal_action = COALESCE(?, disposal_action),
         name = COALESCE(?, name)
       WHERE id = ?`,
      [retentionYears || null, disposalAction || null, name || null, req.params.id]
    );
    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'retention_class', recordId: req.params.id, ip: req.ip });
    return ok(res, null, 'Retention schedule updated');
  })
);

/** POST /api/retention/classes — { code, name, retentionYears, triggerEvent?, disposalAction? } */
router.post(
  '/classes',
  requireModuleAccess('retention', true),
  [body('code').trim().notEmpty(), body('name').trim().notEmpty(), body('retentionYears').isInt({ min: 1 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { code, name, retentionYears, triggerEvent, disposalAction } = req.body;
    const [existing] = await pool.query('SELECT id FROM retention_classes WHERE code = ?', [code]);
    if (existing.length) return fail(res, 'A retention class with this code already exists', 409);

    const [result] = await pool.query(
      `INSERT INTO retention_classes (code, name, retention_years, trigger_event, disposal_action)
       VALUES (?, ?, ?, ?, ?)`,
      [code, name, retentionYears, triggerEvent || 'record declared final', disposalAction || 'review']
    );
    await logAudit({ userId: req.user.id, action: 'Create', recordType: 'retention_class', recordId: result.insertId, detail: name, ip: req.ip });
    return ok(res, { id: result.insertId }, 'Retention schedule created', 201);
  })
);

/** DELETE /api/retention/classes/:id — refuses if still referenced by folders or documents. */
router.delete('/classes/:id', requireModuleAccess('retention', true), asyncHandler(async (req, res) => {
  const [[cls]] = await pool.query('SELECT id, name FROM retention_classes WHERE id = ?', [req.params.id]);
  if (!cls) return fail(res, 'Retention schedule not found', 404);

  const [[{ docCount }]] = await pool.query('SELECT COUNT(*) AS docCount FROM documents WHERE retention_class_id = ?', [req.params.id]);
  const [[{ folderCount }]] = await pool.query('SELECT COUNT(*) AS folderCount FROM folders WHERE retention_class_id = ?', [req.params.id]);
  if (docCount > 0 || folderCount > 0) return fail(res, 'Cannot delete a retention schedule still assigned to folders or records', 409);

  await pool.query('DELETE FROM retention_classes WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'retention_class', recordId: req.params.id, detail: cls.name, ip: req.ip });
  return ok(res, null, 'Retention schedule deleted');
}));

/** GET /api/retention/due — records whose retention_due_at has passed and are eligible for disposal. */
router.get('/due', requireModuleAccess('retention'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT d.id, d.record_no, d.title, d.retention_due_at, rc.disposal_action, rc.name AS retention_class_name
     FROM documents d JOIN retention_classes rc ON rc.id = d.retention_class_id
     WHERE d.status = 'declared_final' AND d.retention_due_at <= NOW()
     ORDER BY d.retention_due_at ASC`
  );
  return ok(res, rows);
}));

/** POST /api/retention/:documentId/dispose — Records Manager approval required. */
router.post('/:documentId/dispose', requireModuleAccess('retention', true), asyncHandler(async (req, res) => {
  const [[doc]] = await pool.query('SELECT owner_id, record_no, title FROM documents WHERE id = ?', [req.params.documentId]);
  if (!doc) return fail(res, 'Record not found', 404);

  await pool.query('UPDATE documents SET status = "disposed" WHERE id = ?', [req.params.documentId]);
  await logAudit({ userId: req.user.id, action: 'Disposal', recordType: 'document', recordId: req.params.documentId, ip: req.ip });
  await createNotification({
    userId: doc.owner_id,
    type: 'record_disposed',
    title: `Disposed: ${doc.record_no}`,
    body: `"${doc.title}" was marked disposed.`,
    relatedRecordType: 'document',
    relatedRecordId: req.params.documentId,
  });
  return ok(res, null, 'Record marked disposed');
}));

module.exports = router;
