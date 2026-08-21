/// Mirrors backend/routes/license.routes.js's response shape for both
/// GET /api/license/status and POST /api/license/activate.
class LicenseStatus {
  const LicenseStatus({required this.active, this.reason, this.licenseType, this.expiresAt, this.countdown});

  final bool active;
  final String? reason;
  final String? licenseType;
  final String? expiresAt;
  final String? countdown;

  factory LicenseStatus.fromJson(Map<String, dynamic> json) {
    return LicenseStatus(
      active: json['active'] as bool,
      reason: json['reason'] as String?,
      licenseType: json['licenseType'] as String?,
      expiresAt: json['expiresAt'] as String?,
      countdown: json['countdown'] as String?,
    );
  }
}
