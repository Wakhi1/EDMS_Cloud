import '../api_client.dart';
import '../endpoints.dart';

/// A row from GET /api/api-keys — masked, never the raw key or its hash.
typedef ApiKeyRow = ({
  int id,
  String name,
  String keyPrefix,
  String createdBy,
  String? lastUsedAt,
  String? revokedAt,
  String createdAt,
});

/// Mirrors backend/routes/apiKeys.routes.js — long-lived credentials for
/// headless callers, today only the local watched-folder agent (see
/// /local-agent at the repo root and routes/agentUpload.routes.js).
class ApiKeysApi {
  ApiKeysApi(this._client);

  final ApiClient _client;

  Future<List<ApiKeyRow>> list() async {
    final response = await _client.get(Endpoints.apiKeys);
    return _client.unwrap(response, (data) {
      return (data as List).cast<Map<String, dynamic>>().map((row) {
        return (
          id: row['id'] as int,
          name: row['name'] as String,
          keyPrefix: row['key_prefix'] as String,
          createdBy: row['created_by'] as String,
          lastUsedAt: row['last_used_at'] as String?,
          revokedAt: row['revoked_at'] as String?,
          createdAt: row['created_at'] as String,
        );
      }).toList();
    });
  }

  /// Returns the raw key — shown to the admin exactly once, never
  /// retrievable again after this call returns.
  Future<String> create(String name) async {
    final response = await _client.post(Endpoints.apiKeys, data: {'name': name});
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['apiKey'] as String);
  }

  Future<void> revoke(int id) async {
    final response = await _client.delete(Endpoints.apiKeyById('$id'));
    _client.unwrap(response, (_) => null);
  }
}
