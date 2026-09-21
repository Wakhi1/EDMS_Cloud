/**
 * services/import.service.js
 * Brings content that already exists in a cloud/local storage bucket —
 * never uploaded through this app — into the Repository as real documents.
 *
 * Deliberately parallel to, not a variant of, document.service.js's
 * registerDocument(): imported content is read in place (never
 * downloaded-and-re-uploaded), so document_storage_objects rows here point
 * at the pre-existing object_key and are written with is_encrypted = 0 —
 * there is no document_encryption_keys row, since this app never
 * encrypted the bytes in the first place. GET /:id/content branches on
 * that flag to skip decryption for these rows.
 */
const { pool } = require('../config/db');
const { logAudit } = require('./audit.service');
const { sha256 } = require('./crypto.service');
const storageService = require('./storage/storage.service');
const ocrService = require('./ocr.service');
const { countPages } = require('./pageCount.service');
const { findDuplicateByContentHash } = require('./document.service');
const { claimNextAvailable, releaseIndex, linkIndexToDocument } = require('./recordIndex.service');

function guessMimeType(filename) {
  const ext = (filename.split('.').pop() || '').toLowerCase();
  const map = {
    pdf: 'application/pdf', png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg',
    txt: 'text/plain', csv: 'text/csv', docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  };
  return map[ext] || 'application/octet-stream';
}

/**
 * Imports every file directly under `prefix` (non-recursive — subfolders
 * are left for a separate import call) into `folderId`.
 * @returns {Promise<{imported: Array, skipped: Array}>}
 */
async function importFromStorage({
  providerId, prefix, folderId,
  documentTypeId, classification, departmentId, retentionClassId,
  userId, ip,
}) {
  const provider = storageService.providers[providerId];
  if (!provider) throw new Error(`"${providerId}" is not a known storage provider`);

  const [[docType]] = await pool.query('SELECT id FROM document_types WHERE id = ?', [documentTypeId]);
  if (!docType) throw new Error('Unknown document type');

  const [[actingUser]] = await pool.query('SELECT company_id FROM users WHERE id = ?', [userId]);
  if (!actingUser) throw new Error(`importFromStorage: userId ${userId} does not resolve to a user`);
  const companyId = actingUser.company_id;

  const { files } = await provider.list(prefix);
  const imported = [];
  const skipped = [];

  for (const fileName of files) {
    const objectKey = prefix ? `${prefix.replace(/\/+$/, '')}/${fileName}` : fileName;
    // eslint-disable-next-line no-await-in-loop
    const buffer = await provider.download(objectKey);
    const contentHash = sha256(buffer);
    const mimeType = guessMimeType(fileName);

    // eslint-disable-next-line no-await-in-loop
    const existing = await findDuplicateByContentHash(contentHash);
    if (existing) {
      skipped.push({ fileName, reason: `Matches existing record ${existing.recordNo} (${existing.title})` });
      continue; // eslint-disable-line no-continue
    }

    // eslint-disable-next-line no-await-in-loop
    const ocrResult = await ocrService.extractText(buffer, mimeType, fileName);
    // eslint-disable-next-line no-await-in-loop
    const pages = await countPages(buffer, mimeType, fileName);

    // No human reviews an import run, so claim the oldest available index
    // for this type rather than presenting a picker (same as Capture &
    // Scan's automated paths) — claimed outside conn's transaction below,
    // so a rollback there must explicitly release it too (see catch).
    // eslint-disable-next-line no-await-in-loop
    const claimedIndex = await claimNextAvailable({ documentTypeId, companyId });
    const recordNo = claimedIndex.indexValue;

    // eslint-disable-next-line no-await-in-loop
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      // Reading in place (never uploading/moving the original object), so
      // there's no upload() response to pull the exact bucket/container
      // name from without adding a new no-op provider method — providerId
      // itself is a safe, always-correct label for this informational column.
      const [storageRow] = await conn.query(
        `INSERT INTO document_storage_objects
           (company_id, provider, bucket_or_container, object_key, region, content_type, size_bytes, is_encrypted, checksum_sha256)
         VALUES (?, ?, ?, ?, ?, ?, ?, 0, ?)`,
        [companyId, providerId, providerId, objectKey, null, mimeType, buffer.length, contentHash]
      );

      const [doc] = await conn.query(
        `INSERT INTO documents
           (company_id, record_no, title, document_type_id, folder_id, department_id, classification, retention_class_id, owner_id, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [companyId, recordNo, fileName, documentTypeId, folderId, departmentId || null, classification || 'internal', retentionClassId || null, userId, userId]
      );

      const [version] = await conn.query(
        `INSERT INTO document_versions
           (company_id, document_id, version_no, file_name, mime_type, size_bytes, page_count, page_count_estimated, storage_object_id, ocr_text, is_current, created_by)
         VALUES (?, ?, 1, ?, ?, ?, ?, ?, ?, ?, 1, ?)`,
        [companyId, doc.insertId, fileName, mimeType, buffer.length, pages.count, pages.estimated ? 1 : 0, storageRow.insertId, ocrResult.text, userId]
      );

      await conn.query('UPDATE documents SET current_version_id = ? WHERE id = ?', [version.insertId, doc.insertId]);
      await conn.commit();
      await linkIndexToDocument(claimedIndex.id, doc.insertId);

      await logAudit({
        userId, action: 'Create', recordType: 'document', recordId: doc.insertId,
        detail: `${recordNo} imported from ${providerId}:${objectKey}`, ip,
      });

      imported.push({ id: doc.insertId, recordNo, fileName });
    } catch (err) {
      await conn.rollback();
      await releaseIndex(claimedIndex.id);
      throw err;
    } finally {
      conn.release();
    }
  }

  return { imported, skipped };
}

module.exports = { importFromStorage };
