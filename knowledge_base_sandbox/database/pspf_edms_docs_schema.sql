-- =====================================================================
-- PSPF EDMS Documentation Portal — database schema (MySQL 5.7+/8,
-- InnoDB, utf8mb4) — XAMPP/phpMyAdmin ready.
--
-- This is a SEPARATE database from the EDMS itself (pspf_edms) — the
-- docs portal is a standalone product that happens to test against the
-- EDMS API, not a module bolted onto it.
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

CREATE DATABASE IF NOT EXISTS `pspf_edms_docs`
  DEFAULT CHARACTER SET utf8mb4 DEFAULT COLLATE utf8mb4_unicode_ci;
USE `pspf_edms_docs`;

-- ---------------------------------------------------------------------
-- 1. ACCOUNTS
-- ---------------------------------------------------------------------

CREATE TABLE `users` (
  `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `full_name`     VARCHAR(150) NOT NULL,
  `email`         VARCHAR(190) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `role`          ENUM('admin','developer') NOT NULL DEFAULT 'developer',
  `status`        ENUM('pending','approved','rejected','suspended') NOT NULL DEFAULT 'pending',
  `company`       VARCHAR(150) NULL,
  `reason`        VARCHAR(500) NULL COMMENT 'Why they want sandbox access — shown to admin at approval time',
  `approved_by`   INT UNSIGNED NULL,
  `approved_at`   DATETIME NULL,
  `created_at`    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_users_approver` FOREIGN KEY (`approved_by`) REFERENCES `users`(`id`)
) ENGINE=InnoDB;

