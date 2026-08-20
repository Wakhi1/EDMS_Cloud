import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh token persistence for the platform-admin identity —
/// deliberately separate storage keys from core/auth/secure_token_store.dart
/// so a tenant session and a platform-admin session can coexist in the same
/// browser without colliding.
class PlatformAdminTokenStore {
  const PlatformAdminTokenStore([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;

  static const _accessKey = 'pspf_edms.platform_admin.access_token';
  static const _refreshKey = 'pspf_edms.platform_admin.refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) {
    return Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<void> saveAccessToken(String accessToken) => _storage.write(key: _accessKey, value: accessToken);

  Future<String?> readAccessToken() => _readOrNull(_accessKey);

  Future<String?> readRefreshToken() => _readOrNull(_refreshKey);

  Future<String?> _readOrNull(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() {
    return Future.wait([
      _storage.delete(key: _accessKey),
      _storage.delete(key: _refreshKey),
    ]);
  }
}
