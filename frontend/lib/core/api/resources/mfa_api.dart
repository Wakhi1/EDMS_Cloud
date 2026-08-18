import 'package:dio/dio.dart';

import '../../auth/models/login_response.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/mfa.routes.js.
///
/// The login-time challenge/verify endpoints authenticate via the
/// short-lived `mfaToken` (issued by POST /api/auth/login when MFA is
/// required), passed as `Authorization: Bearer <mfaToken>` — NOT the normal
/// session access token. Enrollment endpoints (totp/enroll, totp/confirm,
/// backup-codes/generate) use the normal authenticated session instead and
/// are exposed here for completeness; Phase 1's login flow only needs the
/// challenge/verify methods.
class MfaApi {
  MfaApi(this._client);

  final ApiClient _client;

  Options _mfaAuth(String mfaToken) => Options(headers: {'Authorization': 'Bearer $mfaToken'});

  Future<void> sendSmsChallenge(String mfaToken) async {
    final response = await _client.post(
      Endpoints.mfaChallengeSmsSend,
      options: _mfaAuth(mfaToken),
    );
    _client.unwrap(response, (_) => null);
  }

  Future<void> sendEmailChallenge(String mfaToken) async {
    final response = await _client.post(
      Endpoints.mfaChallengeEmailSend,
      options: _mfaAuth(mfaToken),
    );
    _client.unwrap(response, (_) => null);
  }

  /// Whether the signing-in user already has TOTP enrolled (checked before
  /// choosing between showing the QR enrolment step or a bare code field)
  /// and whether they have a valid E.164 phone number on file (checked
  /// before offering "One-time code sent by SMS" as a method at all).
  Future<({bool totpEnrolled, bool hasPhoneNumber})> getChallengeStatus(String mfaToken) async {
    final response = await _client.get(
      Endpoints.mfaChallengeStatus,
      options: _mfaAuth(mfaToken),
    );
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (totpEnrolled: json['totpEnrolled'] as bool, hasPhoneNumber: json['hasPhoneNumber'] as bool);
    });
  }

  /// Mid-login equivalent of [totpEnroll] for a user with no authenticator
  /// app enrolled yet — authenticates with the mfaToken since the user
  /// isn't fully signed in.
  Future<({String qrDataUrl, String base32Secret})> challengeTotpEnroll(String mfaToken) async {
    final response = await _client.post(
      Endpoints.mfaChallengeTotpEnroll,
      options: _mfaAuth(mfaToken),
    );
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (qrDataUrl: json['qrDataUrl'] as String, base32Secret: json['base32Secret'] as String);
    });
  }

  /// Confirming a mid-login enrolment also completes the login, unlike
  /// [totpConfirm] which just marks the method verified for an already
  /// signed-in user.
  Future<LoginResponse> challengeTotpConfirm({required String mfaToken, required String token}) async {
    final response = await _client.post(
      Endpoints.mfaChallengeTotpConfirm,
      data: {'token': token},
      options: _mfaAuth(mfaToken),
    );
    return _client.unwrap(response, (data) => LoginResponse.fromJson(data as Map<String, dynamic>));
  }

  Future<LoginResponse> verifyTotp({required String mfaToken, required String token}) async {
    final response = await _client.post(
      Endpoints.mfaVerifyTotp,
      data: {'token': token},
      options: _mfaAuth(mfaToken),
    );
    return _client.unwrap(response, (data) => LoginResponse.fromJson(data as Map<String, dynamic>));
  }

  Future<LoginResponse> verifyOtp({required String mfaToken, required String code}) async {
    final response = await _client.post(
      Endpoints.mfaVerifyOtp,
      data: {'code': code},
      options: _mfaAuth(mfaToken),
    );
    return _client.unwrap(response, (data) => LoginResponse.fromJson(data as Map<String, dynamic>));
  }

  Future<LoginResponse> verifyBackupCode({required String mfaToken, required String code}) async {
    final response = await _client.post(
      Endpoints.mfaVerifyBackupCode,
      data: {'code': code},
      options: _mfaAuth(mfaToken),
    );
    return _client.unwrap(response, (data) => LoginResponse.fromJson(data as Map<String, dynamic>));
  }

  /// Authenticated-session enrollment calls (Phase 2+ "my account" UI).
  ///
  /// Whether the signed-in user's authenticator app enrolment is actually
  /// confirmed (not just started) and whether they have backup codes —
  /// lets the Security screen gate backup-code generation behind a
  /// completed TOTP confirmation instead of allowing the two to drift out
  /// of sync.
  Future<({bool totpVerified, bool hasBackupCodes})> getMfaStatus() async {
    final response = await _client.get(Endpoints.mfaStatus);
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (totpVerified: json['totpVerified'] as bool, hasBackupCodes: json['hasBackupCodes'] as bool);
    });
  }

  Future<({String qrDataUrl, String base32Secret})> totpEnroll() async {
    final response = await _client.post(Endpoints.mfaTotpEnroll);
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (qrDataUrl: json['qrDataUrl'] as String, base32Secret: json['base32Secret'] as String);
    });
  }

  Future<void> totpConfirm(String token) async {
    final response = await _client.post(Endpoints.mfaTotpConfirm, data: {'token': token});
    _client.unwrap(response, (_) => null);
  }

  Future<List<String>> generateBackupCodes() async {
    final response = await _client.post(Endpoints.mfaBackupCodesGenerate);
    return _client.unwrap(response, (data) => List<String>.from((data as Map<String, dynamic>)['codes'] as List));
  }
}
