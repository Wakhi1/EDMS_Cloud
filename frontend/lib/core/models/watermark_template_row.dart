/// A row from GET /api/watermark-templates (or its /active sibling) —
/// hand-rolled (no freezed/codegen), same convention as RecordIndexRow:
/// simple display shape, never edited in place (edits go through a
/// dialog and a fresh PUT). Backend already aliases columns to camelCase.
class WatermarkTemplateRow {
  const WatermarkTemplateRow({
    required this.id,
    required this.label,
    required this.text,
    this.createdAt,
  });

  final int id;
  final String label;
  final String text;
  final String? createdAt;

  factory WatermarkTemplateRow.fromJson(Map<String, dynamic> json) {
    return WatermarkTemplateRow(
      id: json['id'] as int,
      label: json['label'] as String,
      text: json['text'] as String,
      createdAt: json['createdAt'] as String?,
    );
  }
}
