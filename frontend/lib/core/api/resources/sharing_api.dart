import '../../models/share_link.dart';
import '../../models/share_public_info.dart';
import '../api_client.dart';
import '../endpoints.dart';

/// Mirrors backend/routes/sharing.routes.js. The public/* methods need no
/// auth token at all — same [ApiClient] works either way, it just won't
/// have anything to attach for a recipient who was never logged in.
class SharingApi {
  SharingApi(this._client);

  final ApiClient _client;

  Future<List<ShareLink>> list() async {
    final response = await _client.get(Endpoints.sharing);
    return _client.unwrapList(response, ShareLink.fromJson);
  }

  Future<({String token, String expiresAt})> create({required int documentId, required int expiresInHours}) async {
    final response = await _client.post(Endpoints.sharing, data: {'documentId': documentId, 'expiresInHours': expiresInHours});
    return _client.unwrap(response, (data) {
      final json = data as Map<String, dynamic>;
      return (token: json['token'] as String, expiresAt: json['expiresAt'] as String);
    });
  }

  Future<void> revoke(int id) async {
    final response = await _client.delete(Endpoints.shareLinkById('$id'));
    _client.unwrap(response, (_) => null);
  }

  Future<SharePublicInfo> publicInfo(String token) async {
    final response = await _client.get(Endpoints.sharePublicInfo(token));
    return _client.unwrap(response, (data) => SharePublicInfo.fromJson(data as Map<String, dynamic>));
  }

  /// Absolute URL for the content endpoint — the public share page links
  /// straight to this (a normal browser download/open), it doesn't route
  /// the bytes through Dio.
  String publicContentUrl(String token) => Endpoints.sharePublicContentAbsolute(token);
}
