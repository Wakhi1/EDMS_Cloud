/// Mirrors backend/routes/platform-admin/licenses.routes.js's row shape.
class LicenseRow {
  const LicenseRow({
    required this.id,
    required this.licenseKey,
    required this.companyId,
    required this.licenseType,
    required this.status,
    required this.issuedAt,
    required this.expiresAt,
    this.companyName,
    this.maxUsers,
    this.storageQuotaBytes,
    this.revokedAt,
    this.revokeReason,
  });

  final int id;
  final String licenseKey;
  final int companyId;
  final String licenseType;
  final String status;
  final String issuedAt;
  final String expiresAt;
  final String? companyName;
  final int? maxUsers;
  final int? storageQuotaBytes;
  final String? revokedAt;
  final String? revokeReason;

  factory LicenseRow.fromJson(Map<String, dynamic> json) {
    return LicenseRow(
      id: json['id'] as int,
      licenseKey: json['license_key'] as String,
      companyId: json['company_id'] as int,
      licenseType: json['license_type'] as String,
      status: json['status'] as String,
      issuedAt: json['issued_at'] as String,
      expiresAt: json['expires_at'] as String,
      companyName: json['company_name'] as String?,
      maxUsers: json['max_users'] as int?,
      storageQuotaBytes: json['storage_quota_bytes'] as int?,
      revokedAt: json['revoked_at'] as String?,
      revokeReason: json['revoke_reason'] as String?,
    );
  }
}
