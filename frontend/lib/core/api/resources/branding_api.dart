import '../../models/company_branding.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/branding.routes.js.
class BrandingApi {
  BrandingApi(this._client);

  final ApiClient _client;

  Future<CompanyBranding> get() async {
    final response = await _client.get(Endpoints.branding);
    return _client.unwrap(response, (data) => CompanyBranding.fromJson(data as Map<String, dynamic>));
  }
}
