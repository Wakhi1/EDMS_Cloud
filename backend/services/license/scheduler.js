/**
 * services/license/scheduler.js
 * Hourly proactive check of every active license's expiry — same
 * non-durable, setInterval-based philosophy as services/backup/scheduler.js
 * (no job queue, no persistence across restarts). Flips `licenses.status`
 * to 'expired' in the DB as soon as `expires_at` passes, so a dormant
 * company's license doesn't appear falsely "active" between logins.
 */
const { pool } = require('../../config/db');
const logger = require('../../config/logger');
const { checkCompanyLicense } = require('../license.service');

const CHECK_INTERVAL_MS = 60 * 60 * 1000;

let timer = null;

async function checkAllActiveLicenses() {
  try {
    const [rows] = await pool.query(`SELECT id, company_id FROM licenses WHERE status = 'active'`);
    for (const row of rows) {
      // checkCompanyLicense already flips an expired row's status and
      // writes the log entry as a side effect; run it per-company so a
      // superseded/duplicate row (shouldn't normally exist) doesn't get
      // double-counted.
      // eslint-disable-next-line no-await-in-loop
      await checkCompanyLicense(row.company_id, 'scheduled_check');
    }
    logger.info('License scheduler tick complete', { checked: rows.length });
  } catch (err) {
    logger.error('License scheduler tick failed', { error: err.message });
  }
}

function startScheduler() {
  if (timer) return;
  timer = setInterval(checkAllActiveLicenses, CHECK_INTERVAL_MS);
  checkAllActiveLicenses();
  logger.info('License scheduler started', { checkIntervalMs: CHECK_INTERVAL_MS });
}

module.exports = { startScheduler };
