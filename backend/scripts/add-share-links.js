/**
 * scripts/add-share-links.js
 * One-off, idempotent migration adding `document_share_links` — expiring,
 * revocable public links for the Sharing & Links screen (routes/sharing.routes.js).
 * A fresh install doesn't need this at all — database/pspf_edms_schema.sql
 * already declares the table inline.
 *
 * Safe to re-run. NOT wired into server.js startup; run manually:
 *   node scripts/add-share-links.js
 */
require('dotenv').config();
const { pool } = require('../config/db');
const logger = require('../config/logger');

async function run() {
  const [[table]] = await pool.query(
    `SELECT COUNT(*) AS n FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'document_share_links'`
  );
  if (table.n > 0) {
    logger.info('document_share_links already exists, skipping.');
  } else {
    logger.info('Creating document_share_links...');
    await pool.query(`
      CREATE TABLE \`document_share_links\` (
        \`id\`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        \`company_id\`       INT UNSIGNED NOT NULL,
        \`document_id\`      INT UNSIGNED NOT NULL,
        \`token\`            CHAR(43) NOT NULL UNIQUE,
        \`created_by\`       INT UNSIGNED NOT NULL,
        \`expires_at\`       DATETIME NOT NULL,
        \`revoked_at\`       DATETIME NULL,
        \`access_count\`     INT UNSIGNED NOT NULL DEFAULT 0,
        \`last_accessed_at\` DATETIME NULL,
        \`created_at\`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT \`fk_share_document\` FOREIGN KEY (\`document_id\`) REFERENCES \`documents\`(\`id\`) ON DELETE CASCADE,
        CONSTRAINT \`fk_share_creator\` FOREIGN KEY (\`created_by\`) REFERENCES \`users\`(\`id\`),
        INDEX \`ix_share_document\` (\`document_id\`)
      ) ENGINE=InnoDB
    `);
  }

  logger.info('add-share-links complete.');
}

run()
  .catch((err) => {
    logger.error('add-share-links failed', { error: err.message });
    process.exitCode = 1;
  })
  .finally(() => pool.end());
