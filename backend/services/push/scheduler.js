/**
 * services/push/scheduler.js
 * In-process poller for outbound-push connectors — the mirror image of
 * services/capture/scheduler.js (which pulls files in on an interval);
 * this pushes a payload out on an interval instead. Same "not a durable
 * job queue" tradeoff as every other scheduler in this app: a setInterval
 * per enabled connector, alive only as long as `node server.js` stays up.
 */
const { pool } = require('../../config/db');
const logger = require('../../config/logger');
const webhookPush = require('./webhook.push');

const PUSH_CONNECTORS = { webhook: webhookPush };

const timers = new Map();

/** mysql2 returns JSON columns as raw strings, not pre-parsed objects — see capture/scheduler.js#parseConfig, the original instance of this same gotcha. */
function parseConfig(raw) {
  if (!raw) return {};
  if (typeof raw === 'object') return raw;
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

async function pushConnector(connectorId) {
  // Everything in this function body must stay inside this try — setInterval
  // never awaits or catches this function's returned promise, so any
  // rejection that escapes here becomes an unhandled promise rejection that
  // crashes the whole process (same lesson already learned the hard way in
  // capture/scheduler.js#pollConnector).
  try {
    const [[row]] = await pool.query('SELECT config_json FROM integrations WHERE id = ?', [connectorId]);
    if (!row) return;
    const config = parseConfig(row.config_json);
    const connector = PUSH_CONNECTORS[connectorId];

    const result = await connector.push(config);
    await pool.query(
      'UPDATE integrations SET status = ?, last_sync_at = NOW() WHERE id = ?',
      [result.ok ? 'connected' : 'error', connectorId]
    );
    if (!result.ok) logger.warn('Outbound push failed', { connectorId, message: result.message });
  } catch (err) {
    logger.warn('Outbound push threw', { connectorId, error: err.message });
    try {
      await pool.query(`UPDATE integrations SET status = 'error', last_sync_at = NOW() WHERE id = ?`, [connectorId]);
    } catch (writeErr) {
      logger.warn('Outbound push: failed to record error status', { connectorId, error: writeErr.message });
    }
  }
}

/** Starts one interval per enabled push connector; called once at server boot. */
async function startPushScheduler() {
  const [rows] = await pool.query(`SELECT id, config_json FROM integrations WHERE id IN (?)`, [Object.keys(PUSH_CONNECTORS)]);
  for (const row of rows) {
    const config = parseConfig(row.config_json);
    if (!config.enabled) continue; // eslint-disable-line no-continue

    const intervalMs = (config.pollIntervalMinutes || 15) * 60 * 1000;
    const timer = setInterval(() => pushConnector(row.id), intervalMs);
    timers.set(row.id, timer);
    logger.info('Outbound push connector scheduled', { connectorId: row.id, intervalMs });
  }
}

/** Re-reads config and restarts a single connector's timer — called after an admin edits its config_json. */
async function reschedulePushConnector(connectorId) {
  if (timers.has(connectorId)) {
    clearInterval(timers.get(connectorId));
    timers.delete(connectorId);
  }
  const [[row]] = await pool.query('SELECT config_json FROM integrations WHERE id = ?', [connectorId]);
  if (!row) return;
  const config = parseConfig(row.config_json);
  if (!config.enabled) return;

  const intervalMs = (config.pollIntervalMinutes || 15) * 60 * 1000;
  const timer = setInterval(() => pushConnector(connectorId), intervalMs);
  timers.set(connectorId, timer);
  logger.info('Outbound push connector rescheduled', { connectorId, intervalMs });
}

module.exports = { startPushScheduler, reschedulePushConnector, pushConnector, PUSH_CONNECTORS };
