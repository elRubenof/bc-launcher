import 'dart:convert';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The signed-in player's profile and Minecraft token, so the launcher can
/// start and play without internet, and skip the Xbox sign-in while the
/// token is valid.
class MinecraftSession {
  final String uuid;
  final String name;
  final String token;
  final DateTime expiresAt;

  const MinecraftSession({
    required this.uuid,
    required this.name,
    required this.token,
    required this.expiresAt,
  });

  /// Minecraft tokens last 24 h; it is renewed a little before.
  static const lifetime = Duration(hours: 23);

  factory MinecraftSession.fresh({
    required String uuid,
    required String name,
    required String token,
  }) => MinecraftSession(
    uuid: uuid,
    name: name,
    token: token,
    expiresAt: DateTime.now().add(lifetime),
  );

  bool get isExpired => !DateTime.now().isBefore(expiresAt);

  factory MinecraftSession.fromJson(Map<String, dynamic> json) {
    return MinecraftSession(
      uuid: json['uuid'],
      name: json['name'],
      token: json['token'],
      expiresAt: DateTime.parse(json['expiresAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'token': token,
    'expiresAt': expiresAt.toUtc().toIso8601String(),
  };
}

/// Keeps the [MinecraftSession] in the platform's secure storage, like the
/// Microsoft credentials.
class MinecraftSessionStore {
  static const String _key = "minecraft_session";

  static FlutterSecureStorage storage = const FlutterSecureStorage(
    mOptions: MacOsOptions(usesDataProtectionKeychain: false),
  );

  /// The saved session, or `null` when there is none or it can't be read.
  static Future<MinecraftSession?> read() async {
    try {
      final stored = await storage.read(key: _key);
      if (stored == null || stored.isEmpty) return null;
      return MinecraftSession.fromJson(
        jsonDecode(stored) as Map<String, dynamic>,
      );
    } catch (e) {
      log("Could not read the Minecraft session: ${e.runtimeType}");
      return null;
    }
  }

  static Future<void> write(MinecraftSession session) async {
    try {
      await storage.write(key: _key, value: jsonEncode(session.toJson()));
    } catch (e) {
      log("Could not save the Minecraft session: ${e.runtimeType}");
    }
  }

  static Future<void> clear() async {
    try {
      await storage.delete(key: _key);
    } catch (e) {
      log("Could not delete the Minecraft session: ${e.runtimeType}");
    }
  }
}
