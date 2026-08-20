/// Mirrors backend/routes/platform-admin/companies.routes.js's row shape
/// (raw snake_case DB columns) — covers both the list endpoint (which adds
/// a joined current-license summary) and the detail endpoint (which adds
/// `licenses` + `userCount`, populated only when read via [fromDetailJson]).
class CompanyRow {
  const CompanyRow({
    required this.id,
    required this.companyCode,
    required this.name,
    required this.status,
    this.registrationNo,
    this.taxId,
    this.contactName,
    this.contactEmail,
    this.contactPhone,
    this.themePrimaryColor,
    this.themeSecondaryColor,
    this.themeAccentColor,
    this.customDomain,
    this.storageQuotaBytes,
    this.maxUsers,
    this.lastLoginAt,
    this.createdAt,
    this.currentLicenseType,
    this.currentLicenseStatus,
    this.currentLicenseExpiresAt,
    this.userCount,
  });

  final int id;
  final String companyCode;
  final String name;
  final String status;
  final String? registrationNo;
  final String? taxId;
  final String? contactName;
  final String? contactEmail;
  final String? contactPhone;
  final String? themePrimaryColor;
  final String? themeSecondaryColor;
  final String? themeAccentColor;
  final String? customDomain;
  final int? storageQuotaBytes;
  final int? maxUsers;
  final String? lastLoginAt;
  final String? createdAt;
  final String? currentLicenseType;
  final String? currentLicenseStatus;
  final String? currentLicenseExpiresAt;
  final int? userCount;

  factory CompanyRow.fromJson(Map<String, dynamic> json) {
    return CompanyRow(
      id: json['id'] as int,
      companyCode: json['company_code'] as String,
      name: json['name'] as String,
      status: json['status'] as String,
      registrationNo: json['registration_no'] as String?,
      taxId: json['tax_id'] as String?,
      contactName: json['contact_name'] as String?,
      contactEmail: json['contact_email'] as String?,
      contactPhone: json['contact_phone'] as String?,
      themePrimaryColor: json['theme_primary_color'] as String?,
      themeSecondaryColor: json['theme_secondary_color'] as String?,
      themeAccentColor: json['theme_accent_color'] as String?,
      customDomain: json['custom_domain'] as String?,
      storageQuotaBytes: json['storage_quota_bytes'] as int?,
      maxUsers: json['max_users'] as int?,
      lastLoginAt: json['last_login_at'] as String?,
      createdAt: json['created_at'] as String?,
      currentLicenseType: json['license_type'] as String?,
      currentLicenseStatus: json['license_status'] as String?,
      currentLicenseExpiresAt: json['license_expires_at'] as String?,
      userCount: json['userCount'] as int?,
    );
  }
}
