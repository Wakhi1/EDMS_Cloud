/**
 * services/document.service.js
 * The single document-registration pipeline (encrypt -> upload -> insert ->
 * OCR -> index) — extracted from documents.routes.js's POST / handler so
 * both the interactive upload route and the Capture & Scan batch processor
 * (services/capture/batch.service.js) call the exact same code. Neither
 * path may skip encryption, OCR, or indexing.
 */
const { pool } = require('../config/db');
const { logAudit } = require('./audit.service');
const { envelopeEncryptFile, sha256 } = require('./crypto.service');
const storageService = require('./storage/storage.service');
const ocrService = require('./ocr.service');

class DuplicateRecordNoError extends Error {
  constructor(recordNo) {
    super(`A record with this number already exists: ${recordNo}`);
    this.code = 'DUPLICATE_RECORD_NO';
  }
}

class DuplicateContentError extends Error {
  constructor(existing) {
    super(`This file's content matches an existing record: ${existing.recordNo} (${existing.title})`);
    this.code = 'DUPLICATE_CONTENT';
    this.existing = existing;
  }
}

/**
 * Looks up a live (non-disposed) document whose CURRENT version has the
 * same plaintext content hash. Shared by registerDocument's own duplicate
 * gate and documents.routes.js's read-only /ocr-preview duplicate warning.
 */
async function findDuplicateByContentHash(contentHash, queryable = pool) {
  const [rows] = await queryable.query(
    `SELECT d.id, d.record_no AS recordNo, d.title FROM document_storage_objects dso
     JOIN document_versions dv ON dv.storage_object_id = dso.id AND dv.is_current = 1
     JOIN documents d ON d.id = dv.document_id AND d.status != 'disposed'
     WHERE dso.checksum_sha256 = ? LIMIT 1`,
    [contentHash]
  );
  return rows[0] || null;
}

/**
 * @param {object} params
 * @param {Buffer} params.buffer - plaintext file bytes
 * @param {string} params.originalName
 * @param {string} params.mimeType
 * @param {string} params.recordNo
 * @param {string} params.title
 * @param {number} params.documentTypeId
 * @param {number} params.folderId
 * @param {number} [params.departmentId]
 * @param {string} [params.memberNumber]
 * @param {string} [params.memberName]
 * @param {string} [params.classification]
 * @param {number} [params.retentionClassId]
 * @param {string} [params.storageProviderId] - explicit provider override, else the global active one
 * @param {string} [params.storagePrefix] - folder prefix within the chosen provider
 * @param {Array<{label: string, value: string}>} [params.customFields]
 * @param {number} params.userId - owner/creator/audit actor
 * @param {string} [params.ip]
 * @param {boolean} [params.allowDuplicate] - bypass the content-hash duplicate gate (an interactive caller may choose to proceed after being warned)
 * @returns {Promise<{id: number, recordNo: string, versionId: number}>}
 */
async function registerDocument({
  buffer, originalName, mimeType,
  recordNo, title, documentTypeId, folderId, departmentId,
  memberNumber, memberName, classification, retentionClassId,
  storageProviderId, storagePrefix, customFields = [],
  userId, ip, allowDuplicate = false,
}) {
  if (storageProviderId && !storageService.providers[storageProviderId]) {
    throw new Error(`"${storageProviderId}" is not a known storage provider`);
  }

  // Content-hash duplicate check up front, before OCR/encryption/upload —
  // cheap short-circuit so a rejected duplicate never does the expensive work.
  const contentHash = sha256(buffer);
  if (!allowDuplicate) {
    const existing = await findDuplicateByContentHash(contentHash);
    if (existing) throw new DuplicateContentError(existing);
  }

  // Extract searchable text before opening a DB transaction/connection —
  // pure CPU work on the plaintext buffer, no need to hold a pooled
  // connection while it runs. Never blocks registration: resolves to
  // { text: null, confidence: null } on any extraction failure.
  const ocrResult = await ocrService.extractText(buffer, mimeType, originalName);

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    const [dupe] = await conn.query('SELECT id FROM documents WHERE record_no = ?', [recordNo]);
    if (dupe.length) throw new DuplicateRecordNoError(recordNo); // caught below, single rollback

    // 1) Encrypt the file bytes with a fresh per-version DEK, wrapped by the active KEK.
    const enc = envelopeEncryptFile(buffer);

    // 2) Upload ciphertext to the chosen (or, if omitted, the globally
    // active) cloud provider, under the chosen storage prefix if any.
    const prefix = storagePrefix ? `${String(storagePrefix).replace(/^\/+|\/+$/g, '')}/` : '';
    const objectKey = `${prefix}documents/${recordNo}/v1/${Date.now()}-${originalName}.enc`;
    const uploadResult = await storageService.uploadEncrypted(objectKey, enc.encryptedFile, mimeType, storageProviderId || undefined);

    const [storageRow] = await conn.query(
      `INSERT INTO document_storage_objects
         (provider, bucket_or_container, object_key, region, content_type, size_bytes, is_encrypted, checksum_sha256)
       VALUES (?, ?, ?, ?, ?, ?, 1, ?)`,
      [uploadResult.provider, uploadResult.bucket, uploadResult.objectKey, uploadResult.region,
       mimeType, buffer.length, enc.checksumSha256]
    );

    const [doc] = await conn.query(
      `INSERT INTO documents
         (record_no, title, document_type_id, folder_id, department_id, member_number, member_name,
          classification, retention_class_id, owner_id, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [recordNo, title, documentTypeId, folderId, departmentId || null, memberNumber || null, memberName || null,
       classification || 'internal', retentionClassId || null, userId, userId]
    );

    const [version] = await conn.query(
      `INSERT INTO document_versions
         (document_id, version_no, file_name, mime_type, size_bytes, storage_object_id, ocr_text, is_current, created_by)
       VALUES (?, 1, ?, ?, ?, ?, ?, 1, ?)`,
      [doc.insertId, originalName, mimeType, buffer.length, storageRow.insertId, ocrResult.text, userId]
    );

    const [kek] = await conn.query('SELECT id FROM key_encryption_keys WHERE is_active = 1 LIMIT 1');
    if (!kek[0]) throw new Error('No active key_encryption_keys row — run the seed data / rotate a KEK first');

    await conn.query(
      `INSERT INTO document_encryption_keys
         (document_version_id, key_encryption_key_id, algorithm, wrapped_dek, dek_iv, dek_auth_tag, file_iv, file_auth_tag)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
      [version.insertId, kek[0].id, 'aes-256-gcm', enc.wrappedDek, enc.dekIv, enc.dekAuthTag, enc.fileIv, enc.fileAuthTag]
    );

    await conn.query('UPDATE documents SET current_version_id = ? WHERE id = ?', [version.insertId, doc.insertId]);

    const cleanCustomFields = (customFields || [])
      .map((f) => ({ label: String(f.label || '').trim(), value: String(f.value || '').trim() }))
      .filter((f) => f.label && f.value);
    if (cleanCustomFields.length) {
      await conn.query(
        `INSERT INTO document_custom_fields (document_id, field_label, field_value) VALUES ?`,
        [cleanCustomFields.map((f) => [doc.insertId, f.label, f.value])]
      );
    }

    await conn.commit();

    await logAudit({
      userId, action: 'Capture', recordType: 'document', recordId: doc.insertId,
      detail: `${recordNo} registered (${uploadResult.provider})`, ip,
    });

    return { id: doc.insertId, recordNo, versionId: version.insertId };
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }
}

module.exports = { registerDocument, DuplicateRecordNoError, DuplicateContentError, findDuplicateByContentHash };
