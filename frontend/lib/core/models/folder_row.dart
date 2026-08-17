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
  }) = _FolderRow;

  factory FolderRow.fromJson(Map<String, dynamic> json) => _$FolderRowFromJson(json);
}
