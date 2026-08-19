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
const { findDuplicateByContentHash } = require('./document.service');

function guessMimeType(filename) {
  const ext = (filename.split('.').pop() || '').toLowerCase();
  const map = {
    pdf: 'application/pdf', png: 'image/png', jpg: 'image/jpeg', jpeg: 'image/jpeg',
    txt: 'text/plain', csv: 'text/csv', docx: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    xlsx: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  };
  return map[ext] || 'application/octet-stream';
}

async function nextRecordNo(conn, typeCode) {
  const year = new Date().getFullYear();
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const suffix = String(Math.floor(Math.random() * 10000)).padStart(4, '0');
    const candidate = `${typeCode}-${year}-${suffix}`;
    const [rows] = await conn.query('SELECT id FROM documents WHERE record_no = ?', [candidate]);
    if (!rows.length) return candidate;
  }
  throw new Error('Could not generate a unique record number after 20 attempts');
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

  const [[docType]] = await pool.query('SELECT code FROM document_types WHERE id = ?', [documentTypeId]);
  if (!docType) throw new Error('Unknown document type');

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
    const conn = await pool.getConnection();
    try {
      await conn.beginTransaction();

      const recordNo = await nextRecordNo(conn, docType.code);

      // Reading in place (never uploading/moving the original object), so
      // there's no upload() response to pull the exact bucket/container
      // name from without adding a new no-op provider method — providerId
      // itself is a safe, always-correct label for this informational column.
      const [storageRow] = await conn.query(
        `INSERT INTO document_storage_objects
           (provider, bucket_or_container, object_key, region, content_type, size_bytes, is_encrypted, checksum_sha256)
         VALUES (?, ?, ?, ?, ?, ?, 0, ?)`,
        [providerId, providerId, objectKey, null, mimeType, buffer.length, contentHash]
      );

      const [doc] = await conn.query(
        `INSERT INTO documents
           (record_no, title, document_type_id, folder_id, department_id, classification, retention_class_id, owner_id, created_by)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [recordNo, fileName, documentTypeId, folderId, departmentId || null, classification || 'internal', retentionClassId || null, userId, userId]
      );

      const [version] = await conn.query(
        `INSERT INTO document_versions
           (document_id, version_no, file_name, mime_type, size_bytes, storage_object_id, ocr_text, is_current, created_by)
         VALUES (?, 1, ?, ?, ?, ?, ?, 1, ?)`,
        [doc.insertId, fileName, mimeType, buffer.length, storageRow.insertId, ocrResult.text, userId]
      );

      await conn.query('UPDATE documents SET current_version_id = ? WHERE id = ?', [version.insertId, doc.insertId]);
      await conn.commit();

      await logAudit({
        userId, action: 'Create', recordType: 'document', recordId: doc.insertId,
        detail: `${recordNo} imported from ${providerId}:${objectKey}`, ip,
      });

      imported.push({ id: doc.insertId, recordNo, fileName });
    } catch (err) {
      await conn.rollback();
      throw err;
    } finally {
      conn.release();
    }
  }

  return { imported, skipped };
}

module.exports = { importFromStorage };
