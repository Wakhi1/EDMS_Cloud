-- =====================================================================
-- Migration 002 — API versioning (/api -> /api/v1) + more sandbox
-- environment options out of the box.
--
-- Run this against an existing pspf_edms_docs database (created before
-- this migration existed). Safe to re-run — it only touches rows it
-- recognises by name/URL.
-- =====================================================================

USE `pspf_edms_docs`;

-- Update the existing local environment's base_url to include the new
-- /v1 segment, if it's still on the old unversioned path.
UPDATE `sandbox_environments`
SET `base_url` = 'http://localhost:4000/api/v1'
WHERE `base_url` = 'http://localhost:4000/api';

-- Add the additional environment options, only if they don't already exist.
INSERT INTO `sandbox_environments` (`name`, `base_url`, `is_default`)
SELECT 'Local (Docker Compose)', 'http://edms-api:4000/api/v1', 0
WHERE NOT EXISTS (SELECT 1 FROM `sandbox_environments` WHERE `name` = 'Local (Docker Compose)');

INSERT INTO `sandbox_environments` (`name`, `base_url`, `is_default`)
SELECT 'Staging', 'https://staging-api.pspf.co.sz/api/v1', 0
WHERE NOT EXISTS (SELECT 1 FROM `sandbox_environments` WHERE `name` = 'Staging');

INSERT INTO `sandbox_environments` (`name`, `base_url`, `is_default`)
SELECT 'Production', 'https://api.pspf.co.sz/api/v1', 0
WHERE NOT EXISTS (SELECT 1 FROM `sandbox_environments` WHERE `name` = 'Production');
