/**
 * utils/integrationConfig.js
 * One place to read a single integration's config_json — mysql2 returns
 * JSON columns as raw strings, not pre-parsed objects (confirmed by direct
 * query, not an assumption — see services/capture/scheduler.js#parseConfig,
 * the original instance of this same parse), so every reader of this
 * column must go through the same defensive parse. Self-contained lookup
 * (query + parse), not threaded through callers — same style as
 * storage.service.js#activeProvider().
 */
const { pool } = require('../config/db');

async function getIntegrationConfig(id) {
  try {
    const [[row]] = await pool.query('SELECT config_json FROM integrations WHERE id = ?', [id]);
    if (!row || !row.config_json) return {};
    return typeof row.config_json === 'object' ? row.config_json : JSON.parse(row.config_json);
  } catch {
    return {};
  }
}

module.exports = { getIntegrationConfig };
