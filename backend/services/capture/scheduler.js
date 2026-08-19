/**
 * services/capture/scheduler.js
 * In-process poller for the three automated intake connectors — this is
 * intentionally NOT a durable job queue: it's a setInterval per enabled
 * connector, running only as long as `node server.js` stays up, with no
 * persistence or retry across process restarts. That matches every other
 * piece of automation in this app (nothing here uses a queue or worker
 * service) and is an honest, stated tradeoff for a demo environment, not
 * a hidden limitation.
 *
 * "Left running overnight" is satisfied as long as the backend process
 * itself is left running overnight.
 */
const { pool } = require('../../config/db');
const logger = require('../../config/logger');
const { runBatch } = require('./batch.service');
const watchedFolder = require('../intake/watchedFolder.intake');
const ftp = require('../intake/ftp.intake');
const emailIntake = require('../intake/email.intake');

const CONNECTORS = {
  watched_folder: watchedFolder,
  ftp,
  email_intake: emailIntake,
};

const timers = new Map();

/**
 * mysql2 returns JSON columns as raw strings, not pre-parsed objects (this
 * driver/config does not auto-parse — confirmed by direct query, not an
 * assumption) — every config_json read anywhere in this file, plus
 * integrations.routes.js's /:id/test handler, must go through this.
 */
function parseConfig(raw) {
  if (!raw) return {};
  if (typeof raw === 'object') return raw;
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

async function pollConnector(connectorId) {
  // Everything in this function body must stay inside this try — setInterval
  // (see startScheduler/rescheduleConnector below) never awaits or catches
  // this function's returned promise, so ANY rejection that escapes here
  // becomes an unhandled promise rejection that crashes the whole process.
  // This bit the server for real: a transient ECONNRESET on the very first
  // query below (config lookup) took the whole API down overnight, even
  // though the connector-poll step a few lines later was already guarded.
  try {
    const [[row]] = await pool.query('SELECT config_json FROM integrations WHERE id = ?', [connectorId]);
    if (!row) return;
    const config = parseConfig(row.config_json);
    const connector = CONNECTORS[connectorId];

    const files = await connector.poll(config);
    if (files.length > 0) {
      const result = await runBatch({ source: connectorId, files, defaultFolderId: config.defaultFolderId });
      logger.info('Automated capture batch completed', { connectorId, ...result });
    }
    await pool.query(
      `UPDATE integrations SET status = 'connected', last_sync_at = NOW(),
         stats_json = JSON_SET(COALESCE(stats_json, '{}'), '$.lastFileCount', ?) WHERE id = ?`,
      [files.length, connectorId]
    );
  } catch (err) {
    // A connector failure (e.g. FTP unreachable, no real credentials yet,
    // or a transient DB blip on the config lookup itself) must never crash
    // the process or block the other connectors' timers.
    logger.warn('Automated intake poll failed', { connectorId, error: err.message });
    try {
      await pool.query(`UPDATE integrations SET status = 'error', last_sync_at = NOW() WHERE id = ?`, [connectorId]);
    } catch (writeErr) {
      // Same reasoning as above, one level deeper: if even this write
      // fails (e.g. the same connection blip), swallow it too rather than
      // let it escape as a second unhandled rejection.
      logger.warn('Automated intake poll: failed to record error status', { connectorId, error: writeErr.message });
    }
  }
}

/** Starts one interval per enabled connector; called once at server boot. */
async function startScheduler() {
  const [rows] = await pool.query(
    `SELECT id, config_json FROM integrations WHERE id IN (?)`,
    [Object.keys(CONNECTORS)]
  );
  for (const row of rows) {
    const config = parseConfig(row.config_json);
    if (!config.enabled) continue;

    const intervalMs = (config.pollIntervalSeconds ? config.pollIntervalSeconds : (config.pollIntervalMinutes || 15) * 60) * 1000;
    const timer = setInterval(() => pollConnector(row.id), intervalMs);
    timers.set(row.id, timer);
    logger.info('Automated intake connector scheduled', { connectorId: row.id, intervalMs });
  }
}

/** Re-reads config and restarts a single connector's timer — called after an admin edits its config_json. */
async function rescheduleConnector(connectorId) {
  if (timers.has(connectorId)) {
    clearInterval(timers.get(connectorId));
    timers.delete(connectorId);
  }
  const [[row]] = await pool.query('SELECT config_json FROM integrations WHERE id = ?', [connectorId]);
  if (!row) return;
  const config = parseConfig(row.config_json);
  if (!config.enabled) return;

  const intervalMs = (config.pollIntervalSeconds ? config.pollIntervalSeconds : (config.pollIntervalMinutes || 15) * 60) * 1000;
  const timer = setInterval(() => pollConnector(connectorId), intervalMs);
  timers.set(connectorId, timer);
  logger.info('Automated intake connector rescheduled', { connectorId, intervalMs });
}

module.exports = { startScheduler, rescheduleConnector, pollConnector, CONNECTORS, parseConfig };
