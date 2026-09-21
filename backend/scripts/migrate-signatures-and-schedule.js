/**
 * scripts/migrate-signatures-and-schedule.js
 * One-off, idempotent migration for a database created before this change:
 * adds signature-required workflow steps, scheduled/recurring workflow
 * triggers, the user_signatures table backing Settings -> My Signature,
 * and the workflow_approval_signatures snapshot table. Safe to re-run —
 * every step checks information_schema first.
 *
 * A fresh install doesn't need this at all — database/pspf_edms_schema.sql
 * already declares these inline. Run manually:
 *   node scripts/migrate-signatures-and-schedule.js
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
  if (!(await columnExists('workflow_steps', 'requires_signature'))) {
    await pool.query(
      `ALTER TABLE workflow_steps ADD COLUMN requires_signature TINYINT(1) NOT NULL DEFAULT 0`
    );
    logger.info('Added workflow_steps.requires_signature');
  }

  if (!(await columnExists('workflows', 'schedule_enabled'))) {
    await pool.query(`
      ALTER TABLE workflows
        ADD COLUMN schedule_enabled TINYINT(1) NOT NULL DEFAULT 0,
        ADD COLUMN schedule_target_document_id INT UNSIGNED NULL,
        ADD COLUMN schedule_start_at DATETIME NULL,
        ADD COLUMN schedule_recurrence ENUM('once','daily','weekly','monthly','yearly') NULL,
        ADD COLUMN schedule_end_at DATETIME NULL,
        ADD COLUMN schedule_next_run_at DATETIME NULL,
        ADD CONSTRAINT fk_wf_schedule_doc FOREIGN KEY (schedule_target_document_id) REFERENCES documents(id) ON DELETE SET NULL,
        ADD INDEX ix_wf_schedule_due (schedule_enabled, schedule_next_run_at)
    `);
    logger.info('Added workflows schedule_* columns');
  }

  if (!(await tableExists('user_signatures'))) {
    await pool.query(`
      CREATE TABLE \`user_signatures\` (
        \`user_id\`               INT UNSIGNED PRIMARY KEY,
        \`company_id\`            INT UNSIGNED NOT NULL,
        \`encrypted_image\`       MEDIUMBLOB NOT NULL,
        \`key_encryption_key_id\` INT UNSIGNED NOT NULL,
        \`wrapped_dek\`           VARBINARY(512) NOT NULL,
        \`dek_iv\`                VARBINARY(32) NOT NULL,
        \`dek_auth_tag\`          VARBINARY(32) NOT NULL,
        \`file_iv\`               VARBINARY(32) NOT NULL,
        \`file_auth_tag\`         VARBINARY(32) NOT NULL,
        \`checksum_sha256\`       CHAR(64) NOT NULL,
        \`content_type\`          VARCHAR(50) NOT NULL DEFAULT 'image/png',
        \`created_at\`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        \`updated_at\`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        CONSTRAINT \`fk_sig_user\` FOREIGN KEY (\`user_id\`) REFERENCES \`users\`(\`id\`) ON DELETE CASCADE,
        CONSTRAINT \`fk_sig_kek\`  FOREIGN KEY (\`key_encryption_key_id\`) REFERENCES \`key_encryption_keys\`(\`id\`)
      ) ENGINE=InnoDB
    `);
    logger.info('Created user_signatures table');
  }

  if (!(await tableExists('workflow_approval_signatures'))) {
    await pool.query(`
      CREATE TABLE \`workflow_approval_signatures\` (
        \`id\`                    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
        \`company_id\`            INT UNSIGNED NOT NULL,
        \`approval_id\`           BIGINT UNSIGNED NOT NULL UNIQUE,
        \`encrypted_image\`       MEDIUMBLOB NOT NULL,
        \`key_encryption_key_id\` INT UNSIGNED NOT NULL,
        \`wrapped_dek\`           VARBINARY(512) NOT NULL,
        \`dek_iv\`                VARBINARY(32) NOT NULL,
        \`dek_auth_tag\`          VARBINARY(32) NOT NULL,
        \`file_iv\`               VARBINARY(32) NOT NULL,
        \`file_auth_tag\`         VARBINARY(32) NOT NULL,
        \`created_at\`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
        CONSTRAINT \`fk_wfas_approval\` FOREIGN KEY (\`approval_id\`) REFERENCES \`workflow_approvals\`(\`id\`) ON DELETE CASCADE,
        CONSTRAINT \`fk_wfas_kek\`      FOREIGN KEY (\`key_encryption_key_id\`) REFERENCES \`key_encryption_keys\`(\`id\`)
      ) ENGINE=InnoDB
    `);
    logger.info('Created workflow_approval_signatures table');
  }

  logger.info('migrate-signatures-and-schedule: done');
  process.exit(0);
}

run().catch((err) => {
  logger.error('migrate-signatures-and-schedule failed', { error: err.message });
  process.exit(1);
});
