/**
 * scripts/migrate-provider-sync.js
 * One-off, idempotent migration for a pre-provider-sync database (i.e.
 * one created before this deployment started pulling its license from
 * docsecure-platform-provider instead of self-issuing): makes
 * `licenses.issued_by` nullable, adds `licenses.source`/`provider_synced_at`,
 * and adds `'provider_sync'` to `license_validation_log.source`'s enum.
 *
 * Safe to re-run — every step checks information_schema first. NOT wired
 * into server.js startup; run manually: `node scripts/migrate-provider-sync.js`.
 *
 * A fresh install doesn't need this at all — database/pspf_edms_schema.sql
 * already declares these columns/enum values inline.
 */
require('dotenv').config();
const { pool } = require('../config/db');
const logger = require('../config/logger');

async function columnExists(table, column) {
  const [[row]] = await pool.query(
    `SELECT COUNT(*) AS n FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [table, column]
  );
  return row.n > 0;
}

async function columnIsNullable(table, column) {
  const [[row]] = await pool.query(
    `SELECT IS_NULLABLE AS nullable FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [table, column]
  );
  return row?.nullable === 'YES';
}

async function run() {
  if (!(await columnIsNullable('licenses', 'issued_by'))) {
    logger.info('Dropping fk_license_issuer and making licenses.issued_by nullable...');
    await pool.query('ALTER TABLE `licenses` DROP FOREIGN KEY `fk_license_issuer`');
    await pool.query('ALTER TABLE `licenses` MODIFY `issued_by` INT UNSIGNED NULL');
    await pool.query(
      'ALTER TABLE `licenses` ADD CONSTRAINT `fk_license_issuer` FOREIGN KEY (`issued_by`) REFERENCES `platform_admins`(`id`) ON DELETE SET NULL'
    );
  } else {
    logger.info('licenses.issued_by is already nullable, skipping.');
  }

  if (!(await columnExists('licenses', 'source'))) {
    logger.info('Adding licenses.source...');
    await pool.query(
      "ALTER TABLE `licenses` ADD COLUMN `source` ENUM('local','provider_sync') NOT NULL DEFAULT 'local' AFTER `signed_token`"
    );
    // Existing rows predate provider-sync entirely — they were self-issued locally.
    await pool.query("UPDATE `licenses` SET `source` = 'local'");
  } else {
    logger.info('licenses.source already exists, skipping.');
  }

  if (!(await columnExists('licenses', 'provider_synced_at'))) {
    logger.info('Adding licenses.provider_synced_at...');
    await pool.query('ALTER TABLE `licenses` ADD COLUMN `provider_synced_at` DATETIME NULL AFTER `source`');
  } else {
    logger.info('licenses.provider_synced_at already exists, skipping.');
  }

  const [[sourceColumn]] = await pool.query(
    `SELECT COLUMN_TYPE AS type FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'license_validation_log' AND COLUMN_NAME = 'source'`
  );
  if (sourceColumn && !sourceColumn.type.includes('provider_sync')) {
    logger.info("Adding 'provider_sync' to license_validation_log.source enum...");
    await pool.query(
      "ALTER TABLE `license_validation_log` MODIFY `source` ENUM('login','scheduled_check','manual_admin_check','provider_sync') NOT NULL DEFAULT 'login'"
    );
  } else {
    logger.info('license_validation_log.source already includes provider_sync, skipping.');
  }

  const [[sourceColumn2]] = await pool.query(
    `SELECT COLUMN_TYPE AS type FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'license_validation_log' AND COLUMN_NAME = 'source'`
  );
  if (sourceColumn2 && !sourceColumn2.type.includes('status_check')) {
    logger.info("Adding 'status_check' to license_validation_log.source enum...");
    await pool.query(
      "ALTER TABLE `license_validation_log` MODIFY `source` ENUM('login','scheduled_check','manual_admin_check','provider_sync','status_check') NOT NULL DEFAULT 'login'"
    );
  } else {
    logger.info('license_validation_log.source already includes status_check, skipping.');
  }

  // checkCompanyLicense (services/license.service.js) now only ever trusts
  // source='provider_sync' rows — a locally self-issued license from
  // before this deployment pulled from docsecure-platform-provider must
  // never grant access, even if it's still sitting there as 'active'.
  // Idempotent: matches nothing once this has already run.
  const [staleResult] = await pool.query(
    `UPDATE licenses SET status = 'revoked', revoked_at = NOW(),
       revoke_reason = 'Locally self-issued licenses are no longer trusted — DocSecure platform-provider is now the sole source of truth'
     WHERE status = 'active' AND source = 'local'`
  );
  if (staleResult.affectedRows) {
    logger.info(`Revoked ${staleResult.affectedRows} stale locally-issued active license(s).`);
  }

  logger.info('migrate-provider-sync complete.');
}

run()
  .catch((err) => {
    logger.error('migrate-provider-sync failed', { error: err.message });
    process.exitCode = 1;
  })
  .finally(() => pool.end());
