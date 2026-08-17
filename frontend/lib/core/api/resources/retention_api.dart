import '../../models/retention_class_row.dart';
import '../../models/retention_due_item.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/retention.routes.js.
class RetentionApi {
  RetentionApi(this._client);

  final ApiClient _client;

  Future<List<RetentionClassRow>> classes() async {
    final response = await _client.get(Endpoints.retentionClasses);
    return _client.unwrapList(response, RetentionClassRow.fromJson);
  }

  /// PUT /api/retention/classes/:id — Records Manager / System
  /// Administrator only server-side. All fields optional, COALESCE-merged.
  Future<void> updateClass(int id, {int? retentionYears, String? disposalAction, String? name}) async {
    final response = await _client.put(
      Endpoints.retentionClassById('$id'),
      data: {
        'retentionYears': ?retentionYears,
        'disposalAction': ?disposalAction,
        'name': ?name,
      },
    );
    _client.unwrap(response, (_) => null);
  }

  /// POST /api/retention/classes — Records Manager / System Administrator only server-side.
  Future<int> createClass({required String code, required String name, required int retentionYears, String? disposalAction}) async {
    final response = await _client.post(
      Endpoints.retentionClasses,
      data: {'code': code, 'name': name, 'retentionYears': retentionYears, 'disposalAction': ?disposalAction},
    );
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  /// DELETE /api/retention/classes/:id — refuses if still assigned to folders/records.
  Future<void> deleteClass(int id) async {
    final response = await _client.delete(Endpoints.retentionClassById('$id'));
    _client.unwrap(response, (_) => null);
  }

  /// GET /api/retention/due — records whose retention_due_at has passed.
  Future<List<RetentionDueItem>> due() async {
    final response = await _client.get(Endpoints.retentionDue);
    return _client.unwrapList(response, RetentionDueItem.fromJson);
  }

  /// POST /api/retention/:documentId/dispose — irreversible status flip to
  /// 'disposed'. Records Manager / System Administrator only server-side.
  Future<void> dispose(int documentId) async {
    final response = await _client.post(Endpoints.retentionDispose('$documentId'));
    _client.unwrap(response, (_) => null);
  }
}
