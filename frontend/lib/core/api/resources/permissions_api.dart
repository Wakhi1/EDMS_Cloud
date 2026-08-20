import '../../models/acl_entry_row.dart';
import '../../models/permission_matrix_cell.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/permissions.routes.js. `getAcl`/`grant`/`revoke`
/// are gated per-target via `requireModuleAccess('permissions', ...)`;
/// `matrix`/`updateMatrixCell` are System Administrator only via
/// `allowRoles`, entirely independent of the `permissions` module's own
/// can_view/can_edit cell — see the self-lockout note in
/// permissions_home_screen.dart.
class PermissionsApi {
  PermissionsApi(this._client);

  final ApiClient _client;

  Future<({List<AclEntryRow> own, List<AclEntryRow> inherited})> getAcl(String targetType, String targetId, {bool silent403 = false}) async {
    final response = await _client.get(Endpoints.permissionsFor(targetType, targetId), silent403: silent403);
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      List<AclEntryRow> parse(String key) => (json[key] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AclEntryRow.fromJson)
          .toList(growable: false);
      return (own: parse('own'), inherited: parse('inherited'));
    });
  }

  Future<void> grant(
    String targetType,
    String targetId, {
    required String principalType,
    required int principalId,
    required String permissionLevel,
  }) async {
    final response = await _client.post(
      Endpoints.permissionsFor(targetType, targetId),
      data: {'principalType': principalType, 'principalId': principalId, 'permissionLevel': permissionLevel},
    );
    _client.unwrap(response, (_) => null);
  }

  Future<void> revoke(int aclId) async {
    final response = await _client.delete(Endpoints.permissionAclById('$aclId'));
    _client.unwrap(response, (_) => null);
  }

  Future<List<PermissionMatrixCell>> matrix({bool silent403 = false}) async {
    final response = await _client.get(Endpoints.permissionsMatrix, silent403: silent403);
    return _client.unwrapList(response, PermissionMatrixCell.fromJson);
  }

  Future<void> updateMatrixCell({required int roleId, required String module, required bool canView, required bool canEdit}) async {
    final response = await _client.put(
      Endpoints.permissionsMatrixUpdate,
      data: {'roleId': roleId, 'module': module, 'canView': canView, 'canEdit': canEdit},
    );
    _client.unwrap(response, (_) => null);
  }
}
