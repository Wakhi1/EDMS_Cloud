/// A row from GET /api/settings — hand-rolled (fetch & display, edited via
/// a single value field, never a full form), same convention as
/// CaptureBatchRow.
class SystemSettingRow {
  const SystemSettingRow({
    required this.key,
    required this.value,
    this.description,
    this.updatedAt,
  });

  final String key;
  final String value;
  final String? description;
  final String? updatedAt;

  factory SystemSettingRow.fromJson(Map<String, dynamic> json) {
    return SystemSettingRow(
      key: json['setting_key'] as String,
      value: json['setting_value'] as String? ?? '',
      description: json['description'] as String?,
      updatedAt: json['updated_at'] as String?,
    );
  }
}
