// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_version_row.freezed.dart';
part 'document_version_row.g.dart';

/// A row from GET /api/versions/document/:documentId.
@freezed
abstract class DocumentVersionRow with _$DocumentVersionRow {
  const factory DocumentVersionRow({
    required int id,
    @JsonKey(name: 'version_no') required int versionNo,
    @JsonKey(name: 'file_name') required String fileName,
    @JsonKey(name: 'size_bytes') int? sizeBytes,
    @JsonKey(name: 'is_current', fromJson: _boolFromInt) required bool isCurrent,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'created_by') String? createdBy,
  }) = _DocumentVersionRow;

  factory DocumentVersionRow.fromJson(Map<String, dynamic> json) => _$DocumentVersionRowFromJson(json);
}

bool _boolFromInt(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}
