import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/audit/providers/audit_providers.dart';
import '../../features/repository/providers/repository_providers.dart';
import '../../features/reports/providers/reports_providers.dart';
import '../api/api_exception.dart';
import '../api/api_providers.dart';
import 'auth_repository.dart';
import 'auth_state.dart';
import 'device_trust_store.dart';
import 'mfa_method.dart';
import 'models/app_user.dart';
import 'secure_token_store.dart';
import 'session_events.dart';

part 'auth_providers.g.dart';

/// These are plain (non-autoDispose) StateProviders, so they live for the
/// whole app process — neither switching users on the same tab (sign out,
/// sign back in as someone else) nor navigating away and back via the nav
/// menu (see ResponsiveScaffold's nav tap handlers) resets them on their
/// own. Left alone, the next user/visit silently inherits whatever folder/
/// filter/selection was left behind (confirmed live: Repository showing
/// only one folder's documents for a brand new session, with no visible
/// reason why "All records" wasn't showing everything). Only the providers
/// that actually scope *which data loads* are reset here — pure display
/// preferences (view mode, panel collapsed) are left alone since carrying
/// those across a sign-in or a nav click is harmless.
void resetPerUserUiState(Ref ref) {
  ref.invalidate(repositoryFiltersProvider);
  ref.invalidate(repositoryRecycleBinProvider);
  ref.invalidate(selectedDocumentProvider);
  ref.invalidate(auditFiltersProvider);
  ref.invalidate(reportsFiltersProvider);
}

/// [WidgetRef] variant for call sites outside a provider (e.g.
/// ResponsiveScaffold's nav tap handlers) — WidgetRef isn't a [Ref] in this
/// Riverpod version, so this duplicates the same five invalidate calls
/// rather than fighting the type system.
void resetPerUserUiStateFromWidget(WidgetRef ref) {
  ref.invalidate(repositoryFiltersProvider);
  ref.invalidate(repositoryRecycleBinProvider);
  ref.invalidate(selectedDocumentProvider);
  ref.invalidate(auditFiltersProvider);
  ref.invalidate(reportsFiltersProvider);
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(authApiProvider),
    ref.watch(mfaApiProvider),
    ref.watch(secureTokenStoreProvider),
  );
});

@riverpod
class AuthController extends _$AuthController {
  @override
  Future<LoginState> build() async {
    final subscription = ref.watch(sessionEventsProvider).onExpired.listen((_) => forceSignOut());
    ref.onDispose(subscription.cancel);

    final repo = ref.watch(authRepositoryProvider);
    final accessToken = await repo.readAccessToken();
    if (accessToken == null) return const LoginState.enteringCredentials();

    try {
      final user = await repo.me();
      return LoginState.authenticated(user: user);
    } on ApiException {
      return const LoginState.enteringCredentials();
    }
  }

  void forceSignOut() {
    state = const AsyncValue.data(LoginState.enteringCredentials());
    resetPerUserUiState(ref);
  }

  Future<void> login({required String email, required String password, bool viaAd = false}) async {
    final current = state.valueOrNull;
    if (current is! LoginEnteringCredentials) return;
    state = AsyncValue.data(current.copyWith(isSubmitting: true, error: null));

    final repo = ref.read(authRepositoryProvider);
    try {
      final response = viaAd
          ? await repo.loginAd(email: email, password: password)
          : await repo.login(email: email, password: password);
      if (response.mfaRequired == true && response.mfaToken != null) {
        final trustedMethod = await ref.read(deviceTrustStoreProvider).readTrustedMethod();
        if (trustedMethod != null) {
          state = AsyncValue.data(LoginState.enteringMfaCode(mfaToken: response.mfaToken!, method: trustedMethod));
          if (trustedMethod == MfaMethod.sms || trustedMethod == MfaMethod.email) {
            await sendMfaChallenge();
          }
          return;
        }
        var totpEnrolled = false;
        var hasPhoneNumber = false;
        try {
          final status = await repo.getChallengeStatus(response.mfaToken!);
          totpEnrolled = status.totpEnrolled;
          hasPhoneNumber = status.hasPhoneNumber;
        } on ApiException {
          // Fall back to hiding SMS / showing the TOTP enrolment step —
          // the method-choice screen still works, just conservatively.
        }
        state = AsyncValue.data(LoginState.chooseMfaMethod(
          mfaToken: response.mfaToken!,
          totpEnrolled: totpEnrolled,
          hasPhoneNumber: hasPhoneNumber,
        ));
        return;
      }
      if (response.accessToken != null && response.user != null) {
        await repo.persistTokens(response);
        state = AsyncValue.data(LoginState.authenticated(user: response.user!));
        return;
      }
      state = AsyncValue.data(current.copyWith(isSubmitting: false, error: 'Unexpected response from the server.'));
    } on ApiException catch (e) {
      if (e.isLocked) {
        state = const AsyncValue.data(LoginState.accountLocked());
        return;
      }
      state = AsyncValue.data(current.copyWith(isSubmitting: false, error: e.message));
    }
  }

