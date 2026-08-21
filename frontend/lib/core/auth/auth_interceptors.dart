import 'package:dio/dio.dart';

import '../api/endpoints.dart';

typedef TokenGetter = Future<String?> Function();
typedef RefreshFn = Future<String> Function(String refreshToken);
typedef AsyncVoidCallback = Future<void> Function();

/// Adds two interceptors to [dio]:
///  1. Attaches `Authorization: Bearer <accessToken>` to every request.
///  2. On 401, refreshes the access token exactly once for any number of
///     concurrent failing requests (single-flight), retries each original
///     request with the new token, and calls [onRefreshFailed] (which
///     clears tokens and signals the rest of the app via
///     core/auth/session_events.dart) if the refresh itself fails.
void configureAuthInterceptors(
  Dio dio, {
  required TokenGetter getAccessToken,
  required TokenGetter getRefreshToken,
  required RefreshFn refresh,
  required AsyncVoidCallback onRefreshFailed,
  // Overridable so a second Dio instance wired against a different
  // refresh endpoint can reuse this same interceptor without an infinite loop.
  String refreshPath = Endpoints.authRefresh,
}) {
  Future<String?>? inFlightRefresh;

  Future<String?> refreshOnce() {
    if (inFlightRefresh != null) return inFlightRefresh!;
    final future = () async {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) return null;
      return refresh(refreshToken);
    }();
    inFlightRefresh = future;
    // Clear the in-flight marker once settled (success or failure) so a
    // later 401 (e.g. next session) triggers a fresh refresh attempt.
    future.whenComplete(() => inFlightRefresh = null);
    return future;
  }

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Don't clobber an explicit Authorization header a caller already
        // set (e.g. mfa_api.dart's login-time challenge/verify calls, which
        // authenticate with the short-lived mfaToken instead of the normal
        // session access token).
        if (!options.headers.containsKey('Authorization')) {
          final token = await getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final isRefreshCall = error.requestOptions.path == refreshPath;
        if (error.response?.statusCode != 401 || isRefreshCall) {
          return handler.next(error);
        }

        String? newToken;
        try {
          newToken = await refreshOnce();
        } catch (_) {
          newToken = null;
        }

        if (newToken == null) {
          await onRefreshFailed();
          return handler.next(error);
        }

        try {
          final retryOptions = error.requestOptions;
          retryOptions.headers['Authorization'] = 'Bearer $newToken';
          final response = await dio.fetch<dynamic>(retryOptions);
          return handler.resolve(response);
        } on DioException catch (retryError) {
          return handler.next(retryError);
        }
      },
    ),
  );
}
