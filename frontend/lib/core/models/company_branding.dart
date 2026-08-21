/// Mirrors backend/routes/branding.routes.js's GET /api/branding response.
/// Logo/favicon are never raw URLs here — see [logoUrl]/[faviconUrl],
/// which point at this deployment's own proxy endpoints
/// (GET /api/branding/logo|favicon), not docsecure-platform-provider directly.
class CompanyBranding {
  const CompanyBranding({
    required this.name,
    required this.hasLogo,
    required this.hasFavicon,
    this.companyCode,
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.customDomain,
  });

  final String? companyCode;
  final String name;
  final bool hasLogo;
  final bool hasFavicon;
  final String? primaryColor;
  final String? secondaryColor;
  final String? accentColor;
  final String? customDomain;

  /// "PSPF EDMS" / "ACME EDMS" — for tight spaces (the app bar) where the
  /// full legal name doesn't fit. Falls back to the full name if this
  /// deployment has no company code yet (shouldn't normally happen once licensed).
  String get shortLabel => companyCode != null ? '$companyCode EDMS' : name;

  factory CompanyBranding.fromJson(Map<String, dynamic> json) {
    final theme = (json['theme'] as Map<String, dynamic>?) ?? const {};
    return CompanyBranding(
      companyCode: json['companyCode'] as String?,
      name: json['name'] as String? ?? 'Docsecure EDMS',
      hasLogo: json['hasLogo'] as bool? ?? false,
      hasFavicon: json['hasFavicon'] as bool? ?? false,
      primaryColor: theme['primary'] as String?,
      secondaryColor: theme['secondary'] as String?,
      accentColor: theme['accent'] as String?,
      customDomain: json['customDomain'] as String?,
    );
  }

  /// Used before the real fetch resolves, and if it fails outright (e.g.
  /// docsecure-platform-provider unreachable) — generic, not "PSPF", since
  /// this deployment could by then belong to any licensed company.
  static const fallback = CompanyBranding(
    name: 'Docsecure EDMS',
    hasLogo: false,
    hasFavicon: false,
  );
}
