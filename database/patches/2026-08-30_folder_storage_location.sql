-- Patch: per-folder default storage location (backend/routes/folders.routes.js,
-- consumed by backend/services/document.service.js's registerDocument as a
-- fallback below an explicit per-upload override and above the globally
-- active provider).
--
-- Source of truth is database/pspf_edms_schema.sql (already updated) and
-- backend/scripts/migrate-folder-storage-location.js (the idempotent Node
-- version of this same patch). This file is the same statement in plain
-- SQL for pasting directly into phpMyAdmin against an existing production
-- database.
--
-- Run once. If it errors with "Duplicate column name", it's already applied.

ALTER TABLE `folders`
  ADD COLUMN `storage_provider_id` VARCHAR(30) NULL,
  ADD COLUMN `storage_prefix` VARCHAR(255) NULL,
  ADD CONSTRAINT `fk_folder_storage` FOREIGN KEY (`storage_provider_id`) REFERENCES `integrations`(`id`) ON DELETE SET NULL;
