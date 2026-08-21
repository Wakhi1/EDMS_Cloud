import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_interceptors.dart';
import '../auth/module_access_events.dart';
import '../auth/secure_token_store.dart';
import '../auth/session_events.dart';
import 'api_client.dart';
import 'resources/access_requests_api.dart';
import 'resources/approvals_api.dart';
import 'resources/audit_api.dart';
import 'resources/auth_api.dart';
import 'resources/backup_api.dart';
import 'resources/branding_api.dart';
import 'resources/capture_batches_api.dart';
import 'resources/departments_api.dart';
import 'resources/document_types_api.dart';
import 'resources/documents_api.dart';
import 'resources/folders_api.dart';
import 'resources/integrations_api.dart';
import 'resources/license_api.dart';
import 'resources/mfa_api.dart';
import 'resources/notifications_api.dart';
import 'resources/permissions_api.dart';
import 'resources/reports_api.dart';
import 'resources/retention_api.dart';
import 'resources/roles_api.dart';
import 'resources/settings_api.dart';
import 'resources/users_api.dart';
import 'resources/versions_api.dart';
import 'resources/workflow_api.dart';

/// Single shared [ApiClient] for the app, with the JWT-attach and
/// 401-refresh-and-retry interceptors wired in. Uses a private raw
/// [AuthApi] (over the same [ApiClient]) purely for the refresh call — not
/// exposed here to avoid confusion with [authApiProvider], which is the one
/// the rest of the app should use.
final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  final tokenStore = ref.watch(secureTokenStoreProvider);
  final refreshApi = AuthApi(client);

  configureAuthInterceptors(
    client.dio,
    getAccessToken: tokenStore.readAccessToken,
    getRefreshToken: tokenStore.readRefreshToken,
    refresh: (refreshToken) async {
      final newAccessToken = await refreshApi.refresh(refreshToken);
      await tokenStore.saveAccessToken(newAccessToken);
      return newAccessToken;
    },
    onRefreshFailed: () async {
      await tokenStore.clear();
      ref.read(sessionEventsProvider).notifyExpired();
    },
  );

  client.onForbidden = (apiException) {
    ref.read(lastDeniedMessageProvider.notifier).state = apiException.message;
    ref.read(moduleAccessEventsProvider).notifyDenied(apiException.message);
  };

  return client;
});

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));
final mfaApiProvider = Provider<MfaApi>((ref) => MfaApi(ref.watch(apiClientProvider)));
final documentsApiProvider = Provider<DocumentsApi>((ref) => DocumentsApi(ref.watch(apiClientProvider)));
final foldersApiProvider = Provider<FoldersApi>((ref) => FoldersApi(ref.watch(apiClientProvider)));
final documentTypesApiProvider = Provider<DocumentTypesApi>((ref) => DocumentTypesApi(ref.watch(apiClientProvider)));
final reportsApiProvider = Provider<ReportsApi>((ref) => ReportsApi(ref.watch(apiClientProvider)));
final approvalsApiProvider = Provider<ApprovalsApi>((ref) => ApprovalsApi(ref.watch(apiClientProvider)));
final notificationsApiProvider = Provider<NotificationsApi>((ref) => NotificationsApi(ref.watch(apiClientProvider)));
final workflowApiProvider = Provider<WorkflowApi>((ref) => WorkflowApi(ref.watch(apiClientProvider)));
final versionsApiProvider = Provider<VersionsApi>((ref) => VersionsApi(ref.watch(apiClientProvider)));
final auditApiProvider = Provider<AuditApi>((ref) => AuditApi(ref.watch(apiClientProvider)));
final retentionApiProvider = Provider<RetentionApi>((ref) => RetentionApi(ref.watch(apiClientProvider)));
final usersApiProvider = Provider<UsersApi>((ref) => UsersApi(ref.watch(apiClientProvider)));
final rolesApiProvider = Provider<RolesApi>((ref) => RolesApi(ref.watch(apiClientProvider)));
final permissionsApiProvider = Provider<PermissionsApi>((ref) => PermissionsApi(ref.watch(apiClientProvider)));
final accessRequestsApiProvider = Provider<AccessRequestsApi>((ref) => AccessRequestsApi(ref.watch(apiClientProvider)));
final integrationsApiProvider = Provider<IntegrationsApi>((ref) => IntegrationsApi(ref.watch(apiClientProvider)));
final captureBatchesApiProvider = Provider<CaptureBatchesApi>((ref) => CaptureBatchesApi(ref.watch(apiClientProvider)));
final departmentsApiProvider = Provider<DepartmentsApi>((ref) => DepartmentsApi(ref.watch(apiClientProvider)));
final settingsApiProvider = Provider<SettingsApi>((ref) => SettingsApi(ref.watch(apiClientProvider)));
final backupApiProvider = Provider<BackupApi>((ref) => BackupApi(ref.watch(apiClientProvider)));
final licenseApiProvider = Provider<LicenseApi>((ref) => LicenseApi(ref.watch(apiClientProvider)));
final brandingApiProvider = Provider<BrandingApi>((ref) => BrandingApi(ref.watch(apiClientProvider)));
