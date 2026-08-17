import 'package:freezed_annotation/freezed_annotation.dart';

import 'app_user.dart';

part 'login_response.freezed.dart';
part 'login_response.g.dart';

/// Raw shape returned by POST /api/auth/login, the MFA verify endpoints,
/// and POST /api/auth/refresh (a subset — only accessToken). Deliberately
/// flat with nullable fields rather than a sealed union: this is a DTO
/// mirroring the wire format, not the app's own login state machine (see
/// core/auth/auth_state.dart for that).
@freezed
abstract class LoginResponse with _$LoginResponse {
  const factory LoginResponse({
    bool? mfaRequired,
    String? mfaToken,
    String? accessToken,
    String? refreshToken,
    AppUser? user,
  }) = _LoginResponse;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);
}
