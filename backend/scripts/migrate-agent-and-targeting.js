/**
 * scripts/migrate-agent-and-targeting.js
 * One-off, idempotent migration for a database created before this change:
 * adds per-user workflow-step targeting, per-document watermark override,
 * and the api_keys table backing the local watched-folder agent
 * (routes/agentUpload.routes.js). Safe to re-run — every step checks
 * information_schema first.
 *
 * A fresh install doesn't need this at all — database/pspf_edms_schema.sql
 * already declares these inline. Run manually:
 *   node scripts/migrate-agent-and-targeting.js
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

async function tableExists(table) {
  const [[row]] = await pool.query(
    `SELECT COUNT(*) AS n FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?`,
    [table]
  );
  return row.n > 0;
}

async function run() {
  if (!(await columnExists('workflow_steps', 'assignee_user_id'))) {
    await pool.query(
      `ALTER TABLE workflow_steps
         ADD COLUMN assignee_user_id INT UNSIGNED NULL AFTER role_id,
         ADD CONSTRAINT fk_wfs_assignee FOREIGN KEY (assignee_user_id) REFERENCES users(id)`
    );
    logger.info('Added workflow_steps.assignee_user_id');
  }

  if (!(await columnExists('documents', 'watermark_mode'))) {
    await pool.query(
      `ALTER TABLE documents
         ADD COLUMN watermark_mode ENUM('inherit','on','off') NOT NULL DEFAULT 'inherit' AFTER classification`
    );
    logger.info('Added documents.watermark_mode');
  }

  if (!(await tableExists('api_keys'))) {
    await pool.query(`
      CREATE TABLE \`api_keys\` (
        \`id\`            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        \`company_id\`    INT UNSIGNED NOT NULL,
        \`name\`          VARCHAR(150) NOT NULL,
        \`key_prefix\`    VARCHAR(12) NOT NULL,
        \`key_hash\`      CHAR(64) NOT NULL,
        \`scope\`         VARCHAR(50) NOT NULL DEFAULT 'capture_upload',
        \`created_by\`    INT UNSIGNED NOT NULL,
        \`last_used_at\`  DATETIME NULL,
        \`revoked_at\`    DATETIME NULL,
        \`created_at\`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        UNIQUE KEY \`uq_api_key_hash\` (\`key_hash\`),
        CONSTRAINT \`fk_apikey_creator\` FOREIGN KEY (\`created_by\`) REFERENCES \`users\`(\`id\`),
        INDEX \`ix_apikey_company\` (\`company_id\`)
      ) ENGINE=InnoDB
    `);
    logger.info('Created api_keys table');
  }

  logger.info('migrate-agent-and-targeting: done');
  process.exit(0);
}

run().catch((err) => {
  logger.error('migrate-agent-and-targeting failed', { error: err.message });
  process.exit(1);
});
