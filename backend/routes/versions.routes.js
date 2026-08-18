/**
 * routes/versions.routes.js
 * Version history: list, upload a new version (encrypted like v1),
 * compare metadata, and restore (never overwrites — writes a new
 * current version, matching the prototype's "nothing overwritten" rule).
 */
const express = require('express');
const { pool } = require('../config/db');
const { ok, fail } = require('../utils/apiResponse');
const asyncHandler = require('../utils/asyncHandler');
const { authenticate } = require('../middleware/auth.middleware');
const { requireModuleAccess } = require('../middleware/rbac.middleware');
const upload = require('../middleware/upload.middleware');
const { logAudit } = require('../services/audit.service');
const aclService = require('../services/acl.service');
const { envelopeEncryptFile } = require('../services/crypto.service');
const storageService = require('../services/storage/storage.service');
const ocrService = require('../services/ocr.service');

const router = express.Router();
router.use(authenticate);

/** GET /api/versions/document/:documentId */
router.get('/document/:documentId', requireModuleAccess('versions'), asyncHandler(async (req, res) => {
  if (!await aclService.hasAccess(req.user.id, req.user.role, 'document', req.params.documentId, 'view')) {
    return fail(res, 'You do not have access to this record', 403);
  }
  const [rows] = await pool.query(
    `SELECT dv.id, dv.version_no, dv.file_name, dv.size_bytes, dv.is_current, dv.created_at, u.full_name AS created_by
     FROM document_versions dv JOIN users u ON u.id = dv.created_by
     WHERE dv.document_id = ? ORDER BY dv.version_no DESC`,
    [req.params.documentId]
  );
  return ok(res, rows);
}));

/** POST /api/versions/document/:documentId — upload a new version. */
router.post('/document/:documentId', requireModuleAccess('versions', true), upload.single('file'), asyncHandler(async (req, res) => {
  const documentId = req.params.documentId;
  if (!req.file) return fail(res, 'A file is required', 400);
  if (!await aclService.hasAccess(req.user.id, req.user.role, 'document', documentId, 'edit')) {
    return fail(res, 'You do not have access to this record', 403);
  }

  const ocrResult = await ocrService.extractText(req.file.buffer, req.file.mimetype, req.file.originalname);

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [[doc]] = await conn.query('SELECT record_no FROM documents WHERE id = ? FOR UPDATE', [documentId]);
    if (!doc) { await conn.rollback(); return fail(res, 'Record not found', 404); }

    const [[maxVer]] = await conn.query('SELECT COALESCE(MAX(version_no), 0) AS maxVer FROM document_versions WHERE document_id = ?', [documentId]);
    const nextVersion = Number(maxVer.maxVer) + 1;

    const enc = envelopeEncryptFile(req.file.buffer);
    const objectKey = `documents/${doc.record_no}/v${nextVersion}/${Date.now()}-${req.file.originalname}.enc`;
    const uploadResult = await storageService.uploadEncrypted(objectKey, enc.encryptedFile, req.file.mimetype);

    const [storageRow] = await conn.query(
      `INSERT INTO document_storage_objects
         (provider, bucket_or_container, object_key, region, content_type, size_bytes, is_encrypted, checksum_sha256)
       VALUES (?, ?, ?, ?, ?, ?, 1, ?)`,
      [uploadResult.provider, uploadResult.bucket, uploadResult.objectKey, uploadResult.region,
       req.file.mimetype, req.file.size, enc.checksumSha256]
    );

    await conn.query('UPDATE document_versions SET is_current = 0 WHERE document_id = ?', [documentId]);

    const [version] = await conn.query(
      `INSERT INTO document_versions
         (document_id, version_no, file_name, mime_type, size_bytes, storage_object_id, ocr_text, is_current, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)`,
      [documentId, nextVersion, req.file.originalname, req.file.mimetype, req.file.size, storageRow.insertId, ocrResult.text, req.user.id]
    );

    const [kek] = await conn.query('SELECT id FROM key_encryption_keys WHERE is_active = 1 LIMIT 1');
    await conn.query(
      `INSERT INTO document_encryption_keys
         (document_version_id, key_encryption_key_id, algorithm, wrapped_dek, dek_iv, dek_auth_tag, file_iv, file_auth_tag)
       VALUES (?, ?, 'aes-256-gcm', ?, ?, ?, ?, ?)`,
      [version.insertId, kek[0].id, enc.wrappedDek, enc.dekIv, enc.dekAuthTag, enc.fileIv, enc.fileAuthTag]
    );

    await conn.query('UPDATE documents SET current_version_id = ? WHERE id = ?', [version.insertId, documentId]);
    await conn.commit();

    await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'document', recordId: documentId, detail: `New version v${nextVersion}`, ip: req.ip });
    return ok(res, { versionId: version.insertId, versionNo: nextVersion }, 'New version uploaded', 201);
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}));

/** POST /api/versions/:versionId/restore — promotes an older version to current (writes, never overwrites). */
router.post('/:versionId/restore', requireModuleAccess('versions', true), asyncHandler(async (req, res) => {
  const [[version]] = await pool.query('SELECT * FROM document_versions WHERE id = ?', [req.params.versionId]);
  if (!version) return fail(res, 'Version not found', 404);
  if (!await aclService.hasAccess(req.user.id, req.user.role, 'document', version.document_id, 'edit')) {
    return fail(res, 'You do not have access to this record', 403);
  }

  await pool.query('UPDATE document_versions SET is_current = 0 WHERE document_id = ?', [version.document_id]);
  await pool.query('UPDATE document_versions SET is_current = 1 WHERE id = ?', [version.id]);
  await pool.query('UPDATE documents SET current_version_id = ? WHERE id = ?', [version.id, version.document_id]);

  await logAudit({ userId: req.user.id, action: 'Edit', recordType: 'document', recordId: version.document_id, detail: `Restored v${version.version_no} as current`, ip: req.ip });
  return ok(res, null, `Version ${version.version_no} promoted to current`);
}));

module.exports = router;
