// ignore_for_file: invalid_annotation_target
import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_record.freezed.dart';
part 'document_record.g.dart';

/// A document row as returned by GET /api/documents (search/list) and
/// GET /api/documents/:id (detail) — the backend response for both shares
/// this field set (documents.routes.js), except mimeType/fileName/sizeBytes
/// (current-version metadata joined in for the Repository grid view's file
/// icons), which the list endpoint alone returns — null from the detail one.
@freezed
abstract class DocumentRecord with _$DocumentRecord {
  const factory DocumentRecord({
    required int id,
    @JsonKey(name: 'record_no') required String recordNo,
    required String title,
    required String status,
    required String classification,
    @JsonKey(name: 'watermark_mode') @Default('inherit') String watermarkMode,
    @JsonKey(name: 'member_number') String? memberNumber,
    @JsonKey(name: 'member_name') String? memberName,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'updated_at') String? updatedAt,
    @JsonKey(name: 'document_type') String? documentType,
    String? department,
    @JsonKey(name: 'folder_path') String? folderPath,
    @JsonKey(name: 'current_version_no') int? currentVersionNo,
    @JsonKey(name: 'owner_name') String? ownerName,
    @JsonKey(name: 'mime_type') String? mimeType,
    @JsonKey(name: 'file_name') String? fileName,
    @JsonKey(name: 'size_bytes', fromJson: _intFromDynamic) int? sizeBytes,
    // Current version's page count; null when the file type has no
    // determinable page count (or a pre-migration row not yet backfilled).
    // pageCountEstimated: computed from text length rather than read from the file.
    @JsonKey(name: 'page_count', fromJson: _intFromDynamic) int? pageCount,
    @JsonKey(name: 'page_count_estimated', fromJson: _boolFromDynamic) @Default(false) bool pageCountEstimated,
    @JsonKey(name: 'storage_provider') String? storageProvider,
  }) = _DocumentRecord;

  factory DocumentRecord.fromJson(Map<String, dynamic> json) => _$DocumentRecordFromJson(json);
}

extension DocumentRecordPages on DocumentRecord {
  /// "12", "~3" (estimated from text length, not read from the file) or "—".
  String get pagesLabel => pageCount == null ? '—' : '${pageCountEstimated ? '~' : ''}$pageCount';
}

bool _boolFromDynamic(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  return false;
}

int? _intFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value');
}
