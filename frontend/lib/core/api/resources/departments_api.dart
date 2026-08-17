import '../../models/department_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/departments.routes.js.
class DepartmentsApi {
  DepartmentsApi(this._client);

  final ApiClient _client;

  Future<List<DepartmentRow>> list() async {
    final response = await _client.get(Endpoints.departments);
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
