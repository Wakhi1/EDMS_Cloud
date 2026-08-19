import '../../models/integration_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/integrations.routes.js. Capture-batch data
/// (list/detail/upload/export/summary) lives in CaptureBatchesApi instead
/// — matching the backend's own routes/capture.routes.js split.
class IntegrationsApi {
  IntegrationsApi(this._client);

  final ApiClient _client;

  Future<List<IntegrationRow>> list() async {
    final response = await _client.get(Endpoints.integrations);
    return _client.unwrapList(response, IntegrationRow.fromJson);
  }

  /// PUT /api/integrations/:id — System Administrator only server-side, no
  /// client-side pre-check (matches UsersApi's updateRole/updateLock).
  Future<void> update(
    String id, {
    String? name,
    String? description,
    String? status,
    String? endpoint,
    Map<String, dynamic>? configJson,
  }) async {
    final response = await _client.put(
      Endpoints.integrationById(id),
      data: {
        'name': ?name,
        'description': ?description,
        'status': ?status,
        'endpoint': ?endpoint,
        'configJson': ?configJson,
      },
    );
    _client.unwrap(response, (_) => null);
  }

  /// POST /api/integrations — register a new integration entry.
  Future<void> create({
    required String id,
    required String name,
    String? description,
    String? endpoint,
    String? status,
  }) async {
    final response = await _client.post(
      Endpoints.integrations,
      data: {
        'id': id,
        'name': name,
        'description': ?description,
        'endpoint': ?endpoint,
        'status': ?status,
      },
    );
    _client.unwrap(response, (_) => null);
  }

  Future<void> delete(String id) async {
    final response = await _client.delete(Endpoints.integrationById(id));
    _client.unwrap(response, (_) => null);
  }

  /// POST /api/integrations/:id/test — real connection check, persists the result server-side.
  Future<({bool ok, String message})> testConnection(String id) async {
    final response = await _client.post(Endpoints.integrationTest(id));
    return _client.unwrap(response, (data) {
      final map = data as Map<String, dynamic>;
      return (ok: map['ok'] as bool, message: map['message'] as String);
    });
  }

  Future<String> getStorageLocation() async {
    final response = await _client.get(Endpoints.integrationStorageLocation);
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['provider'] as String);
  }

  Future<void> setStorageLocation(String provider) async {
    final response = await _client.put(Endpoints.integrationStorageLocation, data: {'provider': provider});
    _client.unwrap(response, (_) => null);
  }

  /// GET /api/integrations/storage-options — id+name only for the four
  /// storage-type connectors. Reachable by any 'capture' role (unlike the
  /// full GET / list, which is admin-only since it includes config_json).
  Future<List<({String id, String name})>> storageOptions() async {
    final response = await _client.get(Endpoints.integrationStorageOptions);
    return _client.unwrap(response, (data) {
      return (data as List)
          .cast<Map<String, dynamic>>()
          .map((row) => (id: row['id'] as String, name: row['name'] as String))
          .toList();
    });
  }

  /// GET /api/integrations/:id/browse?prefix= — folders/files for a storage-type connector.
  Future<({List<String> folders, List<String> files})> browse(String id, {String? prefix}) async {
    final response = await _client.get(
      Endpoints.integrationBrowse(id),
      queryParameters: {if (prefix != null && prefix.isNotEmpty) 'prefix': prefix},
    );
    return _client.unwrap(response, (data) {
      final map = data as Map<String, dynamic>;
      return (
        folders: (map['folders'] as List).cast<String>(),
        files: (map['files'] as List).cast<String>(),
      );
    });
  }

  /// Returns the new folder's full prefix (e.g. `hr/contracts`), so callers
  /// can auto-select it right after creation.
  Future<String> createFolder(String id, {String? prefix, required String name}) async {
    final response = await _client.post(
      Endpoints.integrationFolders(id),
      data: {'prefix': ?prefix, 'name': name},
    );
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['prefix'] as String);
  }

  /// POST /api/integrations/:id/import — brings files already sitting under
  /// `prefix` in a storage-type connector into the Repository as real
  /// documents in `folderId`. System-Administrator-only server-side.
  /// [grants]: only sent when access should be restricted from the start
  /// (each entry shaped like GrantAccessDialog's return value); omitted or
  /// empty means the imported folder stays open to anyone with Repository
  /// access, same default as any other folder.
  Future<({int importedCount, int skippedCount})> importFromStorage(
    String id, {
    required String prefix,
    required int folderId,
    required int documentTypeId,
    String? classification,
    int? departmentId,
    int? retentionClassId,
    List<({String principalType, int principalId, String permissionLevel})> grants = const [],
  }) async {
    final response = await _client.post(
      Endpoints.integrationImport(id),
      data: {
        'prefix': prefix,
        'folderId': folderId,
        'documentTypeId': documentTypeId,
        'classification': ?classification,
        'departmentId': ?departmentId,
        'retentionClassId': ?retentionClassId,
        if (grants.isNotEmpty)
          'defaultAccess': {
            'restricted': true,
            'grants': [
              for (final g in grants)
                {'principalType': g.principalType, 'principalId': g.principalId, 'permissionLevel': g.permissionLevel},
            ],
          },
      },
    );
    return _client.unwrap(response, (data) {
      final map = data as Map<String, dynamic>;
      return (
        importedCount: (map['imported'] as List).length,
        skippedCount: (map['skipped'] as List).length,
      );
    });
  }
}
