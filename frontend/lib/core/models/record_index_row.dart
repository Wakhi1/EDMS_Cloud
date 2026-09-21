/// A row from GET /api/record-indexes (admin list) or its narrow
/// GET /available sibling — hand-rolled (no freezed/codegen), same
/// convention as CaptureBatchRow: simple display shape, never edited or
/// posted back. The backend already aliases columns to camelCase, so
/// fromJson reads keys directly with no snake_case mapping needed.
class RecordIndexRow {
  const RecordIndexRow({
    required this.id,
    required this.indexValue,
    this.documentTypeId,
    this.documentTypeName,
    this.status,
    this.usedByDocumentId,
    this.usedByTitle,
    this.createdAt,
    this.usedAt,
  });

  final int id;
  final String indexValue;
  final int? documentTypeId;
  final String? documentTypeName;
  final String? status;
  final int? usedByDocumentId;
  final String? usedByTitle;
  final String? createdAt;
  final String? usedAt;

  factory RecordIndexRow.fromJson(Map<String, dynamic> json) {
    return RecordIndexRow(
      id: json['id'] as int,
      indexValue: json['indexValue'] as String,
      documentTypeId: json['documentTypeId'] as int?,
      documentTypeName: json['documentTypeName'] as String?,
      status: json['status'] as String?,
      usedByDocumentId: json['usedByDocumentId'] as int?,
      usedByTitle: json['usedByTitle'] as String?,
      createdAt: json['createdAt'] as String?,
      usedAt: json['usedAt'] as String?,
    );
  }
}
