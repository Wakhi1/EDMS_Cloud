-- Patch: per-storage-location capacity settings for the Dashboard's
-- "Storage by location" card (backend/routes/dashboard.routes.js). Edited in
-- Settings -> System Settings; '0' means "not set" (local disk then falls
-- back to the size of the disk it lives on).
--
-- Source of truth is database/pspf_edms_schema.sql (already updated) and
-- backend/scripts/migrate-storage-capacity-settings.js (the idempotent Node
-- version of this same patch). Safe to run more than once (INSERT IGNORE).

INSERT IGNORE INTO `system_settings` (`setting_key`, `company_id`, `setting_value`, `description`) VALUES
('storage_capacity_bytes_local', 1, '0', 'Capacity in bytes of the Local disk storage location, shown on the Dashboard (0 = use the disk''s own size)'),
('storage_capacity_bytes_aws_s3', 1, '0', 'Provisioned capacity in bytes of the AWS S3 storage location, shown on the Dashboard (0 = not set)'),
('storage_capacity_bytes_azure_blob', 1, '0', 'Provisioned capacity in bytes of the Azure Blob storage location, shown on the Dashboard (0 = not set)'),
('storage_capacity_bytes_gcp_storage', 1, '0', 'Provisioned capacity in bytes of the Google Cloud Storage location, shown on the Dashboard (0 = not set)');
