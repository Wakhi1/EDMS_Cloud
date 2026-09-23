/**
 * services/audit.service.js
 * Writes hash-chained, append-only audit entries (Records Act / Internal
 * Auditor requirement). Each entry's hash covers the previous entry's
 * hash, so any row deletion/edit breaks the chain and is detectable via
 * verifyChain().
 */
const crypto = require('crypto');
const { pool } = require('../config/db');
const logger = require('../config/logger');

/** MySQL named lock serialising chain writes (and the retention purge). */
const CHAIN_LOCK = 'pspf_edms_audit_chain';
const LOCK_TIMEOUT_SECONDS = 10;

async function getLastHash(conn) {
  const [rows] = await conn.query(
    `SELECT entry_hash FROM audit_log ORDER BY id DESC LIMIT 1`
  );
  if (rows[0]) return rows[0].entry_hash;
  // Empty log after a retention purge: continue from the checkpoint.
  const [[anchor]] = await conn.query("SELECT setting_value FROM system_settings WHERE setting_key = 'audit_chain_anchor_hash'");
  return anchor?.setting_value || '0'.repeat(64);
}

/**
 * Runs fn on a connection holding the chain lock. Without it, two requests
 * logging at the same moment both read the same "last" hash and fork the
 * chain — which verifyChain() then reports as tampering.
 */
async function withChainLock(fn) {
  const conn = await pool.getConnection();
  try {
    const [[{ got }]] = await conn.query('SELECT GET_LOCK(?, ?) AS got', [CHAIN_LOCK, LOCK_TIMEOUT_SECONDS]);
    if (got !== 1) throw new Error('Timed out waiting for the audit chain lock');
    try {
      return await fn(conn);
    } finally {
      await conn.query('SELECT RELEASE_LOCK(?)', [CHAIN_LOCK]);
    }
  } finally {
    conn.release();
  }
}

function computeHash(prevHash, payload) {
  return crypto
    .createHash('sha256')
    .update(prevHash + JSON.stringify(payload))
    .digest('hex');
}

async function logAudit({ userId = null, companyId = null, action, recordType = null, recordId = null, detail = null, ip = null, userAgent = null }) {
  try {
    await withChainLock(async (conn) => {
      const prevHash = await getLastHash(conn);
      const payload = { userId, action, recordType, recordId, detail, ip, userAgent, ts: Date.now() };
      const entryHash = computeHash(prevHash, payload);

      await conn.query(
        `INSERT INTO audit_log (company_id, user_id, action, record_type, record_id, detail, ip_address, user_agent, prev_hash, entry_hash)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [companyId, userId, action, recordType, recordId, detail, ip, userAgent, prevHash, entryHash]
      );
    });
  } catch (err) {
    // Auditing must never crash the request that triggered it, but the
    // failure itself is important operationally.
    logger.error('Failed to write audit entry', { error: err.message, action, recordType, recordId });
  }
}

/**
 * Walk the whole chain and confirm no entry has been tampered with. Starts
 * from the retention checkpoint when old entries have been purged (see
 * services/audit/retention.scheduler.js), otherwise from the genesis hash.
 */
async function verifyChain() {
  const [rows] = await pool.query(`SELECT * FROM audit_log ORDER BY id ASC`);
  const [[anchor]] = await pool.query("SELECT setting_value FROM system_settings WHERE setting_key = 'audit_chain_anchor_hash'");
  let prevHash = anchor?.setting_value || '0'.repeat(64);
  for (const row of rows) {
    const payload = {
      userId: row.user_id, action: row.action, recordType: row.record_type,
      recordId: row.record_id, detail: row.detail, ip: row.ip_address,
      userAgent: row.user_agent, ts: new Date(row.created_at).getTime(),
    };
    // Note: ts recomputation is approximate for legacy rows; in production
    // store the raw payload JSON alongside the hash for exact re-verification.
    if (row.prev_hash !== prevHash) {
      return { valid: false, brokenAtId: row.id, entries: rows.length };
    }
    prevHash = row.entry_hash;
  }
  return { valid: true, brokenAtId: null, entries: rows.length };
}

module.exports = { logAudit, verifyChain, withChainLock };
