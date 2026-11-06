import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/game_installer.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/server_list.dart';
import 'package:bc_launcher/services/sync_engine.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

enum EntryStep { downloading, installing, updating, checking }

/// The game files (Minecraft, loader, Java) could not be prepared.
class GameFilesError implements Exception {
  final Object cause;

  const GameFilesError(this.cause);

  @override
  String toString() => "GameFilesError($cause)";
}

/// Leaves an instance ready to enter: downloaded, installed and up to date.
class InstanceInstaller {
  @visibleForTesting
  static Future<void> Function(
    Manifest manifest,
    Directory folder,
    void Function(double progress)? onProgress,
  )
  prepareGame = _prepareGame;

  /// Does what [instance] needs: installs it, updates it, or checks it and
  /// repairs whatever the player changed or deleted. Throws
  /// [NotEnoughSpaceError], [GameFilesError], [ApiError] or the download's
  /// error; what was done is kept, so trying again resumes.
  static Future<void> enter(
    ApiClient client,
    String organizationKey,
    Instance instance, {
    void Function(EntryStep step)? onStep,
    void Function(SyncProgress progress)? onSyncProgress,
    void Function(double progress)? onInstallProgress,
  }) async {
    try {
      await _run(
        client,
        organizationKey,
        instance,
        onStep: onStep,
        onSyncProgress: onSyncProgress,
        onInstallProgress: onInstallProgress,
      );
    } catch (e) {
      final cause = e is GameFilesError ? e.cause : e;
      if (!isOffline(cause)) rethrow;

      final state = await InstanceManager.readState(
        organizationKey,
        instance.id,
      );
      final status = InstanceManager.statusOf(instance, state);
      if (status != InstallStatus.upToDate) rethrow;
    }
  }

  /// Before playing: like [enter], but without connection it always fails,
  /// so the game never starts unrepaired. Returns the version to launch.
  static Future<String> play(
    ApiClient client,
    String organizationKey,
    Instance instance,
  ) => _run(client, organizationKey, instance);

  /// Returns the version to launch.
  static Future<String> _run(
    ApiClient client,
    String organizationKey,
    Instance instance, {
    void Function(EntryStep step)? onStep,
    void Function(SyncProgress progress)? onSyncProgress,
    void Function(double progress)? onInstallProgress,
  }) async {
    final id = instance.id;
    final state = await InstanceManager.readState(organizationKey, id);
    final status = InstanceManager.statusOf(instance, state);

    final firstTime = status == InstallStatus.notInstalled;
    var serverEntry = state?.serverEntryAddress;
    final installedAt = state?.installedAt ?? DateTime.now();
    if (firstTime) {
      onStep?.call(EntryStep.downloading);
      await InstanceManager.writeState(
        organizationKey,
        id,
        InstanceState(
          contentVersion: instance.contentVersion,
          minecraftVersion: instance.minecraftVersion,
          loaderType: instance.loaderType,
          loaderVersion: instance.loaderVersion,
          complete: false,
          serverEntryAddress: serverEntry,
          instance: instance,
          installedAt: installedAt,
        ),
      );
    } else if (status == InstallStatus.updateAvailable) {
      onStep?.call(EntryStep.updating);
    } else {
      onStep?.call(EntryStep.checking);
    }

    final manifest = await SyncEngine.sync(
      client,
      organizationKey,
      id,
      onProgress: onSyncProgress,
    );
    final folder = await InstanceManager.instanceFolder(organizationKey, id);

    final newEntry = await _updateServerList(
      folder,
      instance.name,
      manifest,
      serverEntry,
      firstTime: firstTime,
    );
    if (newEntry != serverEntry) {
      serverEntry = newEntry;
      final current = await InstanceManager.readState(organizationKey, id);
      if (current != null) {
        await InstanceManager.writeState(
          organizationKey,
          id,
          _withServerEntry(current, serverEntry),
        );
      }
    }

    if (firstTime) onStep?.call(EntryStep.installing);
    try {
      await prepareGame(manifest, folder, onInstallProgress);
    } catch (e) {
      throw GameFilesError(e);
    }

    await InstanceManager.writeState(
      organizationKey,
      id,
      InstanceState(
        contentVersion: manifest.contentVersion,
        minecraftVersion: manifest.minecraftVersion,
        loaderType: manifest.loaderType,
        loaderVersion: manifest.loaderVersion,
        complete: true,
        serverEntryAddress: serverEntry,
        instance: instance,
        installedAt: installedAt,
      ),
    );
    return GameInstaller.versionIdOf(manifest);
  }

  static bool isOffline(Object error) => switch (error) {
    ApiError(type: ApiErrorType.offline || ApiErrorType.serverUnavailable) =>
      true,
    DioException(:final response) =>
      response == null || (response.statusCode ?? 0) >= 500,
    SocketException() => true,
    _ => false,
  };

  /// Adds the instance's server to `servers.dat` the first time, when the
  /// content doesn't bring one, and moves the entry the launcher wrote when
  /// the address changes. Returns the address of that entry.
  static Future<String?> _updateServerList(
    Directory folder,
    String name,
    Manifest manifest,
    String? serverEntry, {
    required bool firstTime,
  }) async {
    final address = manifest.serverAddress;
    if (address == null || address == serverEntry) return serverEntry;

    final file = File(join(folder.path, "servers.dat"));
    if (serverEntry == null) {
      final fromContent = manifest.files.any((f) => f.path == "servers.dat");
      if (!firstTime || fromContent || await file.exists()) return null;

      await ServerList.create(file, name, address);
      return address;
    }

    final moved = await ServerList.replaceAddress(file, serverEntry, address);
    return moved ? address : serverEntry;
  }

  static InstanceState _withServerEntry(InstanceState state, String? entry) {
    return InstanceState(
      contentVersion: state.contentVersion,
      minecraftVersion: state.minecraftVersion,
      loaderType: state.loaderType,
      loaderVersion: state.loaderVersion,
      complete: state.complete,
      serverEntryAddress: entry,
      instance: state.instance,
      installedAt: state.installedAt,
    );
  }

  static Future<void> _prepareGame(
    Manifest manifest,
    Directory folder,
    void Function(double progress)? onProgress,
  ) => GameInstaller.install(manifest, folder, onProgress: onProgress);
}
