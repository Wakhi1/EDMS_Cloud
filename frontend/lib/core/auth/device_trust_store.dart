import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'mfa_method.dart';

/// Purely a local UI convenience — remembers "trust this device" on THIS
/// machine only, to skip the MFA method-choice screen on the next login.
/// There is no backend "trusted device" concept: the server still requires
/// a full second-factor verification on every login regardless of this
/// flag. Never treat this as a security control.
class DeviceTrustStore {
  DeviceTrustStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _trustedKey = 'pspf_edms.device_trusted';
  static const _methodKey = 'pspf_edms.device_trusted_method';

  Future<void> trust(MfaMethod method) {
    return Future.wait([
      _storage.write(key: _trustedKey, value: 'true'),
      _storage.write(key: _methodKey, value: method.name),
    ]);
  }

  Future<void> clear() {
    return Future.wait([
      _storage.delete(key: _trustedKey),
      _storage.delete(key: _methodKey),
    ]);
  }

  /// Returns the remembered method if this device is trusted, else null.
  Future<MfaMethod?> readTrustedMethod() async {
    final trusted = await _storage.read(key: _trustedKey);
    if (trusted != 'true') return null;
    final methodName = await _storage.read(key: _methodKey);
    for (final method in MfaMethod.values) {
      if (method.name == methodName) return method;
    }
    return null;
  }
}

final deviceTrustStoreProvider = Provider<DeviceTrustStore>((ref) => DeviceTrustStore());
