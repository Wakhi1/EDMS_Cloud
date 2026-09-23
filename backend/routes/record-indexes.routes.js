/**
 * routes/record-indexes.routes.js
 * Admin-issued record indexes — see services/recordIndex.service.js for the
 * claim/release lifecycle. GET /available is the narrow lookup every upload
 * path uses (gated by 'capture', same as the manual-upload route); the rest
 * of this file is the admin management surface (gated by 'indexing').
 */
const express = require('express');
const { body, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const { logAudit } = require('../services/audit.service');
const { generateIndexValues } = require('../services/recordIndex.service');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/record-indexes/available?documentTypeId= — narrow {id, indexValue}
 * list for populating an upload flow's picker. Registered before /:id-style
 * routes per this codebase's established route-ordering discipline.
 */
router.get('/available', requireModuleAccess('capture'), asyncHandler(async (req, res) => {
  const { documentTypeId } = req.query;
  if (!documentTypeId) return fail(res, 'documentTypeId is required', 400);

  const [rows] = await pool.query(
    `SELECT id, index_value AS indexValue FROM record_indexes
     WHERE company_id = ? AND document_type_id = ? AND status = 'available' ORDER BY id`,
    [req.user.companyId, documentTypeId]
  );
  return ok(res, rows);
}));

/** GET /api/record-indexes?documentTypeId=&status= — full admin list. */
router.get('/', requireModuleAccess('indexing'), asyncHandler(async (req, res) => {
  const { documentTypeId, status } = req.query;
  const clauses = ['ri.company_id = ?'];
  const params = [req.user.companyId];
  if (documentTypeId) { clauses.push('ri.document_type_id = ?'); params.push(documentTypeId); }
  if (status) { clauses.push('ri.status = ?'); params.push(status); }

  const [rows] = await pool.query(
    `SELECT ri.id, ri.document_type_id AS documentTypeId, dt.name AS documentTypeName, ri.index_value AS indexValue,
            ri.status, ri.used_by_document_id AS usedByDocumentId, d.title AS usedByTitle,
            ri.created_at AS createdAt, ri.used_at AS usedAt
     FROM record_indexes ri
     JOIN document_types dt ON dt.id = ri.document_type_id
     LEFT JOIN documents d ON d.id = ri.used_by_document_id
     WHERE ${clauses.join(' AND ')} ORDER BY ri.id DESC LIMIT 500`,
    params
  );
  return ok(res, rows);
}));

/** POST /api/record-indexes/generate — { documentTypeId, count } — bulk-creates fresh available rows. */
router.post(
  '/generate',
  requireModuleAccess('indexing', true),
  [body('documentTypeId').isInt(), body('count').isInt({ min: 1, max: 500 })],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { documentTypeId, count } = req.body;
    const [[type]] = await pool.query('SELECT code, name FROM document_types WHERE id = ? AND company_id = ?', [documentTypeId, req.user.companyId]);
    if (!type) return fail(res, 'Unknown document type', 404);

    const values = await generateIndexValues(type.code, Number(count));
    const rows = values.map((v) => [req.user.companyId, documentTypeId, v, req.user.id]);
    await pool.query('INSERT INTO record_indexes (company_id, document_type_id, index_value, created_by) VALUES ?', [rows]);

    await logAudit({
      userId: req.user.id, action: 'Create', recordType: 'record_index', recordId: documentTypeId,
      detail: `Generated ${values.length} indexes for ${type.name}`, ip: req.ip,
    });
    return ok(res, { generated: values }, `${values.length} indexes generated`, 201);
  })
);

/** POST /api/record-indexes — { documentTypeId, indexValue } — single manual add with an admin-chosen exact value. */
router.post(
  '/',
  requireModuleAccess('indexing', true),
  [body('documentTypeId').isInt(), body('indexValue').trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { documentTypeId, indexValue } = req.body;
    const [[type]] = await pool.query('SELECT id FROM document_types WHERE id = ? AND company_id = ?', [documentTypeId, req.user.companyId]);
    if (!type) return fail(res, 'Unknown document type', 404);

    const [[existingIndex]] = await pool.query('SELECT id FROM record_indexes WHERE company_id = ? AND index_value = ?', [req.user.companyId, indexValue]);
    if (existingIndex) return fail(res, 'This index value already exists', 409);
    const [[existingDoc]] = await pool.query('SELECT id FROM documents WHERE company_id = ? AND record_no = ?', [req.user.companyId, indexValue]);
    if (existingDoc) return fail(res, 'This value is already in use as a record number', 409);

    const [result] = await pool.query(
      'INSERT INTO record_indexes (company_id, document_type_id, index_value, created_by) VALUES (?, ?, ?, ?)',
      [req.user.companyId, documentTypeId, indexValue, req.user.id]
    );
    await logAudit({ userId: req.user.id, action: 'Create', recordType: 'record_index', recordId: result.insertId, detail: indexValue, ip: req.ip });
    return ok(res, { id: result.insertId }, 'Index added', 201);
  })
);

/** PUT /api/record-indexes/:id — { documentTypeId } — refile an unused index under another type. */
router.put(
  '/:id',
  requireModuleAccess('indexing', true),
  [body('documentTypeId').isInt()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[row]] = await pool.query('SELECT id, status, index_value FROM record_indexes WHERE id = ? AND company_id = ?', [req.params.id, req.user.companyId]);
    if (!row) return fail(res, 'Index not found', 404);
    if (row.status === 'used') return fail(res, 'Cannot change an index already assigned to a record', 409);
    const [[type]] = await pool.query('SELECT id, name FROM document_types WHERE id = ? AND company_id = ?', [req.body.documentTypeId, req.user.companyId]);
    if (!type) return fail(res, 'Unknown document type', 404);

    await pool.query('UPDATE record_indexes SET document_type_id = ? WHERE id = ?', [type.id, row.id]);
    await logAudit({ userId: req.user.id, action: 'Update', recordType: 'record_index', recordId: row.id, detail: `${row.index_value} → ${type.name}`, ip: req.ip });
    return ok(res, null, 'Index updated');
  })
);

/** DELETE /api/record-indexes/:id — refuses if already used. */
router.delete('/:id', requireModuleAccess('indexing', true), asyncHandler(async (req, res) => {
  const [[row]] = await pool.query('SELECT id, status, index_value FROM record_indexes WHERE id = ? AND company_id = ?', [req.params.id, req.user.companyId]);
  if (!row) return fail(res, 'Index not found', 404);
  if (row.status === 'used') return fail(res, 'Cannot delete an index already assigned to a record', 409);

  await pool.query('DELETE FROM record_indexes WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'record_index', recordId: req.params.id, detail: row.index_value, ip: req.ip });
  return ok(res, null, 'Index deleted');
}));

module.exports = router;
