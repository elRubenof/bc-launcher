import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps each organization's token (from `POST /auth/verify`) in the
/// platform's secure storage, keyed by [Organization.key]. All of them go in
/// one entry, so macOS asks for Keychain access once, not per organization.
class TokenStore {
  static const String _key = "organization_tokens";

  /// A token this close to expiring is treated as expired, so a request
  /// doesn't start with a token that runs out on the way.
  static const _margin = Duration(minutes: 5);

  // Same options as CredentialsStore: the legacy Keychain works with the
  // ad-hoc signed macOS build.
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );

  static Map<String, ({String token, DateTime expiresAt})>? _tokens;

  /// The organization's token, or `null` when there is none or it expired:
  /// then the player has to sign in to the organization again.
  static Future<String?> token(String organizationKey) async {
    final saved = (await _load())[organizationKey];
    if (saved == null) return null;
    if (DateTime.now().add(_margin).isAfter(saved.expiresAt)) return null;
    return saved.token;
  }

  /// Saves the organization's token, replacing the previous one. Fails if
  /// the secure storage can't be used: tokens are never written in plain
  /// text.
  static Future<void> save(
    String organizationKey, {
    required String token,
    required DateTime expiresAt,
  }) async {
    final tokens = {...await _load()};
    tokens[organizationKey] = (token: token, expiresAt: expiresAt);
    await _write(tokens);
  }

  static Future<void> delete(String organizationKey) async {
    final tokens = {...await _load()};
    if (tokens.remove(organizationKey) == null) return;
    try {
      await _write(tokens);
    } catch (e) {
      log("Could not delete the organization token: ${e.runtimeType}");
    }
  }

  static Future<Map<String, ({String token, DateTime expiresAt})>>
  _load() async {
    final cached = _tokens;
    if (cached != null) return cached;

    final tokens = <String, ({String token, DateTime expiresAt})>{};
    try {
      final stored = await _storage.read(key: _key);
      if (stored != null && stored.isNotEmpty) {
        final json = jsonDecode(stored) as Map<String, dynamic>;
        for (final MapEntry(:key, :value) in json.entries) {
          final item = value as Map<String, dynamic>;
          tokens[key] = (
            token: item['token'] as String,
            expiresAt: DateTime.parse(item['expiresAt'] as String),
          );
        }
      }
    } catch (e) {
      // Never log the stored value: it holds the tokens.
      log("Could not read the organization tokens: ${e.runtimeType}");
    }
    return _tokens = tokens;
  }

  static Future<void> _write(
    Map<String, ({String token, DateTime expiresAt})> tokens,
  ) async {
    await _storage.write(
      key: _key,
      value: jsonEncode({
        for (final MapEntry(:key, :value) in tokens.entries)
          key: {
            'token': value.token,
            'expiresAt': value.expiresAt.toUtc().toIso8601String(),
          },
      }),
    );
    _tokens = tokens;
  }
}
