/**
 * services/apiKey.service.js
 * Generates and validates sandbox API keys. Keys are never stored in
 * plaintext — only a sha256 hash and an 8-char display prefix (enough
 * to tell two keys apart in the admin UI without re-exposing either).
 */
const crypto = require('crypto');

function generateApiKey() {
  const raw = `pdk_${crypto.randomBytes(24).toString('hex')}`; // "pspf docs key"
  const prefix = raw.slice(0, 8);
  const hash = crypto.createHash('sha256').update(raw).digest('hex');
  return { plaintext: raw, prefix, hash };
}

function hashApiKey(plaintext) {
  return crypto.createHash('sha256').update(plaintext).digest('hex');
}

module.exports = { generateApiKey, hashApiKey };
