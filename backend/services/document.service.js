/**
 * services/document.service.js
 * The single document-registration pipeline (encrypt -> upload -> insert ->
 * OCR -> index) — extracted from documents.routes.js's POST / handler so
 * both the interactive upload route and the Capture & Scan batch processor
 * (services/capture/batch.service.js) call the exact same code. Neither
 * path may skip encryption, OCR, or indexing.
 */
const { pool } = require('../config/db');
const logger = require('../config/logger');
const { logAudit } = require('./audit.service');
const { envelopeEncryptFile, envelopeDecryptFile, sha256 } = require('./crypto.service');
const storageService = require('./storage/storage.service');
const ocrService = require('./ocr.service');
const { countPages } = require('./pageCount.service');
const { stampSignatureOntoPdf } = require('./pdfStamp.service');

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
  // A caller-supplied override always wins; otherwise fall back to the
  // target folder's own default storage location (folders.routes.js's
  // storageProviderId/storagePrefix), and only then to storageService's
  // globally active provider (its own default when storageProviderId is
  // undefined) — so filing into a folder someone deliberately pointed at,
  // say, an "archive" bucket keeps landing there without every upload
  // caller (manual, capture batch, agent) needing to know about it.
  if (!storageProviderId && folderId) {
    const [[folder]] = await pool.query('SELECT storage_provider_id, storage_prefix FROM folders WHERE id = ?', [folderId]);
    if (folder && folder.storage_provider_id) {
      storageProviderId = folder.storage_provider_id;
      if (!storagePrefix) storagePrefix = folder.storage_prefix;
    }
  }
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
  const pages = await countPages(buffer, mimeType, originalName);

  // Derived from the acting user rather than threaded through every caller
  // (documents.routes.js, capture/batch.service.js, import.service.js) —
  // userId is always present and already the source of truth for
  // owner_id/created_by below.
  const [[actingUser]] = await pool.query('SELECT company_id FROM users WHERE id = ?', [userId]);
  if (!actingUser) throw new Error(`registerDocument: userId ${userId} does not resolve to a user`);
  const companyId = actingUser.company_id;

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
         (company_id, provider, bucket_or_container, object_key, region, content_type, size_bytes, is_encrypted, checksum_sha256)
       VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)`,
      [companyId, uploadResult.provider, uploadResult.bucket, uploadResult.objectKey, uploadResult.region,
       mimeType, buffer.length, enc.checksumSha256]
    );

    const [doc] = await conn.query(
      `INSERT INTO documents
         (company_id, record_no, title, document_type_id, folder_id, department_id, member_number, member_name,
          classification, retention_class_id, owner_id, created_by)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [companyId, recordNo, title, documentTypeId, folderId, departmentId || null, memberNumber || null, memberName || null,
       classification || 'internal', retentionClassId || null, userId, userId]
    );

    const [version] = await conn.query(
      `INSERT INTO document_versions
         (company_id, document_id, version_no, file_name, mime_type, size_bytes, page_count, page_count_estimated, storage_object_id, ocr_text, is_current, created_by)
       VALUES (?, ?, 1, ?, ?, ?, ?, ?, ?, ?, 1, ?)`,
      [companyId, doc.insertId, originalName, mimeType, buffer.length, pages.count, pages.estimated ? 1 : 0, storageRow.insertId, ocrResult.text, userId]
    );

    const [kek] = await conn.query('SELECT id FROM key_encryption_keys WHERE is_active = 1 LIMIT 1');
    if (!kek[0]) throw new Error('No active key_encryption_keys row — run the seed data / rotate a KEK first');

    await conn.query(
      `INSERT INTO document_encryption_keys
         (company_id, document_version_id, key_encryption_key_id, algorithm, wrapped_dek, dek_iv, dek_auth_tag, file_iv, file_auth_tag)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [companyId, version.insertId, kek[0].id, 'aes-256-gcm', enc.wrappedDek, enc.dekIv, enc.dekAuthTag, enc.fileIv, enc.fileAuthTag]
    );

    await conn.query('UPDATE documents SET current_version_id = ? WHERE id = ?', [version.insertId, doc.insertId]);

    const cleanCustomFields = (customFields || [])
      .map((f) => ({ label: String(f.label || '').trim(), value: String(f.value || '').trim() }))
      .filter((f) => f.label && f.value);
    if (cleanCustomFields.length) {
      await conn.query(
        `INSERT INTO document_custom_fields (company_id, document_id, field_label, field_value) VALUES ?`,
        [cleanCustomFields.map((f) => [companyId, doc.insertId, f.label, f.value])]
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

/**
 * Physically relocates a document's current-version file when it's moved
 * into a folder configured for a different storage provider — mirrors
 * registerDocument's own folder-default resolution order (explicit >
 * folder's storage_provider_id > storageService's globally active
 * provider), so a document dropped into a folder no-ops here exactly when
 * a fresh upload into that same folder would have landed on the same
 * provider anyway. No-ops when the resolved destination matches where the
 * file already lives. Only the current version moves; older versions are
 * left where they were uploaded — that's normal version history, not a
 * stray duplicate. Called from documents.routes.js's PUT /:id before the
 * folder_id column itself is updated, so a storage failure aborts the
 * whole move rather than leaving folder_id and physical location disagreeing.
 */
async function relocateDocumentStorage(documentId, targetFolderId, { userId, ip } = {}) {
  const [[current]] = await pool.query(
    `SELECT d.company_id, d.record_no, dv.id AS version_id, dv.version_no, dv.file_name, dv.mime_type,
            dso.id AS storage_object_id, dso.provider, dso.bucket_or_container, dso.object_key,
            dso.content_type, dso.size_bytes, dso.is_encrypted, dso.checksum_sha256
     FROM documents d
     JOIN document_versions dv ON dv.id = d.current_version_id
     JOIN document_storage_objects dso ON dso.id = dv.storage_object_id
     WHERE d.id = ?`,
    [documentId]
  );
  if (!current) return; // not yet registered with a stored file — nothing to relocate

  const [[folder]] = await pool.query('SELECT storage_provider_id, storage_prefix FROM folders WHERE id = ?', [targetFolderId]);
  const { key: targetProvider } = await storageService.activeProvider(folder?.storage_provider_id || undefined);
  if (targetProvider === current.provider) return; // already on the right provider for this folder

  const encryptedBytes = await storageService.downloadEncrypted(current);
  const prefix = folder?.storage_prefix ? `${String(folder.storage_prefix).replace(/^\/+|\/+$/g, '')}/` : '';
  const objectKey = `${prefix}documents/${current.record_no}/v${current.version_no}/${Date.now()}-${current.file_name}.enc`;
  const uploadResult = await storageService.uploadEncrypted(objectKey, encryptedBytes, current.content_type, targetProvider);

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [storageRow] = await conn.query(
      `INSERT INTO document_storage_objects
         (company_id, provider, bucket_or_container, object_key, region, content_type, size_bytes, is_encrypted, checksum_sha256)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [current.company_id, uploadResult.provider, uploadResult.bucket, uploadResult.objectKey, uploadResult.region,
       current.content_type, current.size_bytes, current.is_encrypted, current.checksum_sha256]
    );
    await conn.query('UPDATE document_versions SET storage_object_id = ? WHERE id = ?', [storageRow.insertId, current.version_id]);
    await conn.query('DELETE FROM document_storage_objects WHERE id = ?', [current.storage_object_id]);
    await conn.commit();
  } catch (err) {
    await conn.rollback();
    throw err;
  } finally {
    conn.release();
  }

  // Old physical object is already unreferenced at this point — a failure
  // here is a cleanup miss, not a correctness problem, so log and move on
  // rather than failing the whole move.
  try {
    await storageService.deleteObject(current);
  } catch (err) {
    logger.warn('Failed to delete relocated document from its old storage provider', {
      documentId, oldProvider: current.provider, oldObjectKey: current.object_key, error: err.message,
    });
  }

  await logAudit({
    userId, action: 'Edit', recordType: 'document', recordId: documentId,
    detail: `Relocated storage: ${current.provider} -> ${uploadResult.provider}`, ip,
  });
}

