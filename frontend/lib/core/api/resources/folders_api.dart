import '../../models/folder_row.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/folders.routes.js.
class FoldersApi {
  FoldersApi(this._client);

  final ApiClient _client;

  Future<List<FolderRow>> list() async {
    final response = await _client.get(Endpoints.folders);
    return _client.unwrapList(response, FolderRow.fromJson);
  }

  /// POST /api/folders — returns the new folder's id and full display path
  /// (e.g. "Pension Claims / 2026").
  Future<({int id, String path})> create({required String name, int? parentId, int? departmentId, int? retentionClassId}) async {
    final response = await _client.post(
      Endpoints.folders,
      data: {
        'name': name,
        'parentId': ?parentId,
        'departmentId': ?departmentId,
        'retentionClassId': ?retentionClassId,
      },
    );
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (id: json['id'] as int, path: json['path'] as String);
    });
  }

  /// PUT /api/folders/:id — rename/move/reassign department or retention class.
  Future<void> update(int id, {String? name, int? parentId, int? departmentId, int? retentionClassId}) async {
    final response = await _client.put(
      Endpoints.folderById('$id'),
      data: {
        'name': ?name,
        'parentId': ?parentId,
        'departmentId': ?departmentId,
        'retentionClassId': ?retentionClassId,
      },
    );
    _client.unwrap(response, (_) => null);
  }

  /// DELETE /api/folders/:id — refuses if the folder has documents or subfolders.
  Future<void> delete(int id) async {
    final response = await _client.delete(Endpoints.folderById('$id'));
    _client.unwrap(response, (_) => null);
  }
}
