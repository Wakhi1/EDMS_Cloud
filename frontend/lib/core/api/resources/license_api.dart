import '../../models/license_status.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/license.routes.js — this deployment's own
/// license status/activation, unauthenticated (checked before anyone can
/// even reach the login screen). docsecure-platform-provider is the
/// actual licensing authority; this just reads/triggers a sync against it.
class LicenseApi {
  LicenseApi(this._client);

  final ApiClient _client;

  Future<LicenseStatus> status() async {
    final response = await _client.get(Endpoints.licenseStatus);
    return _client.unwrap(response, (data) => LicenseStatus.fromJson(data as Map<String, dynamic>));
  }

  Future<LicenseStatus> activate(String licenseKey) async {
    final response = await _client.post(Endpoints.licenseActivate, data: {'licenseKey': licenseKey});
    return _client.unwrap(response, (data) => LicenseStatus.fromJson(data as Map<String, dynamic>));
  }
}
