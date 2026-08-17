import '../../models/backup_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/backup.routes.js. Every method here is
/// System-Administrator-only server-side (allowRoles, not the
/// configurable role_module_permissions matrix) given the blast radius of
/// [restore].
class BackupApi {
  BackupApi(this._client);

  final ApiClient _client;

  Future<List<BackupRow>> list() async {
    final response = await _client.get(Endpoints.backups);
    return _client.unwrapList(response, BackupRow.fromJson);
  }

  Future<int> run() async {
    final response = await _client.post(Endpoints.backupRun);
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  /// [confirmationPhrase] must exactly match the target backup's
  /// [BackupRow.fileKey] — re-checked server-side, this is not just a UI
  /// nicety.
  Future<void> restore(int backupId, String confirmationPhrase) async {
    final response = await _client.post(
      Endpoints.backupRestore('$backupId'),
      data: {'confirmationPhrase': confirmationPhrase},
    );
    _client.unwrap(response, (_) => null);
  }
}
