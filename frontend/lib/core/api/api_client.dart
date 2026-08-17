import 'package:dio/dio.dart';

import '../env/env.dart';
import 'api_exception.dart';

/// Thin wrapper around a configured [Dio] instance. Resource classes call
/// [get]/[post]/[put]/[delete] (not `dio.get` etc directly) so that every
/// failure — network error, non-2xx response, whatever — surfaces to
/// callers as a plain [ApiException], never a [DioException]. (Dio always
/// throws its own [DioException] at the await point of a failed request;
/// stuffing an ApiException into `DioException.error` does NOT change what
/// gets thrown, so callers must unwrap it — that unwrapping happens once,
/// here, instead of in every catch clause across the app.)
///
/// Auth-related interceptors (JWT attach, 401 refresh-and-retry) are added
/// separately by core/auth/auth_providers.dart once the token store
/// exists, to avoid a circular dependency between the API layer and the
/// auth layer. They run inside Dio's own interceptor chain, so a request
/// that succeeds after a token refresh never reaches [_guard] as a
/// failure at all.
class ApiClient {
  ApiClient() : dio = _buildDio();

  final Dio dio;

  /// Set by core/api/api_providers.dart. Fired whenever a request fails
  /// with 403, so the router can navigate to /access-denied without this
  /// class needing to know about go_router.
  void Function(ApiException)? onForbidden;

  static Dio _buildDio() {
    return Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );
  }

  /// [silent403]: when true, a 403 on this call does NOT trigger the
  /// global onForbidden navigation — for calls used by widgets that
  /// already degrade gracefully in place (e.g. Dashboard's per-section
  /// previews, each independently gated and each rendering its own
  /// "not available for your role" message). Screens whose entire purpose
  /// IS the gated module (Repository, a future Reports screen, ...) should
  /// leave this false so a 403 sends the user to /access-denied.
  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool silent403 = false,
  }) {
    return _guard(() => dio.get<dynamic>(path, queryParameters: queryParameters, options: options), silent403: silent403);
  }

  Future<Response<dynamic>> post(String path, {dynamic data, Options? options, bool silent403 = false}) {
    return _guard(() => dio.post<dynamic>(path, data: data, options: options), silent403: silent403);
  }

  Future<Response<dynamic>> put(String path, {dynamic data, Options? options, bool silent403 = false}) {
    return _guard(() => dio.put<dynamic>(path, data: data, options: options), silent403: silent403);
  }

  Future<Response<dynamic>> delete(String path, {dynamic data, Options? options, bool silent403 = false}) {
    return _guard(() => dio.delete<dynamic>(path, data: data, options: options), silent403: silent403);
  }

  Future<Response<dynamic>> _guard(Future<Response<dynamic>> Function() request, {required bool silent403}) async {
    try {
      return await request();
    } on DioException catch (e) {
      final apiException = ApiException.fromDioException(e);
      if (apiException.isForbidden && !silent403) onForbidden?.call(apiException);
      throw apiException;
    }
  }

  /// Unwraps the backend's `{success, message, data}` envelope. Throws
  /// [ApiException] if `success` is false (shouldn't normally happen here —
  /// a non-2xx response is already converted to [ApiException] by [_guard]
  /// before this is reached — but some endpoints return `success:false`
  /// with a 200 status in edge cases).
  T unwrap<T>(Response<dynamic> response, T Function(dynamic data) parse) {
    final body = response.data;
    if (body is Map<String, dynamic> && body.containsKey('success')) {
      if (body['success'] == true) {
        return parse(body['data']);
      }
      throw ApiException(
        message: (body['message'] as String?) ?? 'Request failed',
        statusCode: response.statusCode,
        rawErrors: body['errors'],
      );
    }
    return parse(body);
  }

  /// Unwraps a list response into a typed list.
  List<T> unwrapList<T>(Response<dynamic> response, T Function(Map<String, dynamic> json) fromJson) {
    return unwrap(response, (data) {
      if (data is! List) return <T>[];
      return data.whereType<Map<String, dynamic>>().map(fromJson).toList(growable: false);
    });
  }
}
