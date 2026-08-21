/**
 * scripts/remove-local-licensing.js
 * One-off, idempotent migration that finishes the move to
 * docsecure-platform-provider owning company/license data outright:
 * drops this deployment's local `companies`, `licenses`,
 * `license_validation_log`, and `company_branding_history` tables
 * (the provider is the sole source of truth for all of it now — see
 * services/license.service.js), and stops there. `company_id` columns
 * elsewhere in the schema are left in place (still used to tag which
 * tenant a row belongs to) but are no longer foreign-keyed to a local
 * `companies` row, since that row no longer exists anywhere but the
 * provider.
 *
 * In place of a `licenses` row, this deployment now records just the
 * one thing it actually needs locally — the license key it was
 * activated with — as a single `system_settings` row (`license_key`),
 * verified live against the provider on every check. No local cache,
 * no scheduler-maintained state, no offline resilience: see
 * services/license.service.js's checkDeploymentLicense.
 *
 * Safe to re-run — every step checks information_schema first. NOT
 * wired into server.js startup; run manually:
 *   node scripts/remove-local-licensing.js
 */
require('dotenv').config();
const { pool } = require('../config/db');
const logger = require('../config/logger');

async function tableExists(table) {
  const [[row]] = await pool.query(
    `SELECT COUNT(*) AS n FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?`,
    [table]
  );
  return row.n > 0;
}

async function dropCompanyForeignKeys() {
  const [fks] = await pool.query(
    `SELECT k.TABLE_NAME, k.CONSTRAINT_NAME
     FROM information_schema.KEY_COLUMN_USAGE k
     WHERE k.REFERENCED_TABLE_NAME = 'companies' AND k.TABLE_SCHEMA = DATABASE()
       AND k.TABLE_NAME NOT IN ('licenses', 'license_validation_log', 'company_branding_history')`
  );
  for (const { TABLE_NAME: table, CONSTRAINT_NAME: constraint } of fks) {
    logger.info(`Dropping ${table}.${constraint} (FK to companies)...`);
    // eslint-disable-next-line no-await-in-loop
    await pool.query(`ALTER TABLE \`${table}\` DROP FOREIGN KEY \`${constraint}\``);
  }
  if (!fks.length) logger.info('No remaining FKs to companies — already dropped.');
}

async function dropTableIfExists(table) {
  if (await tableExists(table)) {
    logger.info(`Dropping table ${table}...`);
    await pool.query(`DROP TABLE \`${table}\``);
  } else {
    logger.info(`Table ${table} already gone, skipping.`);
  }
}

async function ensureLicenseKeySetting() {
  const [[row]] = await pool.query(`SELECT setting_value FROM system_settings WHERE setting_key = 'license_key'`);
  if (row) {
    logger.info('system_settings.license_key already exists, skipping.');
    return;
  }
  logger.info('Adding system_settings.license_key placeholder row...');
  await pool.query(
    `INSERT INTO system_settings (setting_key, company_id, setting_value, description)
     VALUES ('license_key', 1, NULL, 'The license key this deployment was activated with — verified live against DocSecure''s licensing platform on every check')`
  );
}

async function run() {
  // Order matters: license_validation_log FKs to licenses, so it must go
  // (or have that FK dropped) before licenses; dropping the table drops
  // its own outgoing FKs for free, so no separate DROP FOREIGN KEY needed
  // for fk_lvl_license.
  await dropCompanyForeignKeys();
  await dropTableIfExists('license_validation_log');
  await dropTableIfExists('licenses');
  await dropTableIfExists('company_branding_history');
  await dropTableIfExists('companies');
  await ensureLicenseKeySetting();

  logger.info('remove-local-licensing complete.');
}

run()
  .catch((err) => {
    logger.error('remove-local-licensing failed', { error: err.message });
    process.exitCode = 1;
  })
  .finally(() => pool.end());
