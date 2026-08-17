/**
 * services/crypto.service.js
 * Envelope encryption for documents.
 *
 *   1. A fresh random Data Encryption Key (DEK) is generated per document
 *      version and used to AES-256-GCM encrypt the file bytes.
 *   2. The DEK itself is encrypted ("wrapped") with the active Key
 *      Encryption Key (KEK) before being stored in
 *      document_encryption_keys. The KEK material lives only in
 *      process.env (or a cloud KMS in production) — never in the DB.
 *   3. To read a document back, the wrapped DEK is unwrapped with the
 *      KEK, then used to decrypt the object fetched from cloud storage.
 *
 * Swap getKek() for an AWS KMS / Azure Key Vault / GCP KMS call in
 * production without touching any calling code.
 */
const crypto = require('crypto');

const ALGO = 'aes-256-gcm';

function getKek() {
  const b64 = process.env.MASTER_KEK_BASE64;
  if (!b64 || b64 === 'REPLACE_WITH_32_BYTE_BASE64_KEY') {
    throw new Error('MASTER_KEK_BASE64 is not configured. Generate one and set it in .env');
  }
  const key = Buffer.from(b64, 'base64');
  if (key.length !== 32) throw new Error('MASTER_KEK_BASE64 must decode to exactly 32 bytes');
  return key;
}

function encryptBuffer(plainBuffer, key) {
  const iv = crypto.randomBytes(12);
  const cipher = crypto.createCipheriv(ALGO, key, iv);
  const encrypted = Buffer.concat([cipher.update(plainBuffer), cipher.final()]);
  const authTag = cipher.getAuthTag();
  return { encrypted, iv, authTag };
}

function decryptBuffer(encryptedBuffer, key, iv, authTag) {
  const decipher = crypto.createDecipheriv(ALGO, key, iv);
  decipher.setAuthTag(authTag);
  return Buffer.concat([decipher.update(encryptedBuffer), decipher.final()]);
}

/**
 * Encrypts a plaintext file buffer for storage. Returns everything needed
 * to (a) upload the ciphertext to cloud storage and (b) persist the
 * wrapped key material in document_encryption_keys.
 */
function envelopeEncryptFile(plainBuffer) {
  const dek = crypto.randomBytes(32);
  const { encrypted: encryptedFile, iv: fileIv, authTag: fileAuthTag } = encryptBuffer(plainBuffer, dek);

  const kek = getKek();
  const { encrypted: wrappedDek, iv: dekIv, authTag: dekAuthTag } = encryptBuffer(dek, kek);

  const checksumSha256 = crypto.createHash('sha256').update(plainBuffer).digest('hex');

  return {
    encryptedFile, fileIv, fileAuthTag,
    wrappedDek, dekIv, dekAuthTag,
    checksumSha256,
    algorithm: ALGO,
  };
}

/** Reverses envelopeEncryptFile using key rows read back from the database. */
function envelopeDecryptFile({ encryptedFile, fileIv, fileAuthTag, wrappedDek, dekIv, dekAuthTag }) {
  const kek = getKek();
  const dek = decryptBuffer(wrappedDek, kek, dekIv, dekAuthTag);
  const plainBuffer = decryptBuffer(encryptedFile, dek, fileIv, fileAuthTag);
  return plainBuffer;
}

function sha256(buffer) {
  return crypto.createHash('sha256').update(buffer).digest('hex');
}

module.exports = { envelopeEncryptFile, envelopeDecryptFile, sha256 };
