import 'package:freezed_annotation/freezed_annotation.dart';

import 'mfa_method.dart';
import 'models/app_user.dart';

part 'auth_state.freezed.dart';

/// The login flow's own state machine — distinct from [LoginResponse]
/// (core/auth/models/login_response.dart), which is just the raw API DTO.
/// `enteringCredentials -> chooseMfaMethod -> enteringMfaCode -> deviceTrust
/// -> authenticated`, with `accountLocked` (423) and `resetPassword` as
/// side branches reachable from `enteringCredentials`.
@freezed
sealed class LoginState with _$LoginState {
  const factory LoginState.enteringCredentials({
    @Default(false) bool isSubmitting,
    String? error,
  }) = LoginEnteringCredentials;

  const factory LoginState.chooseMfaMethod({
    required String mfaToken,
    @Default(false) bool totpEnrolled,
    @Default(false) bool hasPhoneNumber,
    @Default(false) bool isSubmitting,
    String? error,
  }) = LoginChooseMfaMethod;

  const factory LoginState.enteringMfaCode({
    required String mfaToken,
    required MfaMethod method,
    @Default(false) bool isSubmitting,
    String? error,
  }) = LoginEnteringMfaCode;

  /// Reached instead of [enteringMfaCode] when the user picks "Authenticator
  /// app" but has never enrolled one — shows the QR/manual-key enrolment
  /// step inline, and confirming it also completes the login.
  const factory LoginState.enrollingTotp({
    required String mfaToken,
    required String qrDataUrl,
    required String base32Secret,
    @Default(false) bool isSubmitting,
    String? error,
  }) = LoginEnrollingTotp;

  /// Local-only step — no backend "trusted device" concept exists. Trusting
  /// a device only remembers a flag on this machine to skip the
  /// method-choice screen on the next login; it does not weaken MFA on the
  /// server, which always re-verifies a second factor on every login.
  const factory LoginState.deviceTrust({
    required AppUser user,
    required MfaMethod method,
  }) = LoginDeviceTrust;

  const factory LoginState.authenticated({required AppUser user}) = LoginAuthenticated;

  /// 423 response from POST /api/auth/login.
  const factory LoginState.accountLocked() = LoginAccountLocked;

  const factory LoginState.resetPassword({
    @Default(false) bool sent,
    @Default(false) bool isSubmitting,
    String? error,
  }) = LoginResetPassword;
}
