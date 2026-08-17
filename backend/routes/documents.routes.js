/**
 * routes/documents.routes.js
 * Document repository: search/list, register a new record (encrypt +
 * upload to the active cloud provider), read metadata, and stream a
 * decrypted copy back to an authorised viewer.
 *
 * Encryption flow on upload:
 *   file bytes -> crypto.service.envelopeEncryptFile() -> ciphertext
 *   ciphertext -> storage.service.uploadEncrypted() -> cloud object
 *   wrapped DEK + IVs + auth tags -> document_encryption_keys row
 *
 * Decryption flow on read:
 *   document_encryption_keys row + cloud object -> crypto.service.envelopeDecryptFile()
 *   -> plaintext bytes streamed to the caller (never written unencrypted to disk)
 */
const express = require('express');
const { body, query, validationResult } = require('express-validator');

const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const upload = require('../middleware/upload.middleware');
const { logAudit } = require('../services/audit.service');
const { envelopeDecryptFile, sha256 } = require('../services/crypto.service');
const storageService = require('../services/storage/storage.service');
const ocrService = require('../services/ocr.service');
const { registerDocument, DuplicateRecordNoError, DuplicateContentError, findDuplicateByContentHash } = require('../services/document.service');
const { suggestMemberNumber, suggestDocumentTypeCode } = require('../services/classification.service');
const { getSettingBool } = require('../services/settings.service');
const { watermarkPdf } = require('../services/watermark.service');
const { redactBankNumbers } = require('../services/redaction.service');
const { autoTriggerWorkflow } = require('../services/workflow.service');
const logger = require('../config/logger');

const router = express.Router();
router.use(authenticate);

/**
 * GET /api/documents?query=&folder=&department=&status=&type=
 * Mirrors the repository/search screens: full text, member number,
 * claim reference, folder and department filters.
 */
router.get('/', requireModuleAccess('repository'), asyncHandler(async (req, res) => {
  const { q, folderId, departmentId, status, documentTypeId, captureBatchId } = req.query;
  const clauses = [];
  const params = [];

  if (q) {
    clauses.push(
      '(MATCH(d.title) AGAINST (? IN NATURAL LANGUAGE MODE) OR d.record_no LIKE ? OR d.member_number LIKE ? ' +
      'OR MATCH(v.ocr_text) AGAINST (? IN NATURAL LANGUAGE MODE) ' +
      'OR EXISTS (SELECT 1 FROM document_custom_fields cf WHERE cf.document_id = d.id ' +
      'AND (cf.field_label LIKE ? OR MATCH(cf.field_value) AGAINST (? IN NATURAL LANGUAGE MODE))))'
    );
    params.push(q, `%${q}%`, `%${q}%`, q, `%${q}%`, q);
  }
  if (folderId) { clauses.push('d.folder_id = ?'); params.push(folderId); }
  if (departmentId) { clauses.push('d.department_id = ?'); params.push(departmentId); }
  if (status) { clauses.push('d.status = ?'); params.push(status); }
  if (documentTypeId) { clauses.push('d.document_type_id = ?'); params.push(documentTypeId); }
  if (captureBatchId) {
    clauses.push('EXISTS (SELECT 1 FROM capture_batch_items cbi WHERE cbi.document_id = d.id AND cbi.batch_id = ?)');
    params.push(captureBatchId);
  }

  const where = clauses.length ? `WHERE ${clauses.join(' AND ')}` : '';
  const [rows] = await pool.query(
    `SELECT d.id, d.record_no, d.title, d.status, d.classification, d.member_number,
            d.member_name, d.created_at, d.updated_at,
            dt.name AS document_type, dep.name AS department, f.path AS folder_path,
            v.version_no AS current_version_no, u.full_name AS owner_name
     FROM documents d
     JOIN document_types dt ON dt.id = d.document_type_id
     LEFT JOIN departments dep ON dep.id = d.department_id
     JOIN folders f ON f.id = d.folder_id
     LEFT JOIN document_versions v ON v.id = d.current_version_id
     JOIN users u ON u.id = d.owner_id
     ${where}
     ORDER BY d.created_at DESC
     LIMIT 200`,
    params
  );
  return ok(res, rows);
}));

