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
  const ApiException({required this.message, this.statusCode, this.rawErrors});

  final String message;
  final int? statusCode;
  final dynamic rawErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
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
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(message: 'The connection to the server timed out.');
      case DioExceptionType.connectionError:
        return const ApiException(message: 'Could not reach the server. Check your network connection.');
      default:
        return ApiException(
          message: e.message ?? 'The request failed.',
          statusCode: e.response?.statusCode,
        );
    }
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
