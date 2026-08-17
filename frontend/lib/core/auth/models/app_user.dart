import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

/// The authenticated user, as returned by login/MFA-verify (`{id, fullName,
/// email, role}`) or `GET /api/auth/me` (adds `roleId`, `mfaSatisfied`).
@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required int id,
    required String fullName,
    required String email,
    required String role,
    int? roleId,
    bool? mfaSatisfied,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}
