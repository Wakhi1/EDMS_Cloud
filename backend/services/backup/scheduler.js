/**
 * services/backup/scheduler.js
 * In-process automatic nightly backup — same non-durable, setInterval-based
 * philosophy as services/capture/scheduler.js (no job queue, no
 * persistence/retry across process restarts; "runs nightly" is satisfied
 * as long as `node server.js` itself stays up).
 *
 * Polls `system_settings` every CHECK_INTERVAL_MS and fires runBackup()
 * once per calendar day, the first time the server-local hour reaches
 * `backup_schedule_hour`, while `backup_schedule_enabled` = 'true'. Both
 * settings are edited live via Settings > System Settings; no restart is
 * needed for a change to take effect since this re-reads them every tick.
 */
const { pool } = require('../../config/db');
const logger = require('../../config/logger');
const { runBackup } = require('../backup.service');

const CHECK_INTERVAL_MS = 5 * 60 * 1000;

let timer = null;
let lastRunDate = null; // 'YYYY-MM-DD' local date the automatic backup last fired, guards against re-firing every tick within the same target hour

async function checkAndRun() {
  try {
    const [rows] = await pool.query(
      `SELECT setting_key, setting_value FROM system_settings WHERE setting_key IN ('backup_schedule_enabled', 'backup_schedule_hour')`
    );
    const settings = Object.fromEntries(rows.map((r) => [r.setting_key, r.setting_value]));
    if (settings.backup_schedule_enabled !== 'true') return;

    const targetHour = Number(settings.backup_schedule_hour ?? 2);
    const now = new Date();
    const today = now.toISOString().slice(0, 10);
    if (now.getHours() !== targetHour || lastRunDate === today) return;

    lastRunDate = today; // set before the (possibly slow) run so a tick landing while runBackup is still in flight can't double-fire
    logger.info('Automatic nightly backup starting', { targetHour });
    await runBackup({ createdBy: null, ip: null });
  } catch (err) {
    // runBackup already records its own failure in the backups table and
    // notifies ICT; this catch only guards the scheduler's own timer loop.
    logger.error('Automatic nightly backup check failed', { error: err.message });
  }
}

/** Starts the 5-minute poll; called once at server boot. */
function startScheduler() {
  if (timer) return;
  timer = setInterval(checkAndRun, CHECK_INTERVAL_MS);
  checkAndRun();
  logger.info('Backup scheduler started', { checkIntervalMs: CHECK_INTERVAL_MS });
}

module.exports = { startScheduler };
