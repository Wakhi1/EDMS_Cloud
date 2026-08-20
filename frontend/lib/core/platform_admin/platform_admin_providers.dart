import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import '../auth/auth_interceptors.dart';
import 'models/platform_admin_profile.dart';
import 'platform_admin_api.dart';
import 'platform_admin_token_store.dart';

final platformAdminTokenStoreProvider = Provider<PlatformAdminTokenStore>((ref) => const PlatformAdminTokenStore());

/// A second, fully independent [ApiClient] — own Dio instance, own
/// interceptors, own token store, own refresh endpoint — so a
/// platform-admin session never shares state with a tenant session (see
/// core/api/api_providers.dart's apiClientProvider for the tenant one).
final platformAdminApiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient();
  final tokenStore = ref.watch(platformAdminTokenStoreProvider);
  final api = PlatformAdminApi(client);

  configureAuthInterceptors(
    client.dio,
    getAccessToken: tokenStore.readAccessToken,
    getRefreshToken: tokenStore.readRefreshToken,
    refresh: (refreshToken) async {
      final newAccessToken = await api.refresh(refreshToken);
      await tokenStore.saveAccessToken(newAccessToken);
      return newAccessToken;
    },
    onRefreshFailed: () async {
      await tokenStore.clear();
      ref.read(platformAdminAuthControllerProvider.notifier).forceSignOut();
    },
    refreshPath: '/api/platform-admin/auth/refresh',
  );

  client.onForbidden = (_) {
    // A 403 here means "not a platform admin" (or a stale/foreign token) —
    // no separate access-denied screen for this small module, straight
    // back to its own login.
    ref.read(platformAdminAuthControllerProvider.notifier).forceSignOut();
  };

  return client;
});

final platformAdminApiProvider = Provider<PlatformAdminApi>((ref) => PlatformAdminApi(ref.watch(platformAdminApiClientProvider)));

/// null = signed out, non-null = signed in as that admin. Deliberately a
/// plain `AsyncNotifier<PlatformAdminProfile?>` rather than a sealed state
/// machine like core/auth/auth_state.dart's LoginState — there's no MFA
/// step here, so "signed in or not" is the whole story.
class PlatformAdminAuthController extends AsyncNotifier<PlatformAdminProfile?> {
  @override
  Future<PlatformAdminProfile?> build() async {
    final tokenStore = ref.watch(platformAdminTokenStoreProvider);
    final token = await tokenStore.readAccessToken();
    if (token == null || token.isEmpty) return null;
    try {
      return await ref.read(platformAdminApiProvider).me();
    } on ApiException {
      return null;
    }
  }

  Future<void> login({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final result = await ref.read(platformAdminApiProvider).login(email: email, password: password);
      await ref.read(platformAdminTokenStoreProvider).saveTokens(accessToken: result.accessToken, refreshToken: result.refreshToken);
      state = AsyncData(result.admin);
    } on ApiException catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> logout() async {
    final tokenStore = ref.read(platformAdminTokenStoreProvider);
    final refreshToken = await tokenStore.readRefreshToken();
    try {
      await ref.read(platformAdminApiProvider).logout(refreshToken);
    } on ApiException {
      // best-effort — clear local state regardless
    }
    await tokenStore.clear();
    state = const AsyncData(null);
  }

  /// Called by the interceptor on a failed silent refresh — clears state
  /// without another network round-trip (tokens are already gone/invalid).
  void forceSignOut() {
    state = const AsyncData(null);
  }
}

final platformAdminAuthControllerProvider = AsyncNotifierProvider<PlatformAdminAuthController, PlatformAdminProfile?>(
  PlatformAdminAuthController.new,
);
