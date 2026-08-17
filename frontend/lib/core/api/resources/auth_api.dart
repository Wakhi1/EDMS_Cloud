import '../../auth/models/app_user.dart';
import '../../auth/models/login_response.dart';
import '../api_client.dart';
import '../api_exception.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/auth.routes.js.
class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  /// Returns either `{mfaRequired:true, mfaToken}` or full tokens+user,
  /// depending on whether the role/user requires MFA.
  Future<LoginResponse> login({required String email, required String password}) async {
    final response = await _client.post(
      Endpoints.authLogin,
      data: {'email': email, 'password': password},
    );
    return _client.unwrap(response, (data) => LoginResponse.fromJson(data as Map<String, dynamic>));
  }

  /// Verifies domain credentials via a real LDAP bind against the
  /// configured Active Directory server (backend/services/ad.service.js),
  /// then signs in exactly like [login] — same response shape, same
  /// fail-closed "no EDMS account exists for this identity" behaviour on
  /// first use if no matching account has been provisioned.
  Future<LoginResponse> loginAd({required String email, required String password}) async {
    final response = await _client.post(
      Endpoints.authAd,
      data: {'email': email, 'password': password},
    );
    return _client.unwrap(response, (data) => LoginResponse.fromJson(data as Map<String, dynamic>));
  }

  /// Refresh token itself is NOT rotated by the backend — keep reusing the
  /// same [refreshToken] until it expires (7d) or is revoked by logout.
  Future<String> refresh(String refreshToken) async {
    final response = await _client.post(
      Endpoints.authRefresh,
      data: {'refreshToken': refreshToken},
    );
    return _client.unwrap(response, (data) => (data as Map<String, dynamic>)['accessToken'] as String);
  }

  Future<void> logout(String? refreshToken) async {
    if (refreshToken == null) return;
    try {
      await _client.post(Endpoints.authLogout, data: {'refreshToken': refreshToken});
    } on ApiException {
      // Logout is best-effort — local token clearing happens regardless.
    }
  }

  Future<AppUser> me() async {
    final response = await _client.get(Endpoints.authMe);
    return _client.unwrap(response, (data) => AppUser.fromJson(data as Map<String, dynamic>));
  }

  Future<void> requestPasswordReset(String email) async {
    final response = await _client.post(
      Endpoints.authPasswordResetRequest,
      data: {'email': email},
    );
    _client.unwrap(response, (_) => null);
  }

  Future<void> confirmPasswordReset({required String token, required String newPassword}) async {
    final response = await _client.post(
      Endpoints.authPasswordResetConfirm,
      data: {'token': token, 'newPassword': newPassword},
    );
    _client.unwrap(response, (_) => null);
  }
}
