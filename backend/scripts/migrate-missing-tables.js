/**
 * scripts/migrate-missing-tables.js
 * One-off, idempotent catch-up for a database created from an older
 * schema: creates every table declared in database/pspf_edms_schema.sql
 * that this database doesn't have yet (e.g. record_indexes,
 * report_templates, watermark_templates — added to the schema without
 * their own migration). Tables are created in schema order so foreign keys
 * resolve; existing tables are never touched. Columns missing from
 * existing tables are only reported — use the feature-specific migrate-*
 * scripts for those.
 *
 * Safe to re-run. Run manually:
 *   node scripts/migrate-missing-tables.js
 */
require('dotenv').config();
const fs = require('fs');
const path = require('path');
const { pool } = require('../config/db');
const logger = require('../config/logger');

const SCHEMA_PATH = path.join(__dirname, '..', '..', 'database', 'pspf_edms_schema.sql');
const CREATE_TABLE = /CREATE TABLE (?:IF NOT EXISTS )?`(\w+)` \(([\s\S]*?)\n\)([^;]*);/g;

async function run() {
  const sql = fs.readFileSync(SCHEMA_PATH, 'utf8');
  const [cols] = await pool.query('SELECT TABLE_NAME AS t, COLUMN_NAME AS c FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE()');
  const existing = new Map();
  for (const { t, c } of cols) {
    if (!existing.has(t)) existing.set(t, new Set());
    existing.get(t).add(c);
  }

  let created = 0;
  for (const [statement, table, body] of sql.matchAll(CREATE_TABLE)) {
    if (existing.has(table)) {
      const missing = [...body.matchAll(/^\s+`(\w+)`\s/gm)].map((m) => m[1]).filter((c) => !existing.get(table).has(c));
      if (missing.length) logger.warn(`Table ${table} is missing columns (not changed here)`, { missing });
      continue; // eslint-disable-line no-continue
    }
    // eslint-disable-next-line no-await-in-loop
    await pool.query(statement.replace(/^CREATE TABLE (IF NOT EXISTS )?/, 'CREATE TABLE IF NOT EXISTS '));
    logger.info(`Created table ${table}`);
    created += 1;
  }
  logger.info('migrate-missing-tables: done', { created });
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    logger.error('migrate-missing-tables failed', { error: err.message });
    process.exit(1);
  });
