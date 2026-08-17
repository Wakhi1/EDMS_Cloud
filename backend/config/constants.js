/**
 * config/constants.js
 * Shared enums/constants kept in one place so routes and services never
 * hardcode magic strings.
 */
module.exports = {
  PERMISSION_LEVELS: ['view', 'comment', 'edit', 'approve', 'full_control'],
  TARGET_TYPES: ['folder', 'document'],
  PRINCIPAL_TYPES: ['user', 'group'],
  DOCUMENT_STATUS: [
    'draft', 'pending_approval', 'approved', 'rejected',
    'declared_final', 'archived', 'disposed',
  ],
  CLASSIFICATIONS: ['public', 'internal', 'restricted', 'confidential'],
  AUDIT_ACTIONS: [
    'View', 'Edit', 'Approve', 'Capture', 'Download', 'Permission',
    'Login', 'Login failed', 'Integration', 'Declare record', 'Disposal',
    'Create', 'Delete', 'MFA', 'Logout',
  ],
  STORAGE_PROVIDERS: ['aws_s3', 'azure_blob', 'gcp_storage', 'local'],
};
