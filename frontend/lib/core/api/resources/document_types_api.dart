import '../../models/document_type_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/document-types.routes.js. list() is used
/// everywhere as a read-only lookup (Smart Upload's type dropdown/
/// suggestions); create/update/delete are Records Manager / System
/// Administrator only server-side.
class DocumentTypesApi {
  DocumentTypesApi(this._client);

  final ApiClient _client;

  Future<List<DocumentTypeRow>> list() async {
    final response = await _client.get(Endpoints.documentTypes);
    return _client.unwrapList(response, DocumentTypeRow.fromJson);
  }

  Future<int> create({required String name, required String code}) async {
    final response = await _client.post(Endpoints.documentTypes, data: {'name': name, 'code': code});
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['id'] as int);
  }

  Future<void> update(int id, {String? name, String? code}) async {
    final response = await _client.put(Endpoints.documentTypeById('$id'), data: {'name': ?name, 'code': ?code});
    _client.unwrap(response, (_) => null);
  }

  Future<void> delete(int id) async {
    final response = await _client.delete(Endpoints.documentTypeById('$id'));
    _client.unwrap(response, (_) => null);
  }
}