CREATE TABLE `user_sessions` (
  `id`                 CHAR(36) PRIMARY KEY,
  `user_id`            INT UNSIGNED NOT NULL,
  `refresh_token_hash` CHAR(64) NOT NULL,
  `user_agent`         VARCHAR(255) NULL,
  `ip_address`         VARCHAR(45) NULL,
  `expires_at`         DATETIME NOT NULL,
  `revoked_at`         DATETIME NULL,
  `created_at`         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_session_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Sandbox credentials. Admin-issued only (developers cannot self-serve
-- a key) — matches "admin approving developer account and granting
-- them developer credentials". Plaintext key is shown exactly once at
-- creation; only its hash + a display prefix are stored.
CREATE TABLE `api_keys` (
  `id`           INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`      INT UNSIGNED NOT NULL,
  `label`        VARCHAR(100) NOT NULL DEFAULT 'Sandbox key',
  `key_prefix`   CHAR(8) NOT NULL COMMENT 'First 8 chars, shown in the UI so a key is identifiable without re-exposing it',
  `key_hash`     CHAR(64) NOT NULL COMMENT 'sha256 of the full key',
  `issued_by`    INT UNSIGNED NOT NULL,
  `last_used_at` DATETIME NULL,
  `revoked_at`   DATETIME NULL,
  `created_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_key_user`   FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_key_issuer` FOREIGN KEY (`issued_by`) REFERENCES `users`(`id`),
  UNIQUE KEY `uq_key_hash` (`key_hash`)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 2. MEDIA LIBRARY (admin-uploaded images / videos / documents
--    referenced from .md pages)
-- ---------------------------------------------------------------------

CREATE TABLE `media_assets` (
  `id`            INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `original_name` VARCHAR(255) NOT NULL,
  `stored_name`   VARCHAR(255) NOT NULL UNIQUE COMMENT 'UUID-based filename on disk, under backend/uploads/',
  `mime_type`     VARCHAR(120) NOT NULL,
  `kind`          ENUM('image','video','document','other') NOT NULL,
  `size_bytes`    BIGINT UNSIGNED NOT NULL,
  `alt_text`      VARCHAR(255) NULL,
  `uploaded_by`   INT UNSIGNED NOT NULL,
  `uploaded_at`   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_media_uploader` FOREIGN KEY (`uploaded_by`) REFERENCES `users`(`id`)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 3. SANDBOX CATALOG (imported from the EDMS Postman collection —
--    see backend/scripts/import-postman.js — so every request you can
--    run in Postman is also runnable here, without Postman)
-- ---------------------------------------------------------------------

CREATE TABLE `sandbox_environments` (
  `id`         INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`       VARCHAR(100) NOT NULL,
  `base_url`   VARCHAR(255) NOT NULL COMMENT 'e.g. http://localhost:4000/api — the ONLY thing that decides where a sandbox call actually goes; never taken from the client, so this can''t become an open proxy',
  `is_default` TINYINT(1) NOT NULL DEFAULT 0,
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE `sandbox_folders` (
  `id`          INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `name`        VARCHAR(150) NOT NULL,
  `description` TEXT NULL,
  `sort_order`  INT UNSIGNED NOT NULL DEFAULT 0
) ENGINE=InnoDB;

CREATE TABLE `sandbox_requests` (
  `id`                INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `folder_id`         INT UNSIGNED NOT NULL,
  `name`              VARCHAR(150) NOT NULL,
  `method`             ENUM('GET','POST','PUT','PATCH','DELETE') NOT NULL,
  `path`               VARCHAR(255) NOT NULL COMMENT 'Relative to the chosen environment''s base_url, e.g. /auth/login',
  `description`        TEXT NULL,
  `auth_type`           ENUM('none','bearer','mfa_token') NOT NULL DEFAULT 'none',
  `default_headers_json` JSON NULL,
  `default_query_json`   JSON NULL,
  `default_body_json`    JSON NULL,
  `has_file_upload`      TINYINT(1) NOT NULL DEFAULT 0,
  `doc_json`              JSON NULL COMMENT 'Structured API reference: { summary, parameters:[{name,in,type,required,description}], requestBody:{fields:[{name,type,required,description}]}, responses:[{status,description,example}] } — rendered as a proper docs tab in the Sandbox, not just the free-text description above',
  `sort_order`           INT UNSIGNED NOT NULL DEFAULT 0,
  CONSTRAINT `fk_req_folder` FOREIGN KEY (`folder_id`) REFERENCES `sandbox_folders`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Per-developer variable panel (baseUrl override, accessToken,
-- documentId, etc.) — the browser substitutes {{these}} into a
-- request's path/headers/body before sending, same convention as the
-- Postman collection used, so copy-pasting between the two just works.
CREATE TABLE `sandbox_user_variables` (
  `user_id`    INT UNSIGNED NOT NULL,
  `var_key`    VARCHAR(80) NOT NULL,
  `var_value`  VARCHAR(1000) NULL,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`, `var_key`),
  CONSTRAINT `fk_var_user` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE `sandbox_request_logs` (
  `id`                BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `user_id`           INT UNSIGNED NOT NULL,
  `api_key_id`        INT UNSIGNED NOT NULL,
  `environment_id`    INT UNSIGNED NULL,
  `sandbox_request_id` INT UNSIGNED NULL,
  `method`            VARCHAR(10) NOT NULL,
  `path`              VARCHAR(255) NOT NULL,
  `status_code`       SMALLINT NULL,
  `duration_ms`       INT UNSIGNED NULL,
  `created_at`        DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_log_user`  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_log_key`   FOREIGN KEY (`api_key_id`) REFERENCES `api_keys`(`id`),
  CONSTRAINT `fk_log_env`   FOREIGN KEY (`environment_id`) REFERENCES `sandbox_environments`(`id`),
  CONSTRAINT `fk_log_req`   FOREIGN KEY (`sandbox_request_id`) REFERENCES `sandbox_requests`(`id`) ON DELETE SET NULL,
  INDEX `ix_log_user_time` (`user_id`, `created_at`)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- 4. AUDIT LOG (admin actions: approvals, key issuance/revocation,
--    uploads — separate, lightweight version of the EDMS's own audit
--    log, scoped to this portal)
-- ---------------------------------------------------------------------

CREATE TABLE `audit_log` (
  `id`             BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  `actor_user_id`  INT UNSIGNED NULL,
  `action`         VARCHAR(60) NOT NULL,
  `record_type`    VARCHAR(60) NULL,
  `record_id`      VARCHAR(60) NULL,
  `detail`         VARCHAR(500) NULL,
  `ip_address`     VARCHAR(45) NULL,
  `created_at`     DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT `fk_audit_actor` FOREIGN KEY (`actor_user_id`) REFERENCES `users`(`id`) ON DELETE SET NULL
) ENGINE=InnoDB;

-- =====================================================================
-- SEED DATA
-- =====================================================================

-- Admin login: admin@pspf-docs.local / ChangeMe123!
INSERT INTO `users` (`full_name`, `email`, `password_hash`, `role`, `status`, `approved_at`) VALUES
('Docs Portal Admin', 'admin@pspf-docs.local', '$2b$12$CLREstl293uoWpx7NmwD0OzECP.Ko8qH5w/M66.6dm5IFNRgrWjoe', 'admin', 'approved', NOW());

-- Seeded with several common deployment targets so an admin only has
-- to EDIT a base_url (Admin -> Environments) rather than create a row
-- from scratch. Only one is enabled/default at a time — see
-- DEPLOYMENT.md ("Pointing the sandbox at a real deployment") for
-- which of these to update once you actually deploy, and why
-- "localhost" only ever makes sense for the machine running the docs
-- portal's own Node process, never for anyone else testing against it.
INSERT INTO `sandbox_environments` (`name`, `base_url`, `is_default`) VALUES
('Local (XAMPP)', 'http://localhost:4000/api/v1', 1),
('Local (Docker Compose)', 'http://edms-api:4000/api/v1', 0),
('Staging', 'https://staging-api.pspf.co.sz/api/v1', 0),
('Production', 'https://api.pspf.co.sz/api/v1', 0);

SET FOREIGN_KEY_CHECKS = 1;