/** GET /api/documents/:id — full metadata for the document viewer. */
router.get('/:id', requireModuleAccess('viewer'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT d.*, dt.name AS document_type, f.path AS folder_path, u.full_name AS owner_name
     FROM documents d
     JOIN document_types dt ON dt.id = d.document_type_id
     JOIN folders f ON f.id = d.folder_id
     JOIN users u ON u.id = d.owner_id
     WHERE d.id = ?`,
    [req.params.id]
  );
  if (!rows[0]) return fail(res, 'Record not found', 404);

  await logAudit({ userId: req.user.id, action: 'View', recordType: 'document', recordId: req.params.id, ip: req.ip });
  return ok(res, rows[0]);
}));

/**
 * POST /api/documents
 * multipart/form-data: file + recordNo, title, documentTypeId, folderId,
 * departmentId, memberNumber, memberName, classification, retentionClassId,
 * plus two optional Smart Upload extras:
 *   - storageProviderId / storagePrefix: where the encrypted object
 *     physically lands (defaults to the global active provider / no
 *     prefix, i.e. today's behaviour, when omitted).
 *   - customFields: JSON-encoded array of {label, value} — optional
 *     user-defined tags, stored in document_custom_fields and indexed
 *     alongside title/OCR text in GET /'s search.
 * Registers the record, encrypts the file, uploads it, and writes version 1.
 */
router.post(
  '/',
  requireModuleAccess('capture', true),
  upload.single('file'),
  [
    body('recordNo').trim().notEmpty(),
    body('title').trim().notEmpty(),
    body('documentTypeId').isInt(),
    body('folderId').isInt(),
  ],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());
    if (!req.file) return fail(res, 'A file is required', 400);

    const {
      recordNo, title, documentTypeId, folderId, departmentId,
      memberNumber, memberName, classification, retentionClassId,
      storageProviderId, storagePrefix, allowDuplicate,
    } = req.body;

    if (storageProviderId && !storageService.providers[storageProviderId]) {
      return fail(res, `"${storageProviderId}" is not a known storage provider`, 400);
    }

    let customFields = [];
    if (req.body.customFields) {
      try {
        customFields = JSON.parse(req.body.customFields);
        if (!Array.isArray(customFields)) throw new Error('not an array');
      } catch {
        return fail(res, 'customFields must be a JSON array of {label, value}', 400);
      }
    }

    try {
      const result = await registerDocument({
        buffer: req.file.buffer, originalName: req.file.originalname, mimeType: req.file.mimetype,
        recordNo, title, documentTypeId, folderId, departmentId,
        memberNumber, memberName, classification, retentionClassId,
        storageProviderId, storagePrefix, customFields,
        userId: req.user.id, ip: req.ip,
        allowDuplicate: allowDuplicate === true || allowDuplicate === 'true',
      });

      // Auto-route into a matching workflow, if one's configured — never
      // let a routing failure undo a registration that already succeeded.
      autoTriggerWorkflow({
        documentId: result.id, documentTypeId: Number(documentTypeId), folderId: Number(folderId), ip: req.ip,
      }).catch((err) => logger.error('Auto-trigger workflow failed', { error: err.message, documentId: result.id }));

      return ok(res, result, 'Record registered', 201);
    } catch (err) {
      if (err instanceof DuplicateRecordNoError) return fail(res, err.message, 409);
      if (err instanceof DuplicateContentError) return fail(res, err.message, 409, { existingDocument: err.existing });
      throw err;
    }
  })
);

/**
 * POST /api/documents/ocr-preview
 * Stateless — multipart `file` only, no metadata required. Runs the same
 * extraction service used at registration time but writes NOTHING to the
 * database or storage. Used by Smart Upload to populate a review table
 * with suggested fields before the user commits (and calls POST / per
 * file, separately, with the fields they've reviewed/edited).
 */
router.post('/ocr-preview', requireModuleAccess('capture', true), upload.single('file'), asyncHandler(async (req, res) => {
  if (!req.file) return fail(res, 'A file is required', 400);

  const ocrResult = await ocrService.extractText(req.file.buffer, req.file.mimetype, req.file.originalname);
  const suggestedCode = suggestDocumentTypeCode(ocrResult.text);
  let suggestedDocumentTypeId = null;
  if (suggestedCode) {
    const [[type]] = await pool.query('SELECT id FROM document_types WHERE code = ?', [suggestedCode]);
    suggestedDocumentTypeId = type ? type.id : null;
  }
  const duplicateOf = await findDuplicateByContentHash(sha256(req.file.buffer));

  return ok(res, {
    text: ocrResult.text,
    confidence: ocrResult.confidence,
    duplicateOf,
    suggestedDocumentTypeId,
    suggestedMemberNumber: suggestMemberNumber(ocrResult.text),
  });
}));

/**
 * GET /api/documents/:id/content
 * Streams the decrypted current version back to the browser. Nothing
 * unencrypted ever touches disk — ciphertext is fetched from cloud
 * storage, decrypted in memory, checksum-verified, then written to the
 * response.
 */
router.get('/:id/content', requireModuleAccess('viewer'), asyncHandler(async (req, res) => {
  const [rows] = await pool.query(
    `SELECT dv.id AS version_id, dv.file_name, dv.mime_type, dso.*,
            dek.wrapped_dek, dek.dek_iv, dek.dek_auth_tag, dek.file_iv, dek.file_auth_tag,
            d.classification, d.status
     FROM documents d
     JOIN document_versions dv ON dv.id = d.current_version_id
     JOIN document_storage_objects dso ON dso.id = dv.storage_object_id
     JOIN document_encryption_keys dek ON dek.document_version_id = dv.id
     WHERE d.id = ?`,
    [req.params.id]
  );
  const row = rows[0];
  if (!row) return fail(res, 'Record or content not found', 404);

  const reasonRequired = await getSettingBool('confidential_reason_required', true);
  if (row.classification === 'confidential' && reasonRequired && !req.query.reason) {
    return fail(res, 'Confidential records require a stated reason to open (pass ?reason=...)', 400);
  }

  const encryptedFile = await storageService.downloadEncrypted(row);
  let plaintext = envelopeDecryptFile({
    encryptedFile,
    fileIv: row.file_iv,
    fileAuthTag: row.file_auth_tag,
    wrappedDek: row.wrapped_dek,
    dekIv: row.dek_iv,
    dekAuthTag: row.dek_auth_tag,
  });

  const crypto = require('crypto');
  const actualChecksum = crypto.createHash('sha256').update(plaintext).digest('hex');
  if (actualChecksum !== row.checksum_sha256) {
    return fail(res, 'Integrity check failed — decrypted content does not match the stored checksum', 500);
  }

  if (row.mime_type === 'application/pdf' && await getSettingBool('watermark_downloads', true)) {
    plaintext = await watermarkPdf(plaintext, { userLabel: `${req.user.fullName || req.user.email} (${req.user.id})` });
  }

  await logAudit({
    userId: req.user.id, action: 'Download', recordType: 'document', recordId: req.params.id,
    detail: row.classification === 'confidential' && req.query.reason ? `Reason: ${req.query.reason}` : null, ip: req.ip,
  });

  res.setHeader('Content-Type', row.mime_type);
  res.setHeader('Content-Disposition', `inline; filename="${row.file_name}"`);
  return res.send(plaintext);
}));

/**
 * GET /api/documents/:id/ocr-text
 * Separate from the metadata endpoint since ocr_text is MEDIUMTEXT and
 * the viewer only needs it when the "Extracted text" panel is opened.
 */
router.get('/:id/ocr-text', requireModuleAccess('viewer'), asyncHandler(async (req, res) => {
  const [[row]] = await pool.query(
    `SELECT dv.ocr_text, dv.version_no
     FROM documents d JOIN document_versions dv ON dv.id = d.current_version_id
     WHERE d.id = ?`,
    [req.params.id]
  );
  if (!row) return fail(res, 'Record not found', 404);

  let text = row.ocr_text;
  if (await getSettingBool('redact_bank_numbers', true)) {
    text = redactBankNumbers(text, { role: req.user.role });
  }
  return ok(res, { text, versionNo: row.version_no });
}));

/** PUT /api/documents/:id — edit metadata (title/type/folder/department/member fields/classification). Does not touch file content or versions. */
router.put(
  '/:id',
  requireModuleAccess('repository', true),
  [body('title').optional().trim().notEmpty()],
  asyncHandler(async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) return fail(res, 'Validation failed', 422, errors.array());

    const [[doc]] = await pool.query('SELECT id FROM documents WHERE id = ?', [req.params.id]);
    if (!doc) return fail(res, 'Record not found', 404);

    const { title, documentTypeId, folderId, departmentId, memberNumber, memberName, classification, retentionClassId } = req.body;
    await pool.query(
      `UPDATE documents SET
         title = COALESCE(?, title),
         document_type_id = COALESCE(?, document_type_id),
         folder_id = COALESCE(?, folder_id),
         department_id = COALESCE(?, department_id),
         member_number = COALESCE(?, member_number),
         member_name = COALESCE(?, member_name),
         classification = COALESCE(?, classification),
         retention_class_id = COALESCE(?, retention_class_id)
       WHERE id = ?`,
      [title || null, documentTypeId || null, folderId || null, departmentId || null,
       memberNumber || null, memberName || null, classification || null, retentionClassId || null, req.params.id]
    );
    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'document', recordId: req.params.id, ip: req.ip });
    return ok(res, null, 'Record updated');
  })
);

/** DELETE /api/documents/:id — archives (records-integrity: never hard-deletes a registered document). */
router.delete('/:id', requireModuleAccess('repository', true), asyncHandler(async (req, res) => {
  const [[doc]] = await pool.query('SELECT id, record_no, status FROM documents WHERE id = ?', [req.params.id]);
  if (!doc) return fail(res, 'Record not found', 404);
  if (doc.status === 'disposed') return fail(res, 'Record is already disposed', 409);

  await pool.query('UPDATE documents SET status = "archived" WHERE id = ?', [req.params.id]);
  await logAudit({ userId: req.user.id, action: 'Delete', recordType: 'document', recordId: req.params.id, detail: `${doc.record_no} archived`, ip: req.ip });
  return ok(res, null, 'Record archived');
}));

/** POST /api/documents/:id/declare-final — starts the retention clock. */
router.post('/:id/declare-final', requireModuleAccess('repository', true), asyncHandler(async (req, res) => {
  const [[doc]] = await pool.query(
    `SELECT d.*, rc.retention_years FROM documents d LEFT JOIN retention_classes rc ON rc.id = d.retention_class_id WHERE d.id = ?`,
    [req.params.id]
  );
  if (!doc) return fail(res, 'Record not found', 404);

  const dueAt = doc.retention_years
    ? `DATE_ADD(NOW(), INTERVAL ${Number(doc.retention_years)} YEAR)`
    : 'NULL';

  await pool.query(
    `UPDATE documents SET status = 'declared_final', retention_start_at = NOW(), retention_due_at = ${dueAt} WHERE id = ?`,
    [req.params.id]
  );
  await logAudit({ userId: req.user.id, action: 'Declare record', recordType: 'document', recordId: req.params.id, ip: req.ip });
  return ok(res, null, 'Record declared final — retention clock started');
}));

module.exports = router;