/**
 * Physically stamps an approver's signature onto the document's CURRENT
 * version and writes the result as a new version — distinct from
 * workflow_approval_signatures (an immutable attestation record, never
 * drawn into the file) and from watermark.service.js (text stamped fresh
 * on every download, never persisted). Called from approvals.routes.js's
 * approve handler, inside the same transaction as the approval decision,
 * only when system_settings.embed_approval_signatures is enabled and the
 * approver has a saved signature.
 *
 * No-ops (returns null) for anything that isn't a PDF — signature stamping
 * only makes sense for a page-based document; every other document type
 * still gets the immutable workflow_approval_signatures record, just not a
 * physically stamped copy.
 *
 * Reuses versions.routes.js's exact "write a new version, never overwrite"
 * pattern. Carries forward the current version's page_count too (stamping
 * draws onto existing pages, never adds any) and its ocr_text unchanged rather
 * than re-running OCR — a signature stamp doesn't change the document's
 * searchable content, and re-running (potentially slow) OCR inside an
 * approval transaction would risk holding DB locks far longer than needed.
 */
async function embedSignatureIntoDocument(conn, { documentId, companyId, userId, signatureBuffer, placement }) {
  const [[current]] = await conn.query(
    `SELECT dv.id AS version_id, dv.version_no, dv.file_name, dv.mime_type, dv.ocr_text, dv.page_count, dv.page_count_estimated,
            dso.provider, dso.bucket_or_container, dso.object_key, dso.is_encrypted,
            dek.wrapped_dek, dek.dek_iv, dek.dek_auth_tag, dek.file_iv, dek.file_auth_tag
     FROM documents d
     JOIN document_versions dv ON dv.id = d.current_version_id
     JOIN document_storage_objects dso ON dso.id = dv.storage_object_id
     LEFT JOIN document_encryption_keys dek ON dek.document_version_id = dv.id
     WHERE d.id = ? FOR UPDATE`,
    [documentId]
  );
  if (!current || current.mime_type !== 'application/pdf') return null;

  const fetchedFile = await storageService.downloadEncrypted(current);
  const plaintext = current.is_encrypted
    ? envelopeDecryptFile({
        encryptedFile: fetchedFile,
        fileIv: current.file_iv,
        fileAuthTag: current.file_auth_tag,
        wrappedDek: current.wrapped_dek,
        dekIv: current.dek_iv,
        dekAuthTag: current.dek_auth_tag,
      })
    : fetchedFile;

  const stamped = await stampSignatureOntoPdf(plaintext, signatureBuffer, placement);

  const [[{ maxVer }]] = await conn.query('SELECT MAX(version_no) AS maxVer FROM document_versions WHERE document_id = ?', [documentId]);
  const nextVersion = Number(maxVer) + 1;

  const enc = envelopeEncryptFile(stamped);
  const objectKey = `documents/signed/${documentId}/v${nextVersion}/${Date.now()}-${current.file_name}`;
  const uploadResult = await storageService.uploadEncrypted(objectKey, enc.encryptedFile, current.mime_type);

  const [storageRow] = await conn.query(
    `INSERT INTO document_storage_objects
       (company_id, provider, bucket_or_container, object_key, region, content_type, size_bytes, is_encrypted, checksum_sha256)
     VALUES (?, ?, ?, ?, ?, ?, ?, 1, ?)`,
    [companyId, uploadResult.provider, uploadResult.bucket, uploadResult.objectKey, uploadResult.region,
     current.mime_type, stamped.length, enc.checksumSha256]
  );

  await conn.query('UPDATE document_versions SET is_current = 0 WHERE document_id = ?', [documentId]);

  const [version] = await conn.query(
    `INSERT INTO document_versions
       (company_id, document_id, version_no, file_name, mime_type, size_bytes, page_count, page_count_estimated, storage_object_id, ocr_text, is_current, created_by)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?)`,
    [companyId, documentId, nextVersion, current.file_name, current.mime_type, stamped.length, current.page_count, current.page_count_estimated, storageRow.insertId, current.ocr_text, userId]
  );

  const [kek] = await conn.query('SELECT id FROM key_encryption_keys WHERE is_active = 1 LIMIT 1');
  await conn.query(
    `INSERT INTO document_encryption_keys
       (company_id, document_version_id, key_encryption_key_id, algorithm, wrapped_dek, dek_iv, dek_auth_tag, file_iv, file_auth_tag)
     VALUES (?, ?, ?, 'aes-256-gcm', ?, ?, ?, ?, ?)`,
    [companyId, version.insertId, kek[0].id, enc.wrappedDek, enc.dekIv, enc.dekAuthTag, enc.fileIv, enc.fileAuthTag]
  );

  await conn.query('UPDATE documents SET current_version_id = ? WHERE id = ?', [version.insertId, documentId]);

  return { versionId: version.insertId, versionNo: nextVersion };
}

module.exports = {
  registerDocument, DuplicateRecordNoError, DuplicateContentError, findDuplicateByContentHash,
  relocateDocumentStorage, embedSignatureIntoDocument,
};
