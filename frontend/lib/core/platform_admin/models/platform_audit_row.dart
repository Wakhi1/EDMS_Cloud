/// Mirrors platform_admin_audit_log rows from
/// GET /api/platform-admin/companies/:id/audit.
class PlatformAuditRow {
  const PlatformAuditRow({
    required this.id,
    required this.action,
    required this.createdAt,
    this.detail,
    this.platformAdminName,
  });

  final int id;
  final String action;
  final String createdAt;
  final String? detail;
  final String? platformAdminName;

  factory PlatformAuditRow.fromJson(Map<String, dynamic> json) {
    return PlatformAuditRow(
      id: json['id'] as int,
      action: json['action'] as String,
      createdAt: json['created_at'] as String,
      detail: json['detail'] as String?,
      platformAdminName: json['platform_admin_name'] as String?,
    );
  }
}
