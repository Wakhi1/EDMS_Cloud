/**
 * services/audit/retention.scheduler.js
 * Applies the audit retention period (system setting `audit_retention_days`,
 * '0' = keep forever): once a day, audit entries older than the period are
 * deleted.
 *
 * The audit log is hash-chained (services/audit.service.js), so deleting
 * the oldest rows would otherwise make verifyChain() report a break at the
 * first surviving row. Before deleting, the last deleted entry's hash is
 * stored as the chain checkpoint (`audit_chain_anchor_hash`), and
 * verifyChain() starts from it — anything deleted out of order, or edited,
 * is still detected. The purge itself is recorded as an audit entry.
 */
const { pool } = require('../../config/db');
const logger = require('../../config/logger');
const { logAudit, withChainLock } = require('../audit.service');

const CHECK_INTERVAL_MS = 24 * 60 * 60 * 1000;
const FIRST_RUN_DELAY_MS = 60 * 1000;
const MIN_RETENTION_DAYS = 90;
const DEFAULT_SETTINGS = [
  ['audit_retention_days', '0', 'How many days audit entries are kept (0 = forever, otherwise at least 90). Older entries are deleted daily.'],
  ['audit_chain_anchor_hash', null, 'Hash of the last audit entry removed by retention — where hash-chain verification starts. Managed automatically.'],
];

let timer = null;

async function ensureSettings() {
  const [[owner]] = await pool.query('SELECT company_id FROM system_settings LIMIT 1');
  const companyId = owner ? owner.company_id : 1;
  for (const [key, value, description] of DEFAULT_SETTINGS) {
    // eslint-disable-next-line no-await-in-loop
    await pool.query(
      'INSERT IGNORE INTO system_settings (setting_key, company_id, setting_value, description) VALUES (?, ?, ?, ?)',
      [key, companyId, value, description]
    );
  }
}

async function retentionDays() {
  const [[row]] = await pool.query("SELECT setting_value FROM system_settings WHERE setting_key = 'audit_retention_days'");
  const days = Number(row?.setting_value || 0);
  return Number.isFinite(days) && days > 0 ? Math.max(days, MIN_RETENTION_DAYS) : 0;
}

/** Deletes audit entries past the retention period. Returns how many were removed. */
async function purgeExpired() {
  const days = await retentionDays();
  if (!days) return 0;

  let removed = 0;
  let cutoffId = null;
  // Same lock as logAudit, so nothing is appended while the checkpoint moves.
  const purged = await withChainLock(async (conn) => {
    await conn.beginTransaction();
    try {
      const [[last]] = await conn.query(
        'SELECT id, entry_hash FROM audit_log WHERE created_at < (NOW() - INTERVAL ? DAY) ORDER BY id DESC LIMIT 1',
        [days]
      );
      if (!last) {
        await conn.commit();
        return false;
      }
      cutoffId = last.id;
      // Delete by id (not date) so the removed block is always a prefix of the chain.
      const [result] = await conn.query('DELETE FROM audit_log WHERE id <= ?', [cutoffId]);
      removed = result.affectedRows;
      await conn.query("UPDATE system_settings SET setting_value = ? WHERE setting_key = 'audit_chain_anchor_hash'", [last.entry_hash]);
      await conn.commit();
      return true;
    } catch (err) {
      await conn.rollback();
      throw err;
    }
  });
  if (!purged) return 0;

  await logAudit({
    userId: null,
    action: 'Delete',
    recordType: 'audit_log',
    recordId: String(cutoffId),
    detail: `Retention: removed ${removed} audit entr${removed === 1 ? 'y' : 'ies'} older than ${days} days (up to id ${cutoffId})`,
  });
  logger.info('Audit retention purge', { removed, days, cutoffId });
  return removed;
}

function startAuditRetentionScheduler() {
  if (timer) return;
  ensureSettings().catch((err) => logger.error('Audit retention settings seed failed', { error: err.message }));
  const run = () => purgeExpired().catch((err) => logger.error('Audit retention purge failed', { error: err.message }));
  setTimeout(run, FIRST_RUN_DELAY_MS);
  timer = setInterval(run, CHECK_INTERVAL_MS);
  logger.info('Audit retention scheduler started', { checkIntervalMs: CHECK_INTERVAL_MS });
}

module.exports = { startAuditRetentionScheduler, purgeExpired, retentionDays, MIN_RETENTION_DAYS };
