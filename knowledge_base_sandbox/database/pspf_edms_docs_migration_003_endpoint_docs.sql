-- =====================================================================
-- Migration 003 — adds structured per-endpoint API reference data
-- (parameters, request body fields, example responses) so the Sandbox
-- can render a real documentation tab per request, not just the free
-- -text description that was there before.
--
-- Run this, then re-run `npm run import:postman` (or
-- `node scripts/import-postman.js`) to populate doc_json for every
-- endpoint from the manifest in scripts/endpoint-docs.js — the import
-- is what actually fills this column in; the ALTER just makes room
-- for it.
-- =====================================================================

USE `pspf_edms_docs`;

ALTER TABLE `sandbox_requests`
  ADD COLUMN `doc_json` JSON NULL
  COMMENT 'Structured API reference: { summary, parameters:[{name,in,type,required,description}], requestBody:{fields:[{name,type,required,description}]}, responses:[{status,description,example}] }'
  AFTER `has_file_upload`;