  Future<void> chooseMfaMethod(MfaMethod method) async {
    final current = state.valueOrNull;
    if (current is! LoginChooseMfaMethod) return;
    final repo = ref.read(authRepositoryProvider);

    if (method == MfaMethod.totp) {
      state = AsyncValue.data(current.copyWith(isSubmitting: true, error: null));
      try {
        if (!current.totpEnrolled) {
          final enroll = await repo.enrollTotpChallenge(current.mfaToken);
          state = AsyncValue.data(LoginState.enrollingTotp(
            mfaToken: current.mfaToken,
            qrDataUrl: enroll.qrDataUrl,
            base32Secret: enroll.base32Secret,
          ));
          return;
        }
      } on ApiException catch (e) {
        // The backend knows better than our possibly-stale totpEnrolled
        // flag (e.g. an earlier status check that failed/timed out) — a
        // verified authenticator app actually already exists. Fall through
        // to code entry instead of surfacing this as an error.
        if (!e.isConflict) {
          state = AsyncValue.data(current.copyWith(isSubmitting: false, error: e.message));
          return;
        }
      }
    }

    state = AsyncValue.data(
      LoginState.enteringMfaCode(mfaToken: current.mfaToken, method: method),
    );
    if (method == MfaMethod.sms || method == MfaMethod.email) {
      sendMfaChallenge();
    }
  }

  Future<void> confirmEnrollTotp(String code) async {
    final current = state.valueOrNull;
    if (current is! LoginEnrollingTotp) return;
    state = AsyncValue.data(current.copyWith(isSubmitting: true, error: null));

    final repo = ref.read(authRepositoryProvider);
    try {
      final response = await repo.confirmTotpEnrollment(mfaToken: current.mfaToken, code: code);
      if (response.accessToken != null && response.user != null) {
        await repo.persistTokens(response);
        state = AsyncValue.data(
          LoginState.deviceTrust(user: response.user!, method: MfaMethod.totp),
        );
        return;
      }
      state = AsyncValue.data(current.copyWith(isSubmitting: false, error: 'Unexpected response from the server.'));
    } on ApiException catch (e) {
      state = AsyncValue.data(current.copyWith(isSubmitting: false, error: e.message));
    }
  }

  Future<void> sendMfaChallenge() async {
    final current = state.valueOrNull;
    if (current is! LoginEnteringMfaCode) return;
    state = AsyncValue.data(current.copyWith(isSubmitting: true, error: null));
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.sendMfaChallenge(current.mfaToken, current.method);
      state = AsyncValue.data(current.copyWith(isSubmitting: false));
    } on ApiException catch (e) {
      state = AsyncValue.data(current.copyWith(isSubmitting: false, error: e.message));
    }
  }

  Future<void> verifyMfa(String code) async {
    final current = state.valueOrNull;
    if (current is! LoginEnteringMfaCode) return;
    state = AsyncValue.data(current.copyWith(isSubmitting: true, error: null));

    final repo = ref.read(authRepositoryProvider);
    try {
      final response = await repo.verifyMfa(mfaToken: current.mfaToken, method: current.method, code: code);
      if (response.accessToken != null && response.user != null) {
        await repo.persistTokens(response);
        state = AsyncValue.data(
          LoginState.deviceTrust(user: response.user!, method: current.method),
        );
        return;
      }
      state = AsyncValue.data(current.copyWith(isSubmitting: false, error: 'Unexpected response from the server.'));
    } on ApiException catch (e) {
      state = AsyncValue.data(current.copyWith(isSubmitting: false, error: e.message));
    }
  }

  void backToMethodChoice() {
    final mfaToken = switch (state.valueOrNull) {
      LoginEnteringMfaCode(:final mfaToken) => mfaToken,
      LoginEnrollingTotp(:final mfaToken) => mfaToken,
      _ => null,
    };
    if (mfaToken == null) return;
    state = AsyncValue.data(LoginState.chooseMfaMethod(mfaToken: mfaToken));
  }

  void backToCredentials() {
    state = const AsyncValue.data(LoginState.enteringCredentials());
  }

  /// Local-only — see [LoginState.deviceTrust] doc comment.
  Future<void> finishLogin({required bool trustDevice, required MfaMethod method}) async {
    final current = state.valueOrNull;
    if (current is! LoginDeviceTrust) return;
    final trustStore = ref.read(deviceTrustStoreProvider);
    if (trustDevice) {
      await trustStore.trust(method);
    } else {
      await trustStore.clear();
    }
    state = AsyncValue.data(LoginState.authenticated(user: current.user));
  }

  void goToResetPassword() {
    state = const AsyncValue.data(LoginState.resetPassword());
  }

  Future<void> sendPasswordReset(String email) async {
    final current = state.valueOrNull;
    if (current is! LoginResetPassword) return;
    state = AsyncValue.data(current.copyWith(isSubmitting: true, error: null));
    final repo = ref.read(authRepositoryProvider);
    try {
      await repo.requestPasswordReset(email);
      state = AsyncValue.data(current.copyWith(isSubmitting: false, sent: true));
    } on ApiException catch (e) {
      state = AsyncValue.data(current.copyWith(isSubmitting: false, error: e.message));
    }
  }

  Future<void> logout() async {
    final repo = ref.read(authRepositoryProvider);
    await repo.logout();
    state = const AsyncValue.data(LoginState.enteringCredentials());
    resetPerUserUiState(ref);
  }
}

/// Derived convenience accessor — null until authenticated.
@riverpod
AppUser? currentUser(Ref ref) {
  final state = ref.watch(authControllerProvider).valueOrNull;
  return state is LoginAuthenticated ? state.user : null;
}
