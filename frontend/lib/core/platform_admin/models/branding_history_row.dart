/// Mirrors company_branding_history rows from
/// GET /api/platform-admin/companies/:id/branding/history.
class BrandingHistoryRow {
  const BrandingHistoryRow({
    required this.id,
    required this.changedField,
    required this.changedAt,
    this.oldValue,
    this.newValue,
    this.changedByName,
  });

  final int id;
  final String changedField;
  final String changedAt;
  final String? oldValue;
  final String? newValue;
  final String? changedByName;

  factory BrandingHistoryRow.fromJson(Map<String, dynamic> json) {
    return BrandingHistoryRow(
      id: json['id'] as int,
      changedField: json['changed_field'] as String,
      changedAt: json['changed_at'] as String,
      oldValue: json['old_value'] as String?,
      newValue: json['new_value'] as String?,
      changedByName: json['changed_by_name'] as String?,
    );
  }
}
