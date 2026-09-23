import '../../models/record_index_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/record-indexes.routes.js.
class RecordIndexesApi {
  RecordIndexesApi(this._client);

  final ApiClient _client;

  /// Narrow lookup for an upload flow's picker — GET /available.
  Future<List<RecordIndexRow>> available(int documentTypeId) async {
    final response = await _client.get(Endpoints.recordIndexesAvailable, queryParameters: {'documentTypeId': '$documentTypeId'});
    return _client.unwrapList(response, RecordIndexRow.fromJson);
  }

  /// Full admin list — GET /.
  Future<List<RecordIndexRow>> list({int? documentTypeId, String? status}) async {
    final response = await _client.get(
      Endpoints.recordIndexes,
      queryParameters: {'documentTypeId': ?documentTypeId?.toString(), 'status': ?status},
    );
    return _client.unwrapList(response, RecordIndexRow.fromJson);
  }

  Future<List<String>> generate({required int documentTypeId, required int count}) async {
    final response = await _client.post(Endpoints.recordIndexesGenerate, data: {'documentTypeId': documentTypeId, 'count': count});
    return _client.unwrap(response, (data) => ((data as Map<String, dynamic>)['generated'] as List).cast<String>());
  }

  Future<int> create({required int documentTypeId, required String indexValue}) async {
    final response = await _client.post(Endpoints.recordIndexes, data: {'documentTypeId': documentTypeId, 'indexValue': indexValue});
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  /// PUT /:id — move an unused index to another document type.
  Future<void> changeType(int id, {required int documentTypeId}) async {
    final response = await _client.put(Endpoints.recordIndexById('$id'), data: {'documentTypeId': documentTypeId});
    _client.unwrap(response, (_) => null);
  }

  Future<void> delete(int id) async {
    final response = await _client.delete(Endpoints.recordIndexById('$id'));
    _client.unwrap(response, (_) => null);
  }
}
