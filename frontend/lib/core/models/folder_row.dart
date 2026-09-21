// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'folder_row.freezed.dart';
part 'folder_row.g.dart';

/// A flat folder row from GET /api/folders. The client builds the tree
/// itself from [parentId] — the backend has no nested/tree endpoint.
@freezed
abstract class FolderRow with _$FolderRow {
  const factory FolderRow({
    required int id,
    @JsonKey(name: 'parent_id') int? parentId,
    required String name,
    required String path,
    @JsonKey(name: 'department_id') int? departmentId,
    @JsonKey(name: 'retention_class_id') int? retentionClassId,
    @JsonKey(name: 'retention_class_name') String? retentionClassName,
    // Comma-separated distinct storage providers used by this folder's own
    // (direct, non-recursive) documents — see folders.routes.js. Null if
    // the folder has none.
    @JsonKey(name: 'storage_providers') String? storageProviders,
    // This folder's own DEFAULT storage location for new uploads (distinct
    // from storageProviders above, which reflects where existing documents
    // already ended up) — null means "no folder-level default; fall back
    // to whatever's globally active" (document.service.js's registerDocument).
    @JsonKey(name: 'storage_provider_id') String? storageProviderId,
    @JsonKey(name: 'storage_provider_name') String? storageProviderName,
    @JsonKey(name: 'storage_prefix') String? storagePrefix,
  }) = _FolderRow;

  factory FolderRow.fromJson(Map<String, dynamic> json) => _$FolderRowFromJson(json);
}
