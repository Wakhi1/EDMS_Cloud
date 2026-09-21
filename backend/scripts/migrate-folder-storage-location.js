/**
 * scripts/migrate-folder-storage-location.js
 * One-off, idempotent migration for a database created before this change:
 * adds a per-folder default storage location. Safe to re-run.
 *
 * A fresh install doesn't need this at all — database/pspf_edms_schema.sql
 * already declares these inline. Run manually:
 *   node scripts/migrate-folder-storage-location.js
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

async function run() {
  if (!(await columnExists('folders', 'storage_provider_id'))) {
    await pool.query(
      `ALTER TABLE folders
         ADD COLUMN storage_provider_id VARCHAR(30) NULL,
         ADD COLUMN storage_prefix VARCHAR(255) NULL,
         ADD CONSTRAINT fk_folder_storage FOREIGN KEY (storage_provider_id) REFERENCES integrations(id) ON DELETE SET NULL`
    );
    logger.info('Added folders.storage_provider_id/storage_prefix');
  }

  logger.info('migrate-folder-storage-location: done');
  process.exit(0);
}

run().catch((err) => {
  logger.error('migrate-folder-storage-location failed', { error: err.message });
  process.exit(1);
});
