import '../../models/role_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/roles.routes.js. list() is used wherever a role
/// id+name pair is needed (Create User, Workflow Designer's per-step role
/// picker, Permission Matrix); create/update/delete are System
/// Administrator only server-side.
class RolesApi {
  RolesApi(this._client);

  final ApiClient _client;

  Future<List<RoleRow>> list() async {
    final response = await _client.get(Endpoints.roles);
    return _client.unwrapList(response, RoleRow.fromJson);
  }

  Future<int> create({required String name, String? description, bool mfaRequired = false}) async {
    final response = await _client.post(
      Endpoints.roles,
      data: {'name': name, 'description': description, 'mfaRequired': mfaRequired},
    );
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  Future<void> update(int id, {String? name, String? description, bool? mfaRequired}) async {
    final response = await _client.put(
      Endpoints.roleById('$id'),
      data: {'name': ?name, 'description': ?description, 'mfaRequired': ?mfaRequired},
    );
    _client.unwrap(response, (_) => null);
  }

  Future<void> delete(int id) async {
    final response = await _client.delete(Endpoints.roleById('$id'));
    _client.unwrap(response, (_) => null);
  }
}
