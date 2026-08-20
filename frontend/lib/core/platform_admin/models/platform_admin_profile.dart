/// The signed-in platform admin (DocSecore staff) — GET /api/platform-admin/auth/me
/// and the `admin` object returned by login. Plain class, not freezed: this
/// whole platform-admin module deliberately avoids codegen to keep it a
/// self-contained, quick-to-build addition (see feature README note).
class PlatformAdminProfile {
  const PlatformAdminProfile({required this.id, required this.fullName, required this.email, required this.isOwner});

  final int id;
  final String fullName;
  final String email;
  final bool isOwner;

  factory PlatformAdminProfile.fromJson(Map<String, dynamic> json) {
    return PlatformAdminProfile(
      id: json['id'] as int,
      fullName: (json['fullName'] ?? json['full_name']) as String,
      email: json['email'] as String,
      isOwner: (json['isOwner'] as bool?) ?? (json['is_owner'] == 1),
    );
  }
}
