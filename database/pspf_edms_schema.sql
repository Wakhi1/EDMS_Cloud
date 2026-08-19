-- =====================================================================
-- PSPF EDMS — Electronic Document & Records Management System
-- Database schema (MySQL 5.7+/8, InnoDB, utf8mb4) — XAMPP/phpMyAdmin ready
-- Import via phpMyAdmin > Import, or:  mysql -u root -p < pspf_edms_schema.sql
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `pspf_edms`
  DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;
USE `pspf_edms`;

-- ---------------------------------------------------------------------
-- 1. ORGANISATION / IDENTITY
-- ---------------------------------------------------------------------

CREATE TABLE `departments` (
  `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`        VARCHAR(120) NOT NULL UNIQUE,
  `description` VARCHAR(255) NULL,
  `is_active`   TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE `roles` (
  `id`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`             VARCHAR(80) NOT NULL UNIQUE,   -- e.g. Records Officer, Approving Manager, Finance Officer, Records Manager, System Administrator, Internal Auditor
  `description`      VARCHAR(255) NULL,
  `mfa_required`     TINYINT(1) NOT NULL DEFAULT 0,  -- roles touching member money / PII must use 2FA
  `is_system_role`   TINYINT(1) NOT NULL DEFAULT 0,
  `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE `users` (
  `id`                    INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `staff_number`          VARCHAR(40) NULL UNIQUE,
  `full_name`             VARCHAR(150) NOT NULL,
  `email`                 VARCHAR(190) NOT NULL UNIQUE,
  `phone_number`          VARCHAR(30) NULL,          -- E.164, used for SMS MFA
  `password_hash`         VARCHAR(255) NULL,         -- NULL when account is social-login only
  `role_id`               INT UNSIGNED NOT NULL,
  `department_id`         INT UNSIGNED NULL,
  `is_active`              TINYINT(1) NOT NULL DEFAULT 1,
  `is_locked`              TINYINT(1) NOT NULL DEFAULT 0,
  `failed_login_attempts` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
  `mfa_enabled`            TINYINT(1) NOT NULL DEFAULT 0,
  `email_verified_at`      DATETIME NULL,
  `last_login_at`          DATETIME NULL,
  `last_login_ip`          VARCHAR(45) NULL,
  `password_changed_at`    DATETIME NULL,
  `created_at`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`),
  CONSTRAINT `fk_users_department` FOREIGN KEY (`department_id`) REFERENCES `departments`(`id`)
) ENGINE=InnoDB;

-- Social / federated identities: Google, Microsoft (Azure AD), Active Directory (Kerberos/LDAP)
CREATE TABLE `user_social_identities` (
  `id`                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`           INT UNSIGNED NOT NULL,
  `provider`          ENUM('google','microsoft','active_directory') NOT NULL,
  `provider_user_id`  VARCHAR(190) NOT NULL,   -- sub / oid / sAMAccountName
  `provider_email`    VARCHAR(190) NULL,
  `raw_profile_json`  JSON NULL,
  `linked_at`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_provider_identity` (`provider`, `provider_user_id`),
  CONSTRAINT `fk_social_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- MFA enrolments: TOTP authenticator app, SMS, FIDO2/WebAuthn security key, backup codes
CREATE TABLE `user_mfa_methods` (
  `id`                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`            INT UNSIGNED NOT NULL,
  `method_type`        ENUM('totp','sms','webauthn','backup_codes') NOT NULL,
  `secret_encrypted`   VARBINARY(512) NULL,   -- TOTP secret, encrypted at rest (AES-256-GCM via crypto.service)
  `secret_iv`          VARBINARY(32) NULL,
  `secret_auth_tag`    VARBINARY(32) NULL,
  `webauthn_credential_id` VARCHAR(255) NULL,
  `webauthn_public_key`    TEXT NULL,
  `backup_codes_hash_json` JSON NULL,         -- array of hashed one-time backup codes
  `is_primary`         TINYINT(1) NOT NULL DEFAULT 0,
  `is_verified`        TINYINT(1) NOT NULL DEFAULT 0,
  `created_at`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  -- One row per (user, method): required for mfa.routes.js's `ON DUPLICATE
  -- KEY UPDATE` on enrol/re-enrol and backup-code regeneration to actually
  -- replace the existing row instead of silently inserting a duplicate.
  UNIQUE KEY `uq_user_method` (`user_id`, `method_type`),
  CONSTRAINT `fk_mfa_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Short-lived SMS / email OTP codes (login MFA challenge, not enrolment)
CREATE TABLE `otp_codes` (
  `id`          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`     INT UNSIGNED NOT NULL,
  `channel`     ENUM('sms','email') NOT NULL,
  `purpose`     ENUM('login_mfa','password_reset','email_verify') NOT NULL,
  `code_hash`   CHAR(64) NOT NULL,         -- sha256 of the code, never store plaintext
  `expires_at`  DATETIME NOT NULL,
  `consumed_at` DATETIME NULL,
  `attempts`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_otp_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `user_sessions` (
  `id`                CHAR(36) PRIMARY KEY,     -- UUID (refresh token id / jti)
  `user_id`           INT UNSIGNED NOT NULL,
  `refresh_token_hash` CHAR(64) NOT NULL,
  `user_agent`        VARCHAR(255) NULL,
  `ip_address`        VARCHAR(45) NULL,
  `mfa_satisfied`     TINYINT(1) NOT NULL DEFAULT 0,
  `expires_at`        DATETIME NOT NULL,
  `revoked_at`        DATETIME NULL,
  `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_session_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `groups` (
  `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`        VARCHAR(120) NOT NULL UNIQUE,
  `description` VARCHAR(255) NULL,
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE `group_members` (
  `group_id` INT UNSIGNED NOT NULL,
  `user_id`  INT UNSIGNED NOT NULL,
  PRIMARY KEY (`group_id`, `user_id`),
  CONSTRAINT `fk_gm_group` FOREIGN KEY (`group_id`) REFERENCES `groups`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_gm_user`  FOREIGN KEY (`user_id`)  REFERENCES `users`(`id`)  ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. RETENTION & RECORD TYPES
-- ---------------------------------------------------------------------

CREATE TABLE `document_types` (
  `id`     INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`   VARCHAR(120) NOT NULL UNIQUE,   -- e.g. Claim — Retirement, Contribution Statement, Payout Voucher
  `code`   VARCHAR(20) NOT NULL UNIQUE     -- e.g. PC (Pension Claim)
) ENGINE=InnoDB;

CREATE TABLE `retention_classes` (
  `id`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `code`             VARCHAR(20) NOT NULL UNIQUE,
  `name`             VARCHAR(150) NOT NULL,
  `retention_years`  SMALLINT UNSIGNED NOT NULL,
  `trigger_event`    VARCHAR(100) NOT NULL DEFAULT 'record declared final', -- clock start
  `disposal_action`  ENUM('destroy','archive','transfer_to_national_archives','review') NOT NULL DEFAULT 'review',
  `requires_records_manager_approval` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. FOLDERS & DOCUMENTS
-- ---------------------------------------------------------------------

CREATE TABLE `folders` (
  `id`                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `parent_id`          INT UNSIGNED NULL,     -- self reference => hierarchy e.g. Pension Claims / 2026 / Retirement
  `name`               VARCHAR(150) NOT NULL,
  `path`               VARCHAR(500) NOT NULL, -- materialised path for fast lookups
  `department_id`      INT UNSIGNED NULL,
  `retention_class_id` INT UNSIGNED NULL,
  `created_by`         INT UNSIGNED NULL,
  `created_at`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_folder_parent` FOREIGN KEY (`parent_id`) REFERENCES `folders`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_folder_dept`   FOREIGN KEY (`department_id`) REFERENCES `departments`(`id`),
  CONSTRAINT `fk_folder_retention` FOREIGN KEY (`retention_class_id`) REFERENCES `retention_classes`(`id`),
  CONSTRAINT `fk_folder_creator` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`),
  UNIQUE KEY `uq_folder_path` (`path`)
) ENGINE=InnoDB;

CREATE TABLE `documents` (
  `id`                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `record_no`          VARCHAR(40) NOT NULL UNIQUE,  -- e.g. PC-2026-0433
  `title`              VARCHAR(255) NOT NULL,
  `document_type_id`   INT UNSIGNED NOT NULL,
  `folder_id`          INT UNSIGNED NOT NULL,
  `department_id`      INT UNSIGNED NULL,
  `member_number`      VARCHAR(40) NULL,             -- pension scheme member reference
  `member_name`        VARCHAR(150) NULL,
  `classification`     ENUM('public','internal','restricted','confidential') NOT NULL DEFAULT 'internal',
  `status`             ENUM('draft','pending_approval','approved','rejected','declared_final','archived','disposed') NOT NULL DEFAULT 'draft',
  `retention_class_id` INT UNSIGNED NULL,
  `retention_start_at` DATETIME NULL,                -- set when declared final
  `retention_due_at`   DATETIME NULL,
  `current_version_id` INT UNSIGNED NULL,             -- FK added after document_versions exists
  `owner_id`           INT UNSIGNED NOT NULL,         -- custodian
  `created_by`          INT UNSIGNED NOT NULL,
  `created_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_doc_type`   FOREIGN KEY (`document_type_id`) REFERENCES `document_types`(`id`),
  CONSTRAINT `fk_doc_folder` FOREIGN KEY (`folder_id`) REFERENCES `folders`(`id`),
  CONSTRAINT `fk_doc_dept`   FOREIGN KEY (`department_id`) REFERENCES `departments`(`id`),
  CONSTRAINT `fk_doc_retention` FOREIGN KEY (`retention_class_id`) REFERENCES `retention_classes`(`id`),
  CONSTRAINT `fk_doc_owner`  FOREIGN KEY (`owner_id`) REFERENCES `users`(`id`),
  CONSTRAINT `fk_doc_creator` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`),
  INDEX `ix_doc_member` (`member_number`),
  INDEX `ix_doc_status` (`status`),
  FULLTEXT KEY `ftx_doc_title` (`title`)
) ENGINE=InnoDB;

-- Optional user-defined label:value tags on a document (Smart Upload's
-- "custom indexing"), searchable alongside title/OCR text.
CREATE TABLE `document_custom_fields` (
  `id`          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `document_id` INT UNSIGNED NOT NULL,
  `field_label` VARCHAR(100) NOT NULL,
  `field_value` VARCHAR(500) NOT NULL,
  `created_at`  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_custom_field_document` FOREIGN KEY (`document_id`) REFERENCES `documents`(`id`) ON DELETE CASCADE,
  INDEX `ix_custom_field_document` (`document_id`),
  FULLTEXT KEY `ftx_custom_field_value` (`field_value`)
) ENGINE=InnoDB;

-- Where the encrypted binary lives in the chosen cloud provider
CREATE TABLE `document_storage_objects` (
  `id`               BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `provider`         ENUM('aws_s3','azure_blob','gcp_storage','local') NOT NULL,
  `bucket_or_container` VARCHAR(190) NOT NULL,
  `object_key`       VARCHAR(500) NOT NULL,          -- e.g. documents/2026/PC-2026-0433/v1/<uuid>.enc
  `region`           VARCHAR(60) NULL,
  `content_type`     VARCHAR(120) NOT NULL DEFAULT 'application/octet-stream',
  `size_bytes`       BIGINT UNSIGNED NOT NULL DEFAULT 0,
  `is_encrypted`     TINYINT(1) NOT NULL DEFAULT 1,   -- encrypted at rest (envelope encryption before upload)
  `checksum_sha256`  CHAR(64) NOT NULL,               -- of the *plaintext* file, for integrity verification after decrypt
  `uploaded_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `uq_storage_object` (`provider`, `bucket_or_container`, `object_key`(255))
) ENGINE=InnoDB;

-- Master key metadata (rotation tracking). The actual KEK material lives in
-- env / a secrets manager / cloud KMS — never in this table.
CREATE TABLE `key_encryption_keys` (
  `id`              INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `kek_version`     VARCHAR(40) NOT NULL UNIQUE,     -- e.g. kek-2026-08
  `provider`        ENUM('env','aws_kms','azure_key_vault','gcp_kms') NOT NULL DEFAULT 'env',
  `kms_key_reference` VARCHAR(255) NULL,             -- ARN / Key Vault URI / KMS resource name
  `is_active`       TINYINT(1) NOT NULL DEFAULT 1,
  `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rotated_at`      DATETIME NULL
) ENGINE=InnoDB;

CREATE TABLE `document_versions` (
  `id`                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `document_id`       INT UNSIGNED NOT NULL,
  `version_no`        INT UNSIGNED NOT NULL,        -- 1, 2, 3 ...
  `file_name`         VARCHAR(255) NOT NULL,
  `mime_type`         VARCHAR(120) NOT NULL,
  `size_bytes`        BIGINT UNSIGNED NOT NULL,
  `storage_object_id` BIGINT UNSIGNED NOT NULL,
  `ocr_text`          MEDIUMTEXT NULL,               -- extracted searchable text (from OCR pipeline)
  `is_current`        TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`        INT UNSIGNED NOT NULL,
  `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_ver_document` FOREIGN KEY (`document_id`) REFERENCES `documents`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ver_storage`  FOREIGN KEY (`storage_object_id`) REFERENCES `document_storage_objects`(`id`),
  CONSTRAINT `fk_ver_creator`  FOREIGN KEY (`created_by`) REFERENCES `users`(`id`),
  UNIQUE KEY `uq_doc_version` (`document_id`, `version_no`),
  FULLTEXT KEY `ftx_ocr_text` (`ocr_text`)
) ENGINE=InnoDB;

ALTER TABLE `documents`
  ADD CONSTRAINT `fk_doc_current_version`
  FOREIGN KEY (`current_version_id`) REFERENCES `document_versions`(`id`);

-- The per-document-version data encryption key (DEK), itself wrapped
-- ("envelope encrypted") by the active KEK. The app reads this row,
-- unwraps the DEK using the KEK, then decrypts the object fetched from
-- cloud storage into a readable format for the viewer.
CREATE TABLE `document_encryption_keys` (
  `id`                  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `document_version_id` INT UNSIGNED NOT NULL UNIQUE,
  `key_encryption_key_id` INT UNSIGNED NOT NULL,
  `algorithm`           VARCHAR(40) NOT NULL DEFAULT 'aes-256-gcm',
  `wrapped_dek`         VARBINARY(512) NOT NULL,   -- DEK encrypted with the KEK
  `dek_iv`              VARBINARY(32) NOT NULL,    -- IV used to wrap the DEK
  `dek_auth_tag`        VARBINARY(32) NOT NULL,
  `file_iv`             VARBINARY(32) NOT NULL,    -- IV used to encrypt the file itself with the DEK
  `file_auth_tag`       VARBINARY(32) NOT NULL,
  `created_at`          DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_dek_version` FOREIGN KEY (`document_version_id`) REFERENCES `document_versions`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_dek_kek`     FOREIGN KEY (`key_encryption_key_id`) REFERENCES `key_encryption_keys`(`id`)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. ACCESS CONTROL (folder & document level, inheritable)
-- ---------------------------------------------------------------------

CREATE TABLE `document_acl` (
  `id`              BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `target_type`     ENUM('folder','document') NOT NULL,
  `target_id`       INT UNSIGNED NOT NULL,          -- folders.id or documents.id
  `principal_type`  ENUM('user','group') NOT NULL,
  `principal_id`    INT UNSIGNED NOT NULL,          -- users.id or groups.id
  `permission_level` ENUM('view','comment','edit','approve','full_control') NOT NULL,
  `granted_by`      INT UNSIGNED NOT NULL,
  `granted_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_acl_grantor` FOREIGN KEY (`granted_by`) REFERENCES `users`(`id`),
  INDEX `ix_acl_target` (`target_type`, `target_id`),
  INDEX `ix_acl_principal` (`principal_type`, `principal_id`)
) ENGINE=InnoDB;

-- role x module permission matrix (e.g. can Finance Officer open "Governance/Audit"?)
CREATE TABLE `role_module_permissions` (
  `role_id`   INT UNSIGNED NOT NULL,
  `module`    VARCHAR(60) NOT NULL,   -- dashboard, repository, capture, search, versions, viewer, permissions, security, users, workflow, integrations, reports, audit, retention, approvals
  `can_view`  TINYINT(1) NOT NULL DEFAULT 0,
  `can_edit`  TINYINT(1) NOT NULL DEFAULT 0,
  PRIMARY KEY (`role_id`, `module`),
  CONSTRAINT `fk_rmp_role` FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 5. WORKFLOW / APPROVALS
-- ---------------------------------------------------------------------

CREATE TABLE `workflows` (
  `id`                 INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`               VARCHAR(150) NOT NULL,
  `trigger_doc_type_id` INT UNSIGNED NULL,
  `trigger_folder_id`  INT UNSIGNED NULL,
  `is_active`          TINYINT(1) NOT NULL DEFAULT 1,
  `created_by`         INT UNSIGNED NOT NULL,
  `created_at`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_wf_doctype` FOREIGN KEY (`trigger_doc_type_id`) REFERENCES `document_types`(`id`),
  CONSTRAINT `fk_wf_folder`  FOREIGN KEY (`trigger_folder_id`) REFERENCES `folders`(`id`),
  CONSTRAINT `fk_wf_creator` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`)
) ENGINE=InnoDB;

CREATE TABLE `workflow_steps` (
  `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `workflow_id` INT UNSIGNED NOT NULL,
  `step_order`  SMALLINT UNSIGNED NOT NULL,
  `step_name`   VARCHAR(150) NOT NULL,
  `role_id`     INT UNSIGNED NOT NULL,
  `sla_days`    SMALLINT UNSIGNED NOT NULL DEFAULT 2,
  -- NULL = escalate to Records Manager (the default governance role) once
  -- this step's approval has been pending longer than sla_days.
  `escalation_role_id` INT UNSIGNED NULL,
  -- When set, reaching this step starts an instance of the referenced
  -- workflow against the same document instead of assigning `role_id` a
  -- human approval directly; this step's own advancement waits for that
  -- child instance to reach a terminal state. `role_id` is still required
  -- by the column above but is ignored for a step configured this way.
  `sub_workflow_id`    INT UNSIGNED NULL,
  CONSTRAINT `fk_wfs_workflow`   FOREIGN KEY (`workflow_id`) REFERENCES `workflows`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_wfs_role`       FOREIGN KEY (`role_id`) REFERENCES `roles`(`id`),
  CONSTRAINT `fk_wfs_esc_role`   FOREIGN KEY (`escalation_role_id`) REFERENCES `roles`(`id`),
  CONSTRAINT `fk_wfs_subwf`      FOREIGN KEY (`sub_workflow_id`) REFERENCES `workflows`(`id`),
  UNIQUE KEY `uq_wf_step_order` (`workflow_id`, `step_order`)
) ENGINE=InnoDB;

CREATE TABLE `document_workflow_instances` (
  `id`             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `document_id`    INT UNSIGNED NOT NULL,
  `workflow_id`    INT UNSIGNED NOT NULL,
  `current_step_id` INT UNSIGNED NULL,
  `status`         ENUM('in_progress','approved','rejected','cancelled') NOT NULL DEFAULT 'in_progress',
  -- Self-reference: set when this instance exists only to satisfy a
  -- sub_workflow_id step of another (parent) instance — see
  -- workflow_steps.sub_workflow_id. A sub-workflow step has no human
  -- approver, so this links to the parent INSTANCE (which is "sitting" at
  -- that step via its own current_step_id) rather than a workflow_approvals
  -- row, which always requires a non-null approver_id.
  `parent_instance_id` BIGINT UNSIGNED NULL,
  `started_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at`   DATETIME NULL,
  CONSTRAINT `fk_dwi_document` FOREIGN KEY (`document_id`) REFERENCES `documents`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_dwi_workflow` FOREIGN KEY (`workflow_id`) REFERENCES `workflows`(`id`),
  CONSTRAINT `fk_dwi_step`     FOREIGN KEY (`current_step_id`) REFERENCES `workflow_steps`(`id`),
  CONSTRAINT `fk_dwi_parent_instance` FOREIGN KEY (`parent_instance_id`) REFERENCES `document_workflow_instances`(`id`)
) ENGINE=InnoDB;

CREATE TABLE `workflow_approvals` (
  `id`             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `instance_id`    BIGINT UNSIGNED NOT NULL,
  `step_id`        INT UNSIGNED NOT NULL,
  `approver_id`    INT UNSIGNED NOT NULL,
  `decision`       ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `comment`        VARCHAR(500) NULL,
  `decided_at`     DATETIME NULL,
  -- Set by the escalation scheduler (services/workflow/scheduler.js) the
  -- first time this pending approval is found overdue against its step's
  -- sla_days, so it's only ever escalated once.
  `escalated_at`   DATETIME NULL,
  `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_appr_instance` FOREIGN KEY (`instance_id`) REFERENCES `document_workflow_instances`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_appr_step`     FOREIGN KEY (`step_id`) REFERENCES `workflow_steps`(`id`),
  CONSTRAINT `fk_appr_user`     FOREIGN KEY (`approver_id`) REFERENCES `users`(`id`)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 6. AUDIT TRAIL (append-only, hash-chained for tamper evidence)
-- ---------------------------------------------------------------------

CREATE TABLE `audit_log` (
  `id`            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`       INT UNSIGNED NULL,
  `action`        ENUM('View','Edit','Approve','Capture','Download','Permission','Login','Login failed',
                        'Integration','Declare record','Disposal','Create','Delete','MFA','Logout',
                        'Backup','Restore') NOT NULL,
  `record_type`   VARCHAR(60) NULL,     -- document, folder, user, workflow, integration ...
  `record_id`     VARCHAR(60) NULL,
  `detail`        VARCHAR(500) NULL,
  `ip_address`    VARCHAR(45) NULL,
  `user_agent`    VARCHAR(255) NULL,
  `prev_hash`     CHAR(64) NULL,
  `entry_hash`    CHAR(64) NOT NULL,    -- sha256(prev_hash + canonical(this row)) — verifies chain integrity
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_audit_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL,
  INDEX `ix_audit_created` (`created_at`),
  INDEX `ix_audit_record` (`record_type`, `record_id`)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 7. NOTIFICATIONS
-- ---------------------------------------------------------------------

CREATE TABLE `notifications` (
  `id`             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`        INT UNSIGNED NOT NULL,
  `type`           VARCHAR(60) NOT NULL,   -- approval_pending, workflow_sla_breach, document_shared ...
  `title`          VARCHAR(190) NOT NULL,
  `body`           VARCHAR(500) NULL,
  `related_record_type` VARCHAR(60) NULL,
  `related_record_id`   VARCHAR(60) NULL,
  `is_read`        TINYINT(1) NOT NULL DEFAULT 0,
  `created_at`      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_notif_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 8. INTEGRATIONS & CAPTURE
-- ---------------------------------------------------------------------

CREATE TABLE `integrations` (
  `id`            VARCHAR(30) PRIMARY KEY,     -- 'ad', 'hris', 'smtp', 'aws_s3', 'azure_blob', 'gcp_storage', 'sms'
  `name`          VARCHAR(150) NOT NULL,
  `description`   VARCHAR(255) NULL,
  `endpoint`      VARCHAR(255) NULL,
  `status`        ENUM('connected','disconnected','error') NOT NULL DEFAULT 'disconnected',
  `config_json`   JSON NULL,                   -- non-secret config only; secrets stay in env/.env
  `last_sync_at`  DATETIME NULL,
  `stats_json`    JSON NULL,
  `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE `capture_batches` (
  `id`             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `batch_no`       VARCHAR(40) NOT NULL UNIQUE,
  `source`         ENUM('network_scanner','watched_folder','email_intake','device_upload','manual_upload','ftp') NOT NULL,
  `status`         ENUM('running','completed','completed_with_errors','failed') NOT NULL DEFAULT 'completed',
  `pages`          INT UNSIGNED NOT NULL DEFAULT 0,
  `documents`      INT UNSIGNED NOT NULL DEFAULT 0,
  `success_rate`   DECIMAL(5,2) NOT NULL DEFAULT 0.00,
  `started_at`     DATETIME NULL,
  `completed_at`   DATETIME NULL,
  `created_by`     INT UNSIGNED NULL,
  `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_batch_creator` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`)
) ENGINE=InnoDB;

-- Per-file outcome within a batch — links a batch to the real documents it
-- produced (or records why a file failed), without needing a column on
-- `documents` itself.
CREATE TABLE `capture_batch_items` (
  `id`                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `batch_id`          INT UNSIGNED NOT NULL,
  `source_file_name`  VARCHAR(255) NOT NULL,
  `status`            ENUM('succeeded','failed','duplicate') NOT NULL,
  `document_id`       INT UNSIGNED NULL,
  `error_message`     VARCHAR(500) NULL,
  `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_batch_item_batch` FOREIGN KEY (`batch_id`) REFERENCES `capture_batches`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_batch_item_document` FOREIGN KEY (`document_id`) REFERENCES `documents`(`id`) ON DELETE SET NULL,
  INDEX `ix_batch_item_batch` (`batch_id`)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 9. SYSTEM SETTINGS
-- ---------------------------------------------------------------------

CREATE TABLE `system_settings` (
  `setting_key`   VARCHAR(80) PRIMARY KEY,
  `setting_value` VARCHAR(500) NULL,
  `description`   VARCHAR(255) NULL,
  `updated_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Per-user appearance/UX preferences — deliberately separate from
-- system_settings (which is global), so theme etc. is per-person.
CREATE TABLE `user_preferences` (
  `user_id`      INT UNSIGNED PRIMARY KEY,
  `theme_mode`   ENUM('system','light','dark') NOT NULL DEFAULT 'system',
  `density`      ENUM('comfortable','compact') NOT NULL DEFAULT 'comfortable',
  `updated_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_prefs_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 10. BACKUP & DISASTER RECOVERY
-- ---------------------------------------------------------------------

CREATE TABLE `backups` (
  `id`               INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `file_key`         VARCHAR(255) NOT NULL,      -- storage key/path of the encrypted archive
  `size_bytes`       BIGINT UNSIGNED NULL,
  `storage_provider` VARCHAR(30) NOT NULL,
  `status`           ENUM('running','completed','failed') NOT NULL DEFAULT 'running',
  `error_message`    VARCHAR(500) NULL,
  -- Envelope-encryption key material (same AES-256-GCM scheme as document_encryption_keys),
  -- stored here directly since a backup archive isn't a document_version.
  `wrapped_dek`      VARBINARY(255) NULL,
  `dek_iv`           VARBINARY(32) NULL,
  `dek_auth_tag`     VARBINARY(32) NULL,
  `file_iv`          VARBINARY(32) NULL,
  `file_auth_tag`    VARBINARY(32) NULL,
  `checksum_sha256`  CHAR(64) NULL,
  `created_by`       INT UNSIGNED NULL,
  `created_at`       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at`     DATETIME NULL,
  CONSTRAINT `fk_backup_creator` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`)
) ENGINE=InnoDB;

-- =====================================================================
-- SEED DATA
-- =====================================================================

INSERT INTO `departments` (`name`, `description`) VALUES
('Benefits', 'Pension claims and benefit processing'),
('Finance', 'Contributions, payouts and treasury'),
('Records Management', 'Registry, retention and disposal'),
('ICT', 'Systems and integrations'),
('Human Resources', 'Staff administration');

INSERT INTO `roles` (`name`, `description`, `mfa_required`, `is_system_role`) VALUES
('Records Officer', 'Captures and indexes records', 0, 0),
('Approving Manager', 'Approves claims and workflow steps', 1, 0),
('Finance Officer', 'Handles payouts and contributions', 1, 0),
('Records Manager', 'Owns retention schedules and ACL exceptions', 1, 1),
('System Administrator', 'Full system configuration access', 1, 1),
('Internal Auditor', 'Read-only access to audit trail and reports', 1, 0);

INSERT INTO `document_types` (`name`, `code`) VALUES
('Claim — Retirement', 'PC'),
('Claim — Ill Health', 'IH'),
('Contribution Statement', 'CS'),
('Payout Voucher', 'PV'),
('Member Statement', 'MS'),
('Imported / Unclassified', 'IMP');

INSERT INTO `retention_classes` (`code`, `name`, `retention_years`, `trigger_event`, `disposal_action`) VALUES
('RC-CLAIM-7', 'Pension claim records', 7, 'record declared final', 'transfer_to_national_archives'),
('RC-CONTRIB-10', 'Contribution records', 10, 'record declared final', 'archive'),
('RC-PAYOUT-7', 'Payout records', 7, 'record declared final', 'archive'),
('RC-GOV-PERM', 'Governance / permanent records', 99, 'record declared final', 'review');

INSERT INTO `integrations` (`id`, `name`, `description`, `endpoint`, `status`) VALUES
('hris', 'HRIS — Government Payroll', 'Member service records & exits', 'sftp://payroll.gov.sz/exports', 'connected'),
('smtp', 'E-mail & notifications', 'Approval alerts, statement delivery', 'smtp.pspf.co.sz:587', 'connected'),
('aws_s3', 'AWS S3', 'Primary encrypted document store', NULL, 'disconnected'),
('azure_blob', 'Azure Blob Storage', 'Secondary / DR document store', NULL, 'disconnected'),
('gcp_storage', 'Google Cloud Storage', 'Alternate document store', NULL, 'disconnected'),
('local', 'Local disk (dev)', 'Filesystem fallback for local/XAMPP development', NULL, 'connected');

-- Active Directory: config_json holds real (non-secret) LDAP connection
-- settings read by services/ad.service.js; the service-account bind
-- password lives in .env as AD_BIND_PASSWORD, never in this table (same
-- convention as FTP_INTAKE_PASSWORD/IMAP_INTAKE_PASSWORD below).
INSERT INTO `integrations` (`id`, `name`, `description`, `endpoint`, `status`, `config_json`) VALUES
('ad', 'Active Directory', 'Single sign-on & group membership', 'ldaps://dc01.pspf.local:636', 'disconnected',
 '{"url": "ldaps://dc01.pspf.local:636", "bindDN": "", "searchBase": "dc=pspf,dc=local", "searchFilter": "(&(objectClass=user)(mail={{email}}))", "tlsRejectUnauthorized": true, "enabled": false}');

-- SMS (Vonage): config_json holds only the non-secret sender id; the API
-- key/secret live in .env as VONAGE_API_KEY/VONAGE_API_SECRET, never in
-- this table (same convention as AD_BIND_PASSWORD above).
INSERT INTO `integrations` (`id`, `name`, `description`, `endpoint`, `status`, `config_json`) VALUES
('sms', 'SMS Gateway (Vonage)', 'MFA one-time codes and alert delivery', 'rest.nexmo.com', 'disconnected',
 '{"provider": "vonage", "from": "PSPFEDMS", "enabled": true}');

-- Automated Capture & Scan intake connectors. `config_json` holds
-- non-secret settings (poll target/interval/enabled); real credentials
-- (FTP/IMAP passwords) live in .env as FTP_INTAKE_PASSWORD /
-- IMAP_INTAKE_PASSWORD, never in this table. ids match capture_batches.source.
INSERT INTO `integrations` (`id`, `name`, `description`, `endpoint`, `status`, `config_json`) VALUES
('watched_folder', 'Watched Folder', 'Auto-captures files dropped into a local intake directory - also the landing point for a network scanner''s "scan to folder" feature', NULL, 'disconnected', '{"path": "", "pollIntervalSeconds": 20, "enabled": true}'),
('ftp', 'FTP Intake', 'Polls a remote FTP/SFTP directory for new documents', NULL, 'disconnected', '{"host": "", "port": 21, "user": "", "path": "/", "pollIntervalMinutes": 15, "enabled": false}'),
('email_intake', 'Email Intake', 'Polls a mailbox for new messages with attachments - also the landing point for a network scanner''s "scan to email" feature', NULL, 'disconnected', '{"host": "", "port": 993, "user": "", "mailbox": "INBOX", "pollIntervalMinutes": 10, "enabled": false}');

INSERT INTO `key_encryption_keys` (`kek_version`, `provider`, `is_active`) VALUES
('kek-local-dev-1', 'env', 1);

INSERT INTO `system_settings` (`setting_key`, `setting_value`, `description`) VALUES
('watermark_downloads', 'true', 'Watermark every download with user and timestamp'),
('redact_bank_numbers', 'true', 'Mask bank account numbers for non-Finance roles'),
('bulk_export_limit', '500', 'Block bulk export above this many records without override'),
('confidential_reason_required', 'true', 'Confidential records require a stated reason to open'),
('active_storage_provider', 'aws_s3', 'Default cloud storage provider for new uploads'),
('backup_schedule_enabled', 'false', 'Run an automatic nightly database backup'),
('backup_schedule_hour', '2', 'Hour of day (0-23, server local time) the automatic nightly backup runs'),
('storage_capacity_bytes', '107374182400', 'Total provisioned storage capacity in bytes, shown on the Dashboard (default 100 GB)');

-- Role x module permission matrix. `module` = dashboard, repository, capture,
-- search, versions, viewer, permissions, security, users, departments,
-- settings, backup, workflow, integrations, reports, audit, retention, approvals.
-- `backup` is listed here for visibility in the Permissions Matrix UI only —
-- the backup/restore routes themselves stay hard-gated to System
-- Administrator regardless of this table, given the blast radius.
INSERT INTO `role_module_permissions` (`role_id`, `module`, `can_view`, `can_edit`) VALUES
((SELECT id FROM roles WHERE name = 'Records Officer'), 'approvals', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Officer'), 'capture', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Officer'), 'repository', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Officer'), 'versions', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Officer'), 'viewer', 1, 1),

((SELECT id FROM roles WHERE name = 'Approving Manager'), 'approvals', 1, 1),
((SELECT id FROM roles WHERE name = 'Approving Manager'), 'reports', 1, 0),
((SELECT id FROM roles WHERE name = 'Approving Manager'), 'repository', 1, 0),
((SELECT id FROM roles WHERE name = 'Approving Manager'), 'viewer', 1, 0),

((SELECT id FROM roles WHERE name = 'Finance Officer'), 'approvals', 1, 1),
((SELECT id FROM roles WHERE name = 'Finance Officer'), 'reports', 1, 0),
((SELECT id FROM roles WHERE name = 'Finance Officer'), 'repository', 1, 0),
((SELECT id FROM roles WHERE name = 'Finance Officer'), 'viewer', 1, 0),

((SELECT id FROM roles WHERE name = 'Records Manager'), 'audit', 1, 0),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'permissions', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'reports', 1, 0),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'repository', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'retention', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'versions', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'viewer', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'workflow', 1, 1),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'users', 1, 0),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'departments', 1, 0),
((SELECT id FROM roles WHERE name = 'Records Manager'), 'settings', 1, 0),

((SELECT id FROM roles WHERE name = 'Internal Auditor'), 'audit', 1, 0),
((SELECT id FROM roles WHERE name = 'Internal Auditor'), 'reports', 1, 0),
((SELECT id FROM roles WHERE name = 'Internal Auditor'), 'repository', 1, 0),
((SELECT id FROM roles WHERE name = 'Internal Auditor'), 'viewer', 1, 0),

((SELECT id FROM roles WHERE name = 'System Administrator'), 'approvals', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'audit', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'capture', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'integrations', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'permissions', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'reports', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'repository', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'retention', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'versions', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'viewer', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'workflow', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'users', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'departments', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'settings', 1, 1),
((SELECT id FROM roles WHERE name = 'System Administrator'), 'backup', 1, 1);

SET FOREIGN_KEY_CHECKS = 1;
