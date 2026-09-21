import 'package:dio/dio.dart';

import '../api_client.dart';
import '../api_exception.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/signature.routes.js — one saved signature per
/// user (Settings -> My Signature).
class SignatureApi {
  SignatureApi(this._client);

  final ApiClient _client;

  Future<({bool hasSignature, String? updatedAt})> getMeta() async {
    final response = await _client.get(Endpoints.signatureMe);
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (hasSignature: json['hasSignature'] as bool, updatedAt: json['updatedAt'] as String?);
    });
  }

  /// Returns null if no signature is saved (404).
  Future<List<int>?> getImageBytes() async {
    try {
      final response = await _client.get(
        Endpoints.signatureMeImage,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data as List<int>?;
    } on ApiException catch (e) {
      if (e.statusCode == 404) return null;
      rethrow;
    }
  }

  Future<void> upload(List<int> pngBytes) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(pngBytes, filename: 'signature.png', contentType: DioMediaType.parse('image/png')),
    });
    final response = await _client.put(Endpoints.signatureMe, data: formData);
    _client.unwrap(response, (_) => null);
  }

  Future<void> delete() async {
    final response = await _client.delete(Endpoints.signatureMe);
    _client.unwrap(response, (_) => null);
  }
}
