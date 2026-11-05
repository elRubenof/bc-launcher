import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the Microsoft OAuth credentials (access and refresh token) in the
/// platform's secure storage: Keychain on macOS, DPAPI on Windows and
/// libsecret on Linux.
class CredentialsStore {
  static const String _key = "credentials";

  // The legacy Keychain works with the ad-hoc signed macOS build; the data
  // protection Keychain needs a Keychain Sharing entitlement and a team ID.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );

  /// The stored credentials JSON, or `null` when there is no session or the
  /// secure storage can't be used (e.g. no keyring service on Linux).
  static Future<String?> read() async {
    try {
      final stored = await _storage.read(key: _key);
      return stored == null || stored.isEmpty ? null : stored;
    } catch (e) {
      log("Could not read the credentials: ${e.runtimeType}");
      return null;
    }
  }

  /// Saves [json]. Fails if the secure storage can't be used: the
  /// credentials are never written in plain text.
  static Future<void> write(String json) async {
    await _storage.write(key: _key, value: json);
  }

  static Future<void> clear() async {
    try {
      await _storage.delete(key: _key);
    } catch (e) {
      log("Could not delete the credentials: ${e.runtimeType}");
    }
  }
}
