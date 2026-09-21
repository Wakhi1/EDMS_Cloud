-- Patch: per-version page count (backend/services/pageCount.service.js,
-- written by document.service.js / versions.routes.js / import.service.js
-- and shown in the Repository, Viewer and Versions screens).
-- page_count_estimated = 1 marks counts computed from text length (plain
-- text, .docx files with no Pages figure) rather than read from the file.
--
-- Source of truth is database/pspf_edms_schema.sql (already updated) and
-- backend/scripts/migrate-page-count.js (the idempotent Node version of this
-- same patch, which also backfills existing versions). This file is the same
-- statement in plain SQL for pasting directly into phpMyAdmin against an
-- existing production database — run backend/scripts/migrate-page-count.js
-- afterwards (or instead) to fill in page counts for already-stored documents.
--
-- Run once. If it errors with "Duplicate column name", it's already applied.

ALTER TABLE `document_versions`
  ADD COLUMN `page_count` INT UNSIGNED NULL AFTER `size_bytes`,
  ADD COLUMN `page_count_estimated` TINYINT(1) NOT NULL DEFAULT 0 AFTER `page_count`;
