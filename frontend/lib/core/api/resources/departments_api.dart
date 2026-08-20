import '../../models/department_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/departments.routes.js.
class DepartmentsApi {
  DepartmentsApi(this._client);

  final ApiClient _client;

  /// [silent403]: pass true where the department list is a nice-to-have for
  /// an otherwise-unrelated screen (e.g. an optional field in a dialog) —
  /// a role without the 'departments' module (most roles: it's Records
  /// Manager/System Administrator only) would otherwise get yanked to
  /// /access-denied by the global 403 handler over a field they don't
  /// even need to touch.
  Future<List<DepartmentRow>> list({bool silent403 = false}) async {
    final response = await _client.get(Endpoints.departments, silent403: silent403);
    return _client.unwrapList(response, DepartmentRow.fromJson);
  }

  Future<void> create({required String name, String? description}) async {
    final response = await _client.post(Endpoints.departments, data: {'name': name, 'description': ?description});
    _client.unwrap(response, (_) => null);
  }

  Future<void> update(int id, {String? name, String? description, bool? isActive}) async {
    final response = await _client.put(
      Endpoints.departmentById('$id'),
      data: {'name': ?name, 'description': ?description, 'isActive': ?isActive},
    );
    _client.unwrap(response, (_) => null);
  }

  Future<void> delete(int id) async {
    final response = await _client.delete(Endpoints.departmentById('$id'));
    _client.unwrap(response, (_) => null);
  }
}
