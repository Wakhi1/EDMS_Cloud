/**
 * routes/document-types.routes.js
 * Document type lookup list (Claim — Retirement, Claim — Ill Health,
 * Contribution Statement, Payout Voucher, Member Statement, ...), with
 * admin-gated create/edit/delete — Records Manager owns the classification
 * scheme in practice, so it shares the `retention` module's edit gate.
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

/** GET /api/document-types */
router.get('/', requireModuleAccess('repository'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query('SELECT id, name, code FROM document_types ORDER BY name');
  return ok(res, rows);
}));

/** POST /api/document-types — { name, code } */
router.post(
  '/',
  allowRoles('Records Manager', 'System Administrator'),
  [body('name').trim().notEmpty(), body('code').trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const { name, code } = req.body;
    const [existing] = await pool.query('SELECT id FROM document_types WHERE name = ? OR code = ?', [name, code]);
    if (existing.length) return fail(res, 'A document type with this name or code already exists', 409);

    const [result] = await pool.query('INSERT INTO document_types (name, code) VALUES (?, ?)', [name, code.toUpperCase()]);
    await logAudit({ userId: req.user.id, action: 'Create', recordType: 'document_type', recordId: result.insertId, detail: name, ip: req.ip });
    return ok(res, { id: result.insertId }, 'Document type created', 201);
  })
);

/** PUT /api/document-types/:id — { name?, code? } */
router.put(
  '/:id',
  allowRoles('Records Manager', 'System Administrator'),
  [body('name').optional().trim().notEmpty(), body('code').optional().trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[type]] = await pool.query('SELECT id FROM document_types WHERE id = ?', [req.params.id]);
    if (!type) return fail(res, 'Document type not found', 404);

    const { name, code } = req.body;
    await pool.query(
      'UPDATE document_types SET name = COALESCE(?, name), code = COALESCE(?, code) WHERE id = ?',
      [name || null, code ? code.toUpperCase() : null, req.params.id]
    );
    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'document_type', recordId: req.params.id, ip: req.ip });
    return ok(res, null, 'Document type updated');
  })
);

/** DELETE /api/document-types/:id — refuses if still referenced by documents. */
router.delete('/:id', allowRoles('Records Manager', 'System Administrator'), asyncHandler(async (req, res) => {
  const [[type]] = await pool.query('SELECT id, name FROM document_types WHERE id = ?', [req.params.id]);
  if (!type) return fail(res, 'Document type not found', 404);

  const [[{ docCount }]] = await pool.query('SELECT COUNT(*) AS docCount FROM documents WHERE document_type_id = ?', [req.params.id]);
  if (docCount > 0) return fail(res, 'Cannot delete a document type still used by existing records', 409);

  await pool.query('DELETE FROM document_types WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'document_type', recordId: req.params.id, detail: type.name, ip: req.ip });
  return ok(res, null, 'Document type deleted');
}));

module.exports = router;
