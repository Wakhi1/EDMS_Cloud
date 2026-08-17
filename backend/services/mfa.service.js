/**
 * services/mfa.service.js
 * TOTP enrolment/verification (authenticator apps), SMS one-time codes,
 * and backup codes. FIDO2/WebAuthn has DB support (user_mfa_methods) and
 * a stub verify function ready to wire up to @simplewebauthn/server.
 */
const crypto = require('crypto');
const speakeasy = require('speakeasy');
const qrcode = require('qrcode');
const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');

function generateTotpSecret(userEmail) {
  return speakeasy.generateSecret({ name: `PSPF EDMS (${userEmail})`, length: 20 });
}

async function generateTotpQrDataUrl(otpauthUrl) {
  return qrcode.toDataURL(otpauthUrl);
}

function verifyTotpToken(base32Secret, token) {
  return speakeasy.totp.verify({ secret: base32Secret, encoding: 'base32', token, window: 1 });
}

function generateNumericCode(length = 6) {
  const max = 10 ** length;
  return String(crypto.randomInt(0, max)).padStart(length, '0');
}

function hashCode(code) {
  return crypto.createHash('sha256').update(code).digest('hex');
}

async function generateBackupCodes(count = 8) {
  const codes = Array.from({ length: count }, () => crypto.randomBytes(5).toString('hex'));
  const hashed = await Promise.all(codes.map((c) => bcrypt.hash(c, 10)));
  return { plaintextCodes: codes, hashedCodes: hashed };
}

async function consumeBackupCode(userId, code) {
  const [rows] = await pool.query(
    `SELECT id, backup_codes_hash_json FROM user_mfa_methods WHERE user_id = ? AND method_type = 'backup_codes' LIMIT 1`,
    [userId]
  );
  if (!rows[0]) return false;
  const hashes = JSON.parse(rows[0].backup_codes_hash_json || '[]');
  for (let i = 0; i < hashes.length; i += 1) {
    // eslint-disable-next-line no-await-in-loop
    if (await bcrypt.compare(code, hashes[i])) {
      hashes.splice(i, 1);
      await pool.query(
        `UPDATE user_mfa_methods SET backup_codes_hash_json = ? WHERE id = ?`,
        [JSON.stringify(hashes), rows[0].id]
      );
      return true;
    }
  }
  return false;
}

/**
 * Placeholder for FIDO2/WebAuthn security key verification (e.g. YubiKey,
 * required for Approving Managers per the security module). Wire this up
 * to @simplewebauthn/server's verifyAuthenticationResponse() and the
 * stored webauthn_credential_id / webauthn_public_key columns.
 */
async function verifyWebAuthnAssertion(/* userId, assertionResponse */) {
  throw new Error('WebAuthn verification not yet implemented — integrate @simplewebauthn/server here.');
}

module.exports = {
  generateTotpSecret, generateTotpQrDataUrl, verifyTotpToken,
  generateNumericCode, hashCode,
  generateBackupCodes, consumeBackupCode,
  verifyWebAuthnAssertion,
};
