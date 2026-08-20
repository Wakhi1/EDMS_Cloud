import '../api/api_client.dart';
import '../api/endpoints.dart';
import 'models/branding_history_row.dart';
import 'models/company_row.dart';
import 'models/license_row.dart';
import 'models/platform_admin_profile.dart';
import 'models/platform_audit_row.dart';

/// Mirrors backend/routes/platform-admin/*.routes.js. Talks to [client], a
/// second [ApiClient] instance wired to the platform-admin token store —
/// see platform_admin_providers.dart — never the tenant apiClientProvider.
class PlatformAdminApi {
  PlatformAdminApi(this._client);

  final ApiClient _client;

  Future<({String accessToken, String refreshToken, PlatformAdminProfile admin})> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(Endpoints.platformAdminLogin, data: {'email': email, 'password': password});
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        admin: PlatformAdminProfile.fromJson(json['admin'] as Map<String, dynamic>),
      );
    });
  }

  Future<String> refresh(String refreshToken) async {
    final response = await _client.post(Endpoints.platformAdminRefresh, data: {'refreshToken': refreshToken});
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['accessToken'] as String);
  }

  Future<void> logout(String? refreshToken) async {
    final response = await _client.post(Endpoints.platformAdminLogout, data: {'refreshToken': refreshToken});
    _client.unwrap(response, (_) => null);
  }

  Future<PlatformAdminProfile> me() async {
    final response = await _client.get(Endpoints.platformAdminMe);
    return _client.unwrap(response, (data) => PlatformAdminProfile.fromJson(data as Map<String, dynamic>));
  }

  Future<List<CompanyRow>> listCompanies() async {
    final response = await _client.get(Endpoints.platformAdminCompanies);
    return _client.unwrapList(response, CompanyRow.fromJson);
  }

  Future<({CompanyRow company, List<LicenseRow> licenses, int userCount})> getCompany(int id) async {
    final response = await _client.get(Endpoints.platformAdminCompanyById('$id'));
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      final licenses = (json['licenses'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(LicenseRow.fromJson)
          .toList(growable: false);
      return (company: CompanyRow.fromJson(json), licenses: licenses, userCount: (json['userCount'] as int?) ?? 0);
    });
  }

  Future<int> createCompany({
    required String companyCode,
    required String name,
    String? registrationNo,
    String? taxId,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
  }) async {
    final response = await _client.post(Endpoints.platformAdminCompanies, data: {
      'companyCode': companyCode,
      'name': name,
      'registrationNo': ?registrationNo,
      'taxId': ?taxId,
      'contactName': ?contactName,
      'contactEmail': ?contactEmail,
      'contactPhone': ?contactPhone,
    });
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  Future<void> updateCompany(
    int id, {
    String? name,
    String? registrationNo,
    String? taxId,
    String? contactName,
    String? contactEmail,
    String? contactPhone,
  }) async {
    final response = await _client.put(Endpoints.platformAdminCompanyById('$id'), data: {
      'name': ?name,
      'registrationNo': ?registrationNo,
      'taxId': ?taxId,
      'contactName': ?contactName,
      'contactEmail': ?contactEmail,
      'contactPhone': ?contactPhone,
    });
    _client.unwrap(response, (_) => null);
  }

  Future<void> setCompanyStatus(int id, String status) async {
    final response = await _client.put(Endpoints.platformAdminCompanyStatus('$id'), data: {'status': status});
    _client.unwrap(response, (_) => null);
  }

  Future<int> createAdminUser(int companyId, {required String fullName, required String email, required String password}) async {
    final response = await _client.post(
      Endpoints.platformAdminCompanyAdminUser('$companyId'),
      data: {'fullName': fullName, 'email': email, 'password': password},
    );
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['userId'] as int);
  }

  Future<void> updateTheme(
    int companyId, {
    String? primaryColor,
    String? secondaryColor,
    String? accentColor,
    String? customDomain,
  }) async {
    final response = await _client.put(Endpoints.platformAdminCompanyBrandingTheme('$companyId'), data: {
      'primaryColor': ?primaryColor,
      'secondaryColor': ?secondaryColor,
      'accentColor': ?accentColor,
      'customDomain': ?customDomain,
    });
    _client.unwrap(response, (_) => null);
  }

  Future<List<BrandingHistoryRow>> brandingHistory(int companyId) async {
    final response = await _client.get(Endpoints.platformAdminCompanyBrandingHistory('$companyId'));
    return _client.unwrapList(response, BrandingHistoryRow.fromJson);
  }

  Future<List<PlatformAuditRow>> companyAudit(int companyId) async {
    final response = await _client.get(Endpoints.platformAdminCompanyAudit('$companyId'));
    return _client.unwrapList(response, PlatformAuditRow.fromJson);
  }

  Future<List<LicenseRow>> listLicenses({int? companyId}) async {
    final response = await _client.get(
      Endpoints.platformAdminLicenses,
      queryParameters: companyId == null ? null : {'companyId': companyId},
    );
    return _client.unwrapList(response, LicenseRow.fromJson);
  }

  Future<({int id, String licenseKey, String signedToken})> issueLicense({
    required int companyId,
    required String licenseType,
    required DateTime expiresAt,
    int? maxUsers,
    int? storageQuotaBytes,
  }) async {
    final response = await _client.post(Endpoints.platformAdminLicenses, data: {
      'companyId': companyId,
      'licenseType': licenseType,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
      'maxUsers': ?maxUsers,
      'storageQuotaBytes': ?storageQuotaBytes,
    });
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (id: json['id'] as int, licenseKey: json['licenseKey'] as String, signedToken: json['signedToken'] as String);
    });
  }

  Future<void> revokeLicense(int id, {String? reason}) async {
    final response = await _client.post(Endpoints.platformAdminLicenseRevoke('$id'), data: {'reason': ?reason});
    _client.unwrap(response, (_) => null);
  }

  Future<({bool valid, String? result})> validateLicense(int id) async {
    final response = await _client.post(Endpoints.platformAdminLicenseValidate('$id'));
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (valid: json['valid'] as bool, result: json['result'] as String?);
    });
  }
}
