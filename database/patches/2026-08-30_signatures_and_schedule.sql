-- Patch: per-user signatures (Settings -> My Signature), signature-required
-- workflow steps, and scheduled/recurring workflow triggers.
--
-- Source of truth is database/pspf_edms_schema.sql (already updated) and
-- backend/scripts/migrate-signatures-and-schedule.js (the idempotent Node
-- version of this same patch, for a fresh checkout run via `node
-- scripts/migrate-signatures-and-schedule.js`). This file is the same
-- statements in plain SQL for pasting directly into phpMyAdmin against an
-- existing production database.
--
-- Run once. If a statement errors with "Duplicate column name" or "Table
-- already exists", that piece has already been applied — skip it and run
-- the remaining statements individually.

ALTER TABLE `workflow_steps`
  ADD COLUMN `requires_signature` TINYINT(1) NOT NULL DEFAULT 0;

ALTER TABLE `workflows`
  ADD COLUMN `schedule_enabled` TINYINT(1) NOT NULL DEFAULT 0,
  ADD COLUMN `schedule_target_document_id` INT UNSIGNED NULL,
  ADD COLUMN `schedule_start_at` DATETIME NULL,
  ADD COLUMN `schedule_recurrence` ENUM('once','daily','weekly','monthly','yearly') NULL,
  ADD COLUMN `schedule_end_at` DATETIME NULL,
  ADD COLUMN `schedule_next_run_at` DATETIME NULL,
  ADD CONSTRAINT `fk_wf_schedule_doc` FOREIGN KEY (`schedule_target_document_id`) REFERENCES `documents`(`id`) ON DELETE SET NULL,
  ADD INDEX `ix_wf_schedule_due` (`schedule_enabled`, `schedule_next_run_at`);

CREATE TABLE `user_signatures` (
  `user_id`               INT UNSIGNED PRIMARY KEY,
  `company_id`            INT UNSIGNED NOT NULL,
  `encrypted_image`       MEDIUMBLOB NOT NULL,
  `key_encryption_key_id` INT UNSIGNED NOT NULL,
  `wrapped_dek`           VARBINARY(512) NOT NULL,
  `dek_iv`                VARBINARY(32) NOT NULL,
  `dek_auth_tag`          VARBINARY(32) NOT NULL,
  `file_iv`               VARBINARY(32) NOT NULL,
  `file_auth_tag`         VARBINARY(32) NOT NULL,
  `checksum_sha256`       CHAR(64) NOT NULL,
  `content_type`          VARCHAR(50) NOT NULL DEFAULT 'image/png',
  `created_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT `fk_sig_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_sig_kek`  FOREIGN KEY (`key_encryption_key_id`) REFERENCES `key_encryption_keys`(`id`)
) ENGINE=InnoDB;

CREATE TABLE `workflow_approval_signatures` (
  `id`                    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `company_id`            INT UNSIGNED NOT NULL,
  `approval_id`           BIGINT UNSIGNED NOT NULL UNIQUE,
  `encrypted_image`       MEDIUMBLOB NOT NULL,
  `key_encryption_key_id` INT UNSIGNED NOT NULL,
  `wrapped_dek`           VARBINARY(512) NOT NULL,
  `dek_iv`                VARBINARY(32) NOT NULL,
  `dek_auth_tag`          VARBINARY(32) NOT NULL,
  `file_iv`               VARBINARY(32) NOT NULL,
  `file_auth_tag`         VARBINARY(32) NOT NULL,
  `created_at`            DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_wfas_approval` FOREIGN KEY (`approval_id`) REFERENCES `workflow_approvals`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_wfas_kek`      FOREIGN KEY (`key_encryption_key_id`) REFERENCES `key_encryption_keys`(`id`)
) ENGINE=InnoDB;
