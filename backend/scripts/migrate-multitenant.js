/**
 * scripts/migrate-multitenant.js
 * One-off, idempotent migration for a pre-multi-tenant database (i.e. one
 * created before `company_id` existed on every table): creates the new
 * platform/licensing tables, bootstraps a platform_admins row + the
 * 'PSPF' company from env vars, then backfills `company_id` onto every
 * existing tenant table. Safe to re-run — every step checks
 * information_schema first, so a re-run after a partial failure just
 * skips what's already done. NOT wired into server.js startup; run
 * manually: `node scripts/migrate-multitenant.js`.
 *
 * A fresh install doesn't need this at all — database/pspf_edms_schema.sql
 * already declares company_id inline on every table.
 */
require('dotenv').config();
const bcrypt = require('bcryptjs');
const { pool } = require('../config/db');
const logger = require('../config/logger');

async function tableExists(table) {
  const [[row]] = await pool.query(
    `SELECT COUNT(*) AS n FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?`,
    [table]
  );
  return row.n > 0;
}

async function columnExists(table, column) {
  const [[row]] = await pool.query(
    `SELECT COUNT(*) AS n FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [table, column]
  );
  return row.n > 0;
}

async function indexExists(table, indexName) {
  const [[row]] = await pool.query(
    `SELECT COUNT(*) AS n FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND INDEX_NAME = ?`,
    [table, indexName]
  );
  return row.n > 0;
}

const NEW_TABLES_SQL = {
  platform_admins: `
    CREATE TABLE \`platform_admins\` (
      \`id\`                    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      \`full_name\`             VARCHAR(150) NOT NULL,
      \`email\`                 VARCHAR(190) NOT NULL UNIQUE,
      \`password_hash\`         VARCHAR(255) NOT NULL,
      \`is_owner\`              TINYINT(1) NOT NULL DEFAULT 0,
      \`is_active\`             TINYINT(1) NOT NULL DEFAULT 1,
      \`is_locked\`             TINYINT(1) NOT NULL DEFAULT 0,
      \`failed_login_attempts\` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
      \`last_login_at\`         DATETIME NULL,
      \`last_login_ip\`         VARCHAR(45) NULL,
      \`created_at\`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      \`updated_at\`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    ) ENGINE=InnoDB`,
  platform_admin_sessions: `
    CREATE TABLE \`platform_admin_sessions\` (
      \`id\`                 CHAR(36) PRIMARY KEY,
      \`platform_admin_id\`  INT UNSIGNED NOT NULL,
      \`refresh_token_hash\` CHAR(64) NOT NULL,
      \`user_agent\`         VARCHAR(255) NULL,
      \`ip_address\`         VARCHAR(45) NULL,
      \`expires_at\`         DATETIME NOT NULL,
      \`revoked_at\`         DATETIME NULL,
      \`created_at\`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT \`fk_pasession_admin\` FOREIGN KEY (\`platform_admin_id\`) REFERENCES \`platform_admins\`(\`id\`) ON DELETE CASCADE
    ) ENGINE=InnoDB`,
  companies: `
    CREATE TABLE \`companies\` (
      \`id\`                     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      \`company_code\`           VARCHAR(20) NOT NULL UNIQUE,
      \`name\`                   VARCHAR(190) NOT NULL,
      \`registration_no\`        VARCHAR(80) NULL,
      \`tax_id\`                 VARCHAR(80) NULL,
      \`contact_name\`           VARCHAR(150) NULL,
      \`contact_email\`          VARCHAR(190) NULL,
      \`contact_phone\`          VARCHAR(30) NULL,
      \`logo_provider\`          VARCHAR(30) NULL,
      \`logo_object_key\`        VARCHAR(500) NULL,
      \`logo_content_type\`      VARCHAR(120) NULL,
      \`favicon_provider\`       VARCHAR(30) NULL,
      \`favicon_object_key\`     VARCHAR(500) NULL,
      \`favicon_content_type\`   VARCHAR(120) NULL,
      \`theme_primary_color\`    CHAR(7) NULL,
      \`theme_secondary_color\`  CHAR(7) NULL,
      \`theme_accent_color\`     CHAR(7) NULL,
      \`custom_domain\`          VARCHAR(190) NULL UNIQUE,
      \`enabled_modules_json\`   JSON NULL,
      \`storage_quota_bytes\`    BIGINT UNSIGNED NULL,
      \`max_users\`              INT UNSIGNED NULL,
      \`status\`                 ENUM('active','suspended','deleted') NOT NULL DEFAULT 'active',
      \`last_login_at\`          DATETIME NULL,
      \`created_by\`             INT UNSIGNED NULL,
      \`created_at\`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      \`updated_at\`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
      CONSTRAINT \`fk_company_creator\` FOREIGN KEY (\`created_by\`) REFERENCES \`platform_admins\`(\`id\`) ON DELETE SET NULL
    ) ENGINE=InnoDB`,
  licenses: `
    CREATE TABLE \`licenses\` (
      \`id\`                    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      \`license_key\`           CHAR(36) NOT NULL UNIQUE,
      \`company_id\`            INT UNSIGNED NOT NULL,
      \`license_type\`          ENUM('trial','standard','enterprise') NOT NULL DEFAULT 'trial',
      \`status\`                ENUM('active','suspended','expired','revoked') NOT NULL DEFAULT 'active',
      \`issued_at\`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      \`expires_at\`            DATETIME NOT NULL,
      \`max_users\`             INT UNSIGNED NULL,
      \`storage_quota_bytes\`   BIGINT UNSIGNED NULL,
      \`enabled_modules_json\`  JSON NULL,
      \`signed_token\`          TEXT NOT NULL,
      \`issued_by\`             INT UNSIGNED NOT NULL,
      \`revoked_at\`            DATETIME NULL,
      \`revoked_by\`            INT UNSIGNED NULL,
      \`revoke_reason\`         VARCHAR(255) NULL,
      \`created_at\`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT \`fk_license_company\` FOREIGN KEY (\`company_id\`) REFERENCES \`companies\`(\`id\`),
      CONSTRAINT \`fk_license_issuer\`  FOREIGN KEY (\`issued_by\`) REFERENCES \`platform_admins\`(\`id\`),
      CONSTRAINT \`fk_license_revoker\` FOREIGN KEY (\`revoked_by\`) REFERENCES \`platform_admins\`(\`id\`) ON DELETE SET NULL,
      INDEX \`ix_license_company\` (\`company_id\`),
      INDEX \`ix_license_status\` (\`status\`)
    ) ENGINE=InnoDB`,
  license_validation_log: `
    CREATE TABLE \`license_validation_log\` (
      \`id\`         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      \`license_id\` INT UNSIGNED NULL,
      \`company_id\` INT UNSIGNED NULL,
      \`result\`     ENUM('valid','expired','signature_invalid','suspended','revoked','not_found','malformed') NOT NULL,
      \`source\`     ENUM('login','scheduled_check','manual_admin_check') NOT NULL DEFAULT 'login',
      \`detail\`     VARCHAR(500) NULL,
      \`checked_at\` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT \`fk_lvl_license\` FOREIGN KEY (\`license_id\`) REFERENCES \`licenses\`(\`id\`) ON DELETE SET NULL,
      CONSTRAINT \`fk_lvl_company\` FOREIGN KEY (\`company_id\`) REFERENCES \`companies\`(\`id\`) ON DELETE SET NULL,
      INDEX \`ix_lvl_company\` (\`company_id\`),
      INDEX \`ix_lvl_checked\` (\`checked_at\`)
    ) ENGINE=InnoDB`,
  company_branding_history: `
    CREATE TABLE \`company_branding_history\` (
      \`id\`            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      \`company_id\`    INT UNSIGNED NOT NULL,
      \`changed_field\` ENUM('logo','favicon','theme_primary_color','theme_secondary_color','theme_accent_color','custom_domain') NOT NULL,
      \`old_value\`     VARCHAR(500) NULL,
      \`new_value\`     VARCHAR(500) NULL,
      \`changed_by\`    INT UNSIGNED NOT NULL,
      \`changed_at\`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT \`fk_cbh_company\` FOREIGN KEY (\`company_id\`) REFERENCES \`companies\`(\`id\`) ON DELETE CASCADE,
      CONSTRAINT \`fk_cbh_admin\`   FOREIGN KEY (\`changed_by\`) REFERENCES \`platform_admins\`(\`id\`),
      INDEX \`ix_cbh_company\` (\`company_id\`)
    ) ENGINE=InnoDB`,
  platform_admin_audit_log: `
    CREATE TABLE \`platform_admin_audit_log\` (
      \`id\`                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
      \`platform_admin_id\` INT UNSIGNED NULL,
      \`action\`            VARCHAR(60) NOT NULL,
      \`company_id\`        INT UNSIGNED NULL,
      \`detail\`            VARCHAR(500) NULL,
      \`ip_address\`        VARCHAR(45) NULL,
      \`created_at\`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
      CONSTRAINT \`fk_paal_admin\`   FOREIGN KEY (\`platform_admin_id\`) REFERENCES \`platform_admins\`(\`id\`) ON DELETE SET NULL,
      CONSTRAINT \`fk_paal_company\` FOREIGN KEY (\`company_id\`) REFERENCES \`companies\`(\`id\`) ON DELETE SET NULL,
      INDEX \`ix_paal_company\` (\`company_id\`),
      INDEX \`ix_paal_created\` (\`created_at\`)
    ) ENGINE=InnoDB`,
};

// Order matches database/pspf_edms_schema.sql. Every table just gets
// backfilled to the same single bootstrap company — order between these
// tables doesn't matter for correctness (only that `companies` exists
// first, which the bootstrap step above guarantees).
const TENANT_TABLES = [
  { table: 'departments', uniqueDrops: ['name'], uniqueAdds: [{ name: 'uq_department_company_name', columns: ['company_id', 'name'] }] },
  { table: 'roles', uniqueDrops: ['name'], uniqueAdds: [{ name: 'uq_role_company_name', columns: ['company_id', 'name'] }] },
  {
    table: 'users',
    uniqueDrops: ['staff_number', 'email'],
    uniqueAdds: [
      { name: 'uq_users_company_staff_number', columns: ['company_id', 'staff_number'] },
      { name: 'uq_users_company_email', columns: ['company_id', 'email'] },
    ],
  },
  {
    table: 'user_social_identities',
    uniqueDrops: ['uq_provider_identity'],
    uniqueAdds: [{ name: 'uq_provider_identity', columns: ['company_id', 'provider', 'provider_user_id'] }],
  },
  { table: 'user_mfa_methods' },
  { table: 'otp_codes' },
  { table: 'user_sessions' },
  { table: 'groups', uniqueDrops: ['name'], uniqueAdds: [{ name: 'uq_group_company_name', columns: ['company_id', 'name'] }] },
  { table: 'group_members' },
  {
    table: 'document_types',
    uniqueDrops: ['name', 'code'],
    uniqueAdds: [
      { name: 'uq_doctype_company_name', columns: ['company_id', 'name'] },
      { name: 'uq_doctype_company_code', columns: ['company_id', 'code'] },
    ],
  },
  { table: 'retention_classes', uniqueDrops: ['code'], uniqueAdds: [{ name: 'uq_retention_company_code', columns: ['company_id', 'code'] }] },
  { table: 'folders', uniqueDrops: ['uq_folder_path'], uniqueAdds: [{ name: 'uq_folder_path', columns: ['company_id', 'path'] }] },
  { table: 'documents', uniqueDrops: ['record_no'], uniqueAdds: [{ name: 'uq_doc_company_record_no', columns: ['company_id', 'record_no'] }] },
  { table: 'document_custom_fields' },
  { table: 'document_storage_objects' },
  { table: 'key_encryption_keys' },
  { table: 'document_versions' },
  { table: 'document_encryption_keys' },
  { table: 'document_acl' },
  { table: 'access_requests' },
  { table: 'role_module_permissions' },
  { table: 'workflows' },
  { table: 'workflow_steps' },
  { table: 'document_workflow_instances' },
  { table: 'workflow_approvals' },
  { table: 'audit_log', nullable: true },
  { table: 'notifications' },
  { table: 'integrations' }, // PK stays the bare `id` string this pass — see schema.sql's note on this table
  { table: 'capture_batches', uniqueDrops: ['batch_no'], uniqueAdds: [{ name: 'uq_batch_company_no', columns: ['company_id', 'batch_no'] }] },
  { table: 'capture_batch_items' },
  { table: 'system_settings' }, // PK stays `setting_key` this pass — same reasoning as integrations
  { table: 'user_preferences' },
  { table: 'backups' },
];

async function createNewTablesIfMissing() {
  for (const [table, sql] of Object.entries(NEW_TABLES_SQL)) {
    // eslint-disable-next-line no-await-in-loop
    if (await tableExists(table)) {
      logger.info(`[migrate] ${table} already exists, skipping create`);
      continue;
    }
    // eslint-disable-next-line no-await-in-loop
    await pool.query(sql);
    logger.info(`[migrate] created table ${table}`);
  }
}

async function bootstrapPlatformAdmin() {
  const email = process.env.BOOTSTRAP_PLATFORM_ADMIN_EMAIL;
  const password = process.env.BOOTSTRAP_PLATFORM_ADMIN_PASSWORD;
  if (!email || !password) {
    throw new Error('BOOTSTRAP_PLATFORM_ADMIN_EMAIL / BOOTSTRAP_PLATFORM_ADMIN_PASSWORD must be set in .env');
  }
  const [[existing]] = await pool.query('SELECT id FROM platform_admins WHERE email = ?', [email]);
  if (existing) {
    logger.info('[migrate] bootstrap platform_admins row already exists, skipping');
    return existing.id;
  }
  const passwordHash = await bcrypt.hash(password, 12);
  const [result] = await pool.query(
    `INSERT INTO platform_admins (full_name, email, password_hash, is_owner) VALUES (?, ?, ?, 1)`,
    ['DocSecore Bootstrap Admin', email, passwordHash]
  );
  logger.info('[migrate] created bootstrap platform_admins row', { email });
  return result.insertId;
}

async function bootstrapCompany(createdByAdminId) {
  const [[existing]] = await pool.query(`SELECT id FROM companies WHERE company_code = 'PSPF'`);
  if (existing) {
    logger.info('[migrate] PSPF company row already exists, skipping');
    return existing.id;
  }
  const [result] = await pool.query(
    `INSERT INTO companies (company_code, name, status, created_by) VALUES ('PSPF', 'Public Service Pensions Fund', 'active', ?)`,
    [createdByAdminId]
  );
  logger.info('[migrate] created PSPF company row', { id: result.insertId });
  return result.insertId;
}

async function migrateTenantTable(spec, companyId) {
  const { table, nullable, uniqueDrops = [], uniqueAdds = [] } = spec;

  if (await columnExists(table, 'company_id')) {
    logger.info(`[migrate] ${table}.company_id already exists, skipping`);
    return;
  }

  await pool.query(`ALTER TABLE \`${table}\` ADD COLUMN \`company_id\` INT UNSIGNED NULL`);
  await pool.query(`UPDATE \`${table}\` SET \`company_id\` = ? WHERE \`company_id\` IS NULL`, [companyId]);

  const [[remaining]] = await pool.query(`SELECT COUNT(*) AS n FROM \`${table}\` WHERE \`company_id\` IS NULL`);
  if (remaining.n > 0) {
    throw new Error(`${table}: ${remaining.n} rows still have NULL company_id after backfill — aborting`);
  }

  if (!nullable) {
    await pool.query(`ALTER TABLE \`${table}\` MODIFY \`company_id\` INT UNSIGNED NOT NULL`);
  }

  const fkClause = nullable ? 'ON DELETE SET NULL' : '';
  await pool.query(
    `ALTER TABLE \`${table}\` ADD CONSTRAINT \`fk_${table}_company\` FOREIGN KEY (\`company_id\`) REFERENCES \`companies\`(\`id\`) ${fkClause}`
  );

  for (const dropName of uniqueDrops) {
    // eslint-disable-next-line no-await-in-loop
    if (await indexExists(table, dropName)) {
      // eslint-disable-next-line no-await-in-loop
      await pool.query(`ALTER TABLE \`${table}\` DROP INDEX \`${dropName}\``);
    }
  }
  for (const add of uniqueAdds) {
    // eslint-disable-next-line no-await-in-loop
    if (!(await indexExists(table, add.name))) {
      const cols = add.columns.map((c) => `\`${c}\``).join(', ');
      // eslint-disable-next-line no-await-in-loop
      await pool.query(`ALTER TABLE \`${table}\` ADD UNIQUE KEY \`${add.name}\` (${cols})`);
    }
  }

  if (!uniqueAdds.length && !(await indexExists(table, `ix_${table}_company`))) {
    await pool.query(`ALTER TABLE \`${table}\` ADD INDEX \`ix_${table}_company\` (\`company_id\`)`);
  }

  logger.info(`[migrate] backfilled company_id on ${table}`);
}

async function run() {
  logger.info('[migrate] starting multi-tenant migration');
  await createNewTablesIfMissing();
  const adminId = await bootstrapPlatformAdmin();
  const companyId = await bootstrapCompany(adminId);

  for (const spec of TENANT_TABLES) {
    // eslint-disable-next-line no-await-in-loop
    await migrateTenantTable(spec, companyId);
  }

  logger.info('[migrate] multi-tenant migration complete', { companyId });
}

run()
  .then(() => process.exit(0))
  .catch((err) => {
    logger.error('[migrate] migration failed', { error: err.message, stack: err.stack });
    process.exit(1);
  });
