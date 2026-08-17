import '../api/resources/auth_api.dart';
import '../api/resources/mfa_api.dart';
import 'mfa_method.dart';
import 'models/app_user.dart';
import 'models/login_response.dart';
import 'secure_token_store.dart';

/// Thin façade over [AuthApi] + [MfaApi] + [SecureTokenStore]: owns token
/// persistence side-effects so core/auth/auth_providers.dart's
/// AuthController can stay focused purely on state-machine transitions.
class AuthRepository {
  AuthRepository(this._authApi, this._mfaApi, this._tokenStore);

  final AuthApi _authApi;
  final MfaApi _mfaApi;
  final SecureTokenStore _tokenStore;

  Future<LoginResponse> login({required String email, required String password}) {
    return _authApi.login(email: email, password: password);
  }

  Future<LoginResponse> loginAd({required String email, required String password}) {
    return _authApi.loginAd(email: email, password: password);
  }

  Future<void> sendMfaChallenge(String mfaToken, MfaMethod method) {
    return switch (method) {
      MfaMethod.sms => _mfaApi.sendSmsChallenge(mfaToken),
      MfaMethod.email => _mfaApi.sendEmailChallenge(mfaToken),
      MfaMethod.totp || MfaMethod.backupCode => Future.value(),
    };
  }

  Future<({bool totpEnrolled, bool hasPhoneNumber})> getChallengeStatus(String mfaToken) =>
      _mfaApi.getChallengeStatus(mfaToken);

  Future<({String qrDataUrl, String base32Secret})> enrollTotpChallenge(String mfaToken) {
    return _mfaApi.challengeTotpEnroll(mfaToken);
  }

  Future<LoginResponse> confirmTotpEnrollment({required String mfaToken, required String code}) {
    return _mfaApi.challengeTotpConfirm(mfaToken: mfaToken, token: code);
  }

  Future<LoginResponse> verifyMfa({required String mfaToken, required MfaMethod method, required String code}) {
    return switch (method) {
      MfaMethod.totp => _mfaApi.verifyTotp(mfaToken: mfaToken, token: code),
      MfaMethod.sms || MfaMethod.email => _mfaApi.verifyOtp(mfaToken: mfaToken, code: code),
      MfaMethod.backupCode => _mfaApi.verifyBackupCode(mfaToken: mfaToken, code: code),
    };
  }

  Future<void> persistTokens(LoginResponse response) async {
    final accessToken = response.accessToken;
    final refreshToken = response.refreshToken;
    if (accessToken == null || refreshToken == null) return;
    await _tokenStore.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<String?> readAccessToken() => _tokenStore.readAccessToken();

  Future<AppUser> me() => _authApi.me();

  Future<void> logout() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    await _authApi.logout(refreshToken);
    await _tokenStore.clear();
  }

  Future<void> requestPasswordReset(String email) => _authApi.requestPasswordReset(email);

  Future<void> confirmPasswordReset({required String token, required String newPassword}) {
    return _authApi.confirmPasswordReset(token: token, newPassword: newPassword);
  }
}
