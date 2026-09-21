  -- Patch: per-user workflow-step targeting, per-document watermark override,
  -- and the api_keys table backing the local watched-folder agent
  -- (backend/routes/agentUpload.routes.js).
  --
  -- Source of truth is database/pspf_edms_schema.sql (already updated) and
  -- backend/scripts/migrate-agent-and-targeting.js (the idempotent Node
  -- version of this same patch, for a fresh checkout run via `node
  -- scripts/migrate-agent-and-targeting.js`). This file is the same three
  -- statements in plain SQL for pasting directly into phpMyAdmin against an
  -- existing production database.
  --
  -- Run once. If a statement errors with "Duplicate column name" or "Table
  -- already exists", that piece has already been applied — skip it and run
  -- the remaining statements individually.

  ALTER TABLE `workflow_steps`
    ADD COLUMN `assignee_user_id` INT UNSIGNED NULL AFTER `role_id`,
    ADD CONSTRAINT `fk_wfs_assignee` FOREIGN KEY (`assignee_user_id`) REFERENCES `users`(`id`);

  ALTER TABLE `documents`
    ADD COLUMN `watermark_mode` ENUM('inherit','on','off') NOT NULL DEFAULT 'inherit' AFTER `classification`;

  CREATE TABLE `api_keys` (
    `id`            BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `company_id`    INT UNSIGNED NOT NULL,
    `name`          VARCHAR(150) NOT NULL,
    `key_prefix`    VARCHAR(12) NOT NULL,
    `key_hash`      CHAR(64) NOT NULL,
    `scope`         VARCHAR(50) NOT NULL DEFAULT 'capture_upload',
    `created_by`    INT UNSIGNED NOT NULL,
    `last_used_at`  DATETIME NULL,
    `revoked_at`    DATETIME NULL,
    `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY `uq_api_key_hash` (`key_hash`),
    CONSTRAINT `fk_apikey_creator` FOREIGN KEY (`created_by`) REFERENCES `users`(`id`),
    INDEX `ix_apikey_company` (`company_id`)
  ) ENGINE=InnoDB;
