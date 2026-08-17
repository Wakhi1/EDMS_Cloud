/// The four storage-type integration ids — mirrors
/// `backend/services/storage/storage.service.js`'s `providers` map keys.
/// Shared between the Integrations screen (admin storage-location switcher)
/// and Smart Upload (per-batch storage-location picker).
const kStorageProviderIds = <String>['local', 'aws_s3', 'azure_blob', 'gcp_storage'];
