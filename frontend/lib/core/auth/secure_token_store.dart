import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Access/refresh token persistence. Keychain/Keystore-backed on
/// mobile/desktop, DPAPI on Windows, falls back to browser storage on web
/// (acceptable for local dev against localhost; a hardened web deployment
/// should reassess this — JS-accessible storage is vulnerable to XSS token
/// theft — as a follow-up security pass, not a Phase 1 blocker).
class SecureTokenStore {
  SecureTokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _accessKey = 'pspf_edms.access_token';
  static const _refreshKey = 'pspf_edms.refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) {
    return Future.wait([
      _storage.write(key: _accessKey, value: accessToken),
      _storage.write(key: _refreshKey, value: refreshToken),
    ]);
  }

  Future<void> saveAccessToken(String accessToken) => _storage.write(key: _accessKey, value: accessToken);

  Future<String?> readAccessToken() => _readOrNull(_accessKey);

  Future<String?> readRefreshToken() => _readOrNull(_refreshKey);

  /// `flutter_secure_storage`'s own docs promise `read()` "returns null ...
  /// if decryption fails", but on web its AES-GCM decrypt only catches
  /// `Exception` — a raw DOMException like `OperationError` (thrown by
  /// `crypto.subtle.decrypt` when its IndexedDB-held key desyncs from the
  /// encrypted blob in localStorage) isn't an `Exception` and slips through
  /// uncaught. Every authenticated request depends on this read (the auth
  /// interceptor calls it on every call, plus cold start), so treat an
  /// unreadable/corrupted stored token the same as "no token" everywhere,
  /// not just at one call site.
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

final secureTokenStoreProvider = Provider<SecureTokenStore>((ref) => SecureTokenStore());
