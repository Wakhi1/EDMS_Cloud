/**
 * scripts/migrate-storage-capacity-settings.js
 * One-off, idempotent migration for a database created before this change:
 * seeds the per-storage-location capacity settings the Dashboard's
 * "Storage by location" card reads (routes/dashboard.routes.js) — one
 * storage_capacity_bytes_<provider> row per storage provider, editable in
 * Settings -> System Settings. '0' means "not set" (local disk then falls
 * back to the size of the disk it lives on). Safe to re-run.
 *
 * A fresh install doesn't need this at all — database/pspf_edms_schema.sql
 * already seeds these rows. Run manually:
 *   node scripts/migrate-storage-capacity-settings.js
 */
require('dotenv').config();
const { pool } = require('../config/db');
const logger = require('../config/logger');

const SETTINGS = [
  ['storage_capacity_bytes_local', "Capacity in bytes of the Local disk storage location, shown on the Dashboard (0 = use the disk's own size)"],
  ['storage_capacity_bytes_aws_s3', 'Provisioned capacity in bytes of the AWS S3 storage location, shown on the Dashboard (0 = not set)'],
  ['storage_capacity_bytes_azure_blob', 'Provisioned capacity in bytes of the Azure Blob storage location, shown on the Dashboard (0 = not set)'],
  ['storage_capacity_bytes_gcp_storage', 'Provisioned capacity in bytes of the Google Cloud Storage location, shown on the Dashboard (0 = not set)'],
];

async function run() {
  const [[owner]] = await pool.query("SELECT company_id FROM system_settings WHERE setting_key = 'storage_capacity_bytes'");
  const companyId = owner ? owner.company_id : 1;
  for (const [key, description] of SETTINGS) {
    // eslint-disable-next-line no-await-in-loop
    const [result] = await pool.query(
      'INSERT IGNORE INTO system_settings (setting_key, company_id, setting_value, description) VALUES (?, ?, ?, ?)',
      [key, companyId, '0', description]
    );
    if (result.affectedRows) logger.info(`Seeded ${key}`);
  }

  logger.info('migrate-storage-capacity-settings: done');
  process.exit(0);
}

run().catch((err) => {
  logger.error('migrate-storage-capacity-settings failed', { error: err.message });
  process.exit(1);
});
