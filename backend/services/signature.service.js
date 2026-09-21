/**
 * services/signature.service.js
 * One saved signature per user (Settings -> My Signature), encrypted with
 * the same envelope scheme as documents (services/crypto.service.js) but
 * stored directly as a DB blob (user_signatures.encrypted_image) rather
 * than uploaded to cloud storage — deliberate, this is a small (<1MB)
 * image, not a full document.
 *
 * snapshotSignatureForApproval copies a user's CURRENT signature ciphertext
 * into an immutable workflow_approval_signatures row at the moment a
 * signature-required step is approved (backend/routes/approvals.routes.js)
 * — never a live reference, so a later signature replacement can't
 * retroactively change what a past approval appears to have been signed
 * with. See database/pspf_edms_schema.sql's comment on that table for the
 * full reasoning.
 */
const { pool } = require('../config/db');
const { envelopeEncryptFile, envelopeDecryptFile } = require('./crypto.service');

async function getActiveKek(conn = pool) {
  const [rows] = await conn.query('SELECT id FROM key_encryption_keys WHERE is_active = 1 LIMIT 1');
  if (!rows[0]) throw new Error('No active key_encryption_keys row — run the seed data / rotate a KEK first');
  return rows[0].id;
}

async function getSignatureMeta(userId) {
  const [[row]] = await pool.query(
    'SELECT updated_at FROM user_signatures WHERE user_id = ?',
    [userId]
  );
  return { hasSignature: !!row, updatedAt: row ? row.updated_at : null };
}

async function getSignatureImage(userId) {
  const [[row]] = await pool.query(
    `SELECT encrypted_image, wrapped_dek, dek_iv, dek_auth_tag, file_iv, file_auth_tag, content_type
     FROM user_signatures WHERE user_id = ?`,
    [userId]
  );
  if (!row) return null;
  const buffer = envelopeDecryptFile({
    encryptedFile: row.encrypted_image,
    fileIv: row.file_iv,
    fileAuthTag: row.file_auth_tag,
    wrappedDek: row.wrapped_dek,
    dekIv: row.dek_iv,
    dekAuthTag: row.dek_auth_tag,
  });
  return { buffer, contentType: row.content_type };
}

async function upsertSignature(userId, companyId, buffer, contentType) {
  const enc = envelopeEncryptFile(buffer);
  const kekId = await getActiveKek();

  await pool.query(
    `INSERT INTO user_signatures
       (user_id, company_id, encrypted_image, key_encryption_key_id, wrapped_dek, dek_iv, dek_auth_tag, file_iv, file_auth_tag, checksum_sha256, content_type)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE
       encrypted_image = VALUES(encrypted_image), key_encryption_key_id = VALUES(key_encryption_key_id),
       wrapped_dek = VALUES(wrapped_dek), dek_iv = VALUES(dek_iv), dek_auth_tag = VALUES(dek_auth_tag),
       file_iv = VALUES(file_iv), file_auth_tag = VALUES(file_auth_tag),
       checksum_sha256 = VALUES(checksum_sha256), content_type = VALUES(content_type)`,
    [userId, companyId, enc.encryptedFile, kekId, enc.wrappedDek, enc.dekIv, enc.dekAuthTag, enc.fileIv, enc.fileAuthTag, enc.checksumSha256, contentType]
  );
}

async function deleteSignature(userId) {
  await pool.query('DELETE FROM user_signatures WHERE user_id = ?', [userId]);
}

async function hasSignature(userId) {
  const [[row]] = await pool.query('SELECT 1 FROM user_signatures WHERE user_id = ?', [userId]);
  return !!row;
}

/**
 * Called inside the same transaction as the approval decision
 * (approvals.routes.js). Returns the decrypted signature bytes so a caller
 * that also wants to physically stamp the signature onto the document
 * (see document.service.js's embedSignatureIntoDocument) can reuse exactly
 * what was just snapshotted, without a second round trip or a risk of it
 * racing a concurrent signature replacement.
 */
async function snapshotSignatureForApproval(conn, approvalId, companyId, userId) {
  const [[sig]] = await conn.query(
    `SELECT encrypted_image, key_encryption_key_id, wrapped_dek, dek_iv, dek_auth_tag, file_iv, file_auth_tag, content_type
     FROM user_signatures WHERE user_id = ? FOR UPDATE`,
    [userId]
  );
  if (!sig) throw new Error(`snapshotSignatureForApproval: user ${userId} has no saved signature`);

  await conn.query(
    `INSERT INTO workflow_approval_signatures
       (company_id, approval_id, encrypted_image, key_encryption_key_id, wrapped_dek, dek_iv, dek_auth_tag, file_iv, file_auth_tag)
     VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
    [companyId, approvalId, sig.encrypted_image, sig.key_encryption_key_id, sig.wrapped_dek, sig.dek_iv, sig.dek_auth_tag, sig.file_iv, sig.file_auth_tag]
  );

  const buffer = envelopeDecryptFile({
    encryptedFile: sig.encrypted_image,
    fileIv: sig.file_iv,
    fileAuthTag: sig.file_auth_tag,
    wrappedDek: sig.wrapped_dek,
    dekIv: sig.dek_iv,
    dekAuthTag: sig.dek_auth_tag,
  });
  return { buffer, contentType: sig.content_type };
}

module.exports = {
  getSignatureMeta,
  getSignatureImage,
  upsertSignature,
  deleteSignature,
  hasSignature,
  snapshotSignatureForApproval,
};
