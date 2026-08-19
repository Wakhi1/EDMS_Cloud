/// Backend route paths, mirroring backend/routes/*.routes.js 1:1. Phases
/// 1-6 populate auth, mfa, documents, folders, reports, approvals,
/// notifications, document-types, audit, retention, users, permissions,
/// and integrations, cross-checked against the matching *.routes.js file.
/// (workflow.routes.js and versions.routes.js endpoints are inlined
/// directly in resources/workflow_api.dart and resources/versions_api.dart
/// instead of here — a Phase 3 inconsistency, not worth churning now.)
class Endpoints {
  const Endpoints._();

  // auth.routes.js
  static const authRegister = '/api/auth/register';
  static const authLogin = '/api/auth/login';
  static const authRefresh = '/api/auth/refresh';
  static const authLogout = '/api/auth/logout';
  static const authGoogle = '/api/auth/google';
  static const authMicrosoft = '/api/auth/microsoft';
  static const authAd = '/api/auth/ad';
  static const authPasswordResetRequest = '/api/auth/password-reset/request';
  static const authPasswordResetConfirm = '/api/auth/password-reset/confirm';
  static const authMe = '/api/auth/me';

  // mfa.routes.js
  static const mfaStatus = '/api/mfa/status';
  static const mfaTotpEnroll = '/api/mfa/totp/enroll';
  static const mfaTotpConfirm = '/api/mfa/totp/confirm';
  static const mfaBackupCodesGenerate = '/api/mfa/backup-codes/generate';
  static const mfaChallengeSmsSend = '/api/mfa/challenge/sms/send';
  static const mfaChallengeEmailSend = '/api/mfa/challenge/email/send';
  static const mfaChallengeStatus = '/api/mfa/challenge/status';
  static const mfaChallengeTotpEnroll = '/api/mfa/challenge/totp/enroll';
  static const mfaChallengeTotpConfirm = '/api/mfa/challenge/totp/confirm';
  static const mfaVerifyTotp = '/api/mfa/verify/totp';
  static const mfaVerifyOtp = '/api/mfa/verify/otp';
  static const mfaVerifyBackupCode = '/api/mfa/verify/backup-code';

  // folders.routes.js
  static const folders = '/api/folders';
  static String folderById(String id) => '/api/folders/$id';

  // documents.routes.js
  static const documents = '/api/documents';
  static const documentsOcrPreview = '/api/documents/ocr-preview';
  static String documentById(String id) => '/api/documents/$id';
  static String documentContent(String id) => '/api/documents/$id/content';
  static String documentOcrText(String id) => '/api/documents/$id/ocr-text';
  static String documentDeclareFinal(String id) => '/api/documents/$id/declare-final';

  // document-types.routes.js
  static const documentTypes = '/api/document-types';
  static String documentTypeById(String id) => '/api/document-types/$id';

  // approvals.routes.js
  static const approvals = '/api/approvals';

  // notifications.routes.js
  static const notifications = '/api/notifications';
  static String notificationRead(String id) => '/api/notifications/$id/read';
  static const notificationsReadAll = '/api/notifications/read-all';

  // reports.routes.js
  static const reportsByStatus = '/api/reports/by-status';
  static const reportsByDepartment = '/api/reports/by-department';
  static const reportsByCategory = '/api/reports/by-category';
  static const reportsByFolder = '/api/reports/by-folder';
  static const reportsCapacity = '/api/reports/capacity';
  static const reportsByClassification = '/api/reports/by-classification';
  static const reportsCapturedOverTime = '/api/reports/captured-over-time';
  static const reportsCaptureBySource = '/api/reports/capture-by-source';
  static const reportsRetentionStatus = '/api/reports/retention-status';
  static const reportsTopUsers = '/api/reports/top-users';
  static const reportsClaimTurnaround = '/api/reports/claim-turnaround';
  static const reportsAuditActions = '/api/reports/audit-actions';

  // audit.routes.js
  static const audit = '/api/audit';
  static const auditExportCsv = '/api/audit/export.csv';
  static const auditVerifyChain = '/api/audit/verify-chain';
  static const auditRecordTypes = '/api/audit/record-types';

  // retention.routes.js
  static const retentionClasses = '/api/retention/classes';
  static String retentionClassById(String id) => '/api/retention/classes/$id';
  static const retentionDue = '/api/retention/due';
  static String retentionDispose(String documentId) => '/api/retention/$documentId/dispose';

  // users.routes.js
  static const users = '/api/users';
  static String userById(String id) => '/api/users/$id';
  static String userRole(String id) => '/api/users/$id/role';
  static String userLock(String id) => '/api/users/$id/lock';
  static String userDepartment(String id) => '/api/users/$id/department';
  static String userPassword(String id) => '/api/users/$id/password';
  static String userMfa(String id) => '/api/users/$id/mfa';
  static String userMfaReset(String id) => '/api/users/$id/mfa/reset';
  static const userGroups = '/api/users/groups/all';
  static String groupMembers(String groupId) => '/api/users/groups/$groupId/members';
  static const usersMe = '/api/users/me';
  static const usersMePassword = '/api/users/me/password';

  // roles.routes.js
  static const roles = '/api/roles';
  static String roleById(String id) => '/api/roles/$id';

  // permissions.routes.js
  static String permissionsFor(String targetType, String targetId) => '/api/permissions/$targetType/$targetId';
  static String permissionAclById(String aclId) => '/api/permissions/$aclId';
  static const permissionsMatrix = '/api/permissions/matrix/all';
  static const permissionsMatrixUpdate = '/api/permissions/matrix';

  // integrations.routes.js
  static const integrations = '/api/integrations';
  static String integrationById(String id) => '/api/integrations/$id';
  static const integrationStorageLocation = '/api/integrations/storage-location';
  static const integrationStorageOptions = '/api/integrations/storage-options';
  static String integrationTest(String id) => '/api/integrations/$id/test';
  static String integrationBrowse(String id) => '/api/integrations/$id/browse';
  static String integrationFolders(String id) => '/api/integrations/$id/folders';
  static String integrationImport(String id) => '/api/integrations/$id/import';

  // capture.routes.js
  static const captureBatches = '/api/capture-batches';
  static const captureBatchesSummary = '/api/capture-batches/summary';
  static const captureBatchesConnectorStatus = '/api/capture-batches/connector-status';
  static const captureBatchesExportCsv = '/api/capture-batches/export.csv';
  static const captureBatchesUpload = '/api/capture-batches/upload';
  static String captureBatchById(String id) => '/api/capture-batches/$id';

  // departments.routes.js
  static const departments = '/api/departments';
  static String departmentById(String id) => '/api/departments/$id';

  // settings.routes.js
  static const settings = '/api/settings';
  static String settingByKey(String key) => '/api/settings/$key';
  static const settingsMyPreferences = '/api/settings/me/preferences';

  // backup.routes.js
  static const backups = '/api/backup';
  static const backupRun = '/api/backup/run';
  static String backupRestore(String id) => '/api/backup/$id/restore';
}
