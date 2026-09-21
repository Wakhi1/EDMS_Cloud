import 'package:dio/dio.dart';

/// A field-level validation error, matching express-validator's
/// `{msg, param, location, ...}` shape returned in a 422 response's `errors`
/// array.
class FieldError {
  const FieldError({required this.param, required this.message});

  final String param;
  final String message;

  factory FieldError.fromJson(Map<String, dynamic> json) {
    return FieldError(
      param: (json['param'] ?? json['path'] ?? '') as String,
      message: (json['msg'] ?? json['message'] ?? 'Invalid value') as String,
    );
  }
}

/// Typed wrapper around the backend's `{success:false, message, errors}`
/// envelope (see backend/utils/apiResponse.js), plus network-level failures
/// (timeout, no connection) that never reached the server at all.
class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.rawErrors, this.debugInfo});

  final String message;
  final int? statusCode;
  final dynamic rawErrors;

  /// TEMPORARY diagnostic field — the raw [DioExceptionType] plus the
  /// underlying platform error's toString() (a SocketException,
  /// HandshakeException, etc.), for the "can't reach the server" case
  /// where [message] is deliberately a generic, user-facing translation
  /// that collapses several very different underlying failures into one
  /// sentence. Surfaced in the login screen's connectivity banner
  /// (core/diagnostics/connectivity_gate_provider.dart) while tracking
  /// down why physical devices can't reach a host curl/Chrome/the
  /// emulator all reach fine. Remove once that's root-caused.
  final String? debugInfo;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isConflict => statusCode == 409;
  bool get isLocked => statusCode == 423;
  bool get isValidation => statusCode == 422;

  List<FieldError> get fieldErrors {
    final errors = rawErrors;
    if (errors is! List) return const [];
    return errors
        .whereType<Map<String, dynamic>>()
        .map(FieldError.fromJson)
        .toList(growable: false);
  }

  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data['message'] is String) {
      return ApiException(
        message: data['message'] as String,
        statusCode: e.response?.statusCode,
        rawErrors: data['errors'],
      );
    }
    final debugInfo = '${e.type}: ${e.error ?? e.message}';
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(message: 'The connection to the server timed out.', debugInfo: debugInfo);
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'Could not reach the server. Check your network connection.',
          debugInfo: debugInfo,
        );
      default:
        return ApiException(
          message: e.message ?? 'The request failed.',
          statusCode: e.response?.statusCode,
          debugInfo: debugInfo,
        );
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
