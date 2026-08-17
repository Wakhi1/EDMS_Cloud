import 'package:freezed_annotation/freezed_annotation.dart';

part 'document_type_row.freezed.dart';
part 'document_type_row.g.dart';

/// A row from GET /api/document-types.
@freezed
abstract class DocumentTypeRow with _$DocumentTypeRow {
  const factory DocumentTypeRow({
    required int id,
    required String name,
    required String code,
  }) = _DocumentTypeRow;

  factory DocumentTypeRow.fromJson(Map<String, dynamic> json) => _$DocumentTypeRowFromJson(json);
}
