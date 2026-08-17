import 'package:dio/dio.dart';

import '../../models/document_version_row.dart';
import '../api_client.dart';

/// Mirrors backend/routes/versions.routes.js.
class VersionsApi {
  VersionsApi(this._client);

  final ApiClient _client;

  Future<List<DocumentVersionRow>> list(int documentId) async {
    final response = await _client.get('/api/versions/document/$documentId');
    return _client.unwrapList(response, DocumentVersionRow.fromJson);
  }

  Future<({int versionId, int versionNo})> uploadNewVersion({
    required int documentId,
    required List<int> fileBytes,
    required String fileName,
    required String mimeType,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(fileBytes, filename: fileName, contentType: DioMediaType.parse(mimeType)),
    });
    final response = await _client.post('/api/versions/document/$documentId', data: formData);
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (versionId: json['versionId'] as int, versionNo: json['versionNo'] as int);
    });
  }

  Future<void> restore(int versionId) async {
    final response = await _client.post('/api/versions/$versionId/restore');
    _client.unwrap(response, (_) => null);
  }
}
