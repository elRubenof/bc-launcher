import 'dart:developer';

import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/services/token_store.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:dio/dio.dart';

/// Mojang refused or couldn't take the `join`: [offline] when it couldn't
/// be reached, otherwise the Minecraft session is no longer valid.
class MinecraftJoinError implements Exception {
  final bool offline;
  final int? status;

  const MinecraftJoinError({required this.offline, this.status});

  @override
  String toString() => "MinecraftJoinError(offline: $offline, status: $status)";
}

/// Signs the player in to organizations with Mojang's handshake, so the
/// Minecraft token never leaves the launcher.
class OrganizationAuth {
  static const _joinUrl =
      "https://sessionserver.mojang.com/session/minecraft/join";

  static final _mojang = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );

  /// An [ApiClient] for [organization] that uses its saved token and signs
  /// in again by itself when the token is missing, expired or refused.
  static ApiClient clientFor(Organization organization) {
    late final ApiClient client;
    client = ApiClient(
      organization,
      getToken: () async =>
          await TokenStore.token(organization.key) ?? await signIn(client),
      renewToken: () => signIn(client),
      renegotiate: () => _renegotiate(organization),
    );
    return client;
  }

  /// Reads the discovery again after a `426` and keeps the organization
  /// saved with the new version. Throws [ApiError] (`incompatible`) when no
  /// version is shared any more.
  static Future<Organization> _renegotiate(Organization organization) async {
    final fresh = await ApiClient.discovery(organization.url);
    if (OrganizationStore.byKey(fresh.key) != null) {
      await OrganizationStore.save(fresh);
    }
    return fresh;
  }

  /// `challenge` → Mojang's `join` → `verify`, and saves the token. Throws
  /// [ApiError] (e.g. `notMember`) or [MinecraftJoinError].
  static Future<String> signIn(ApiClient client) async {
    final serverId = await client.challenge();

    final token = await Minecraft.getToken();
    final profile = Minecraft.profile.value!;
    await _join(token, profile.uuid, serverId);

    final session = await client.verify(
      username: profile.name,
      serverId: serverId,
    );
    await TokenStore.save(
      client.organization.key,
      token: session.token,
      expiresAt: session.expiresAt,
    );
    return session.token;
  }

  /// Tells Mojang the player joins the server [serverId]; the organization
  /// then checks it with `hasJoined`. Done in every `auth.type`, so nothing
  /// changes if the organization starts verifying.
  static Future<void> _join(
    String minecraftToken,
    String uuid,
    String serverId,
  ) async {
    try {
      await _mojang.post(
        _joinUrl,
        data: {
          'accessToken': minecraftToken,
          'selectedProfile': uuid.replaceAll('-', ''),
          'serverId': serverId,
        },
      );
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      log("Mojang join failed: ${status ?? e.type.name}");
      throw MinecraftJoinError(offline: status == null, status: status);
    }
  }
}
