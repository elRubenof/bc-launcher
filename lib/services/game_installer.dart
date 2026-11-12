import 'dart:convert';
import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/services/asset_manager.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/services/forge_installer.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/java_manager.dart';
import 'package:bc_launcher/services/library_manager.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_core.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

/// Mojang doesn't list [version].
class UnknownMinecraftVersionError implements Exception {
  final String version;

  const UnknownMinecraftVersionError(this.version);

  @override
  String toString() => "UnknownMinecraftVersionError($version)";
}

/// The loader doesn't have [version] for this Minecraft version.
class UnknownLoaderVersionError implements Exception {
  final LoaderType loader;
  final String? version;

  const UnknownLoaderVersionError(this.loader, this.version);

  @override
  String toString() => "UnknownLoaderVersionError(${loader.name}, $version)";
}

/// Installs the game files an instance needs, which organizations never serve.
/// Libraries, assets and Java are shared by every instance.
class GameInstaller {
  static const versionManifestUrl =
      "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json";

  /// The meta APIs of the loaders it can install, which give a version JSON
  /// (profile) that inherits from Minecraft's.
  static const loaderMeta = {
    LoaderType.fabric: "https://meta.fabricmc.net/v2/versions/loader",
    LoaderType.quilt: "https://meta.quiltmc.org/v3/versions/loader",
  };

  /// What Java needs to download (tests replace it).
  @visibleForTesting
  static Future<JavaPlan> Function(Map versionData, Directory runtimesDir)
  planJava = JavaManager.planRuntime;

  static Future<String> install(
    Manifest manifest,
    Directory folder, {
    void Function(double progress)? onProgress,
  }) async {
    final loader = manifest.loaderType;
    final forge =
        !loaderMeta.containsKey(loader) && loader != LoaderType.vanilla;

    await _ensureVersionJson(manifest.minecraftVersion, folder);

    final versionId = versionIdOf(manifest);
    final shared = await InstanceManager.sharedFolder();
    final runtimes = Directory(join(shared.path, "runtime"));

    // Running the Forge and NeoForge installer takes the first half of the
    // bar, when it has to run.
    var installerShare = 0.0;
    if (forge) {
      final version = manifest.loaderVersion;
      if (version == null) throw UnknownLoaderVersionError(loader, version);

      if (!await ForgeInstaller.isInstalled(versionId, folder, shared)) {
        installerShare = 0.5;
      }
      await ForgeInstaller.install(
        loader,
        manifest.minecraftVersion,
        version,
        folder,
        shared,
        java: (versionData) => _ensureJava(versionData, runtimes),
        onProgress: (progress) => onProgress?.call(progress * installerShare),
      );
    } else if (loader != LoaderType.vanilla) {
      await _ensureLoaderProfile(manifest, versionId, folder);
    }

    final versionData = await MinecraftLauncherCore.loadVersionData(
      versionId,
      folder.path,
    );

    // Libraries, client jar, assets and Java in one download, so the bar
    // follows the bytes that are really missing.
    final parts = [
      await LibraryManager.plan(versionData, folder, sharedRoot: shared),
      await AssetManager.plan(versionData, shared, folder),
      await planJava(versionData, runtimes),
    ];
    await FileDownloader.downloadAll(
      [for (final part in parts) ...part.tasks],
      onProgress: (progress) =>
          onProgress?.call(installerShare + (1 - installerShare) * progress),
    );
    for (final part in parts) {
      await part.finish();
    }

    onProgress?.call(1);
    return versionId;
  }

  /// Java for the Forge and NeoForge processors.
  static Future<String> _ensureJava(Map versionData, Directory runtimes) async {
    final java = await planJava(versionData, runtimes);
    await FileDownloader.downloadAll(java.tasks);
    await java.finish();
    return java.executable;
  }

  /// The version to launch: Minecraft's, or the loader's, named as its
  /// installer names it (`fabric-loader-0.16.5-1.21.1`, `1.20.1-forge-47.3.0`,
  /// `neoforge-21.1.77`).
  static String versionIdOf(Manifest manifest) => versionIdFor(
    manifest.loaderType,
    manifest.minecraftVersion,
    manifest.loaderVersion,
  );

  /// Like [versionIdOf], from the versions an installation saved.
  static String versionIdFor(
    LoaderType loader,
    String minecraft,
    String? version,
  ) {
    return switch (loader) {
      LoaderType.vanilla => minecraft,
      LoaderType.forge || LoaderType.neoforge => ForgeInstaller.versionId(
        loader,
        minecraft,
        version ?? "",
      ),
      _ => "${loader.name}-loader-$version-$minecraft",
    };
  }

  /// Saves the loader's profile as `versions/<id>/<id>.json` unless it is
  /// already there.
  static Future<void> _ensureLoaderProfile(
    Manifest manifest,
    String id,
    Directory folder,
  ) async {
    final file = File(join(folder.path, "versions", id, "$id.json"));
    if (await _isJson(file)) return;

    final loader = manifest.loaderType;
    final version = manifest.loaderVersion;
    if (version == null) throw UnknownLoaderVersionError(loader, version);

    final Map profile;
    try {
      final minecraft = Uri.encodeComponent(manifest.minecraftVersion);
      profile =
          (await FileDownloader.dio.get(
                "${loaderMeta[loader]}/$minecraft/${Uri.encodeComponent(version)}"
                "/profile/json",
              )).data
              as Map;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 400 || status == 404) {
        throw UnknownLoaderVersionError(loader, version);
      }
      rethrow;
    }

    // Launched by this name, whatever the profile says.
    profile['id'] = id;
    await file.parent.create(recursive: true);
    final part = File("${file.path}.part");
    await part.writeAsString(jsonEncode(profile));
    await part.rename(file.path);
  }

  /// Downloads `versions/<version>/<version>.json` from Mojang unless it is
  /// already there.
  static Future<void> _ensureVersionJson(
    String version,
    Directory folder,
  ) async {
    final file = File(join(folder.path, "versions", version, "$version.json"));
    if (await _isJson(file)) return;

    final manifest =
        (await FileDownloader.dio.get(versionManifestUrl)).data as Map;
    final entry = (manifest['versions'] as List).cast<Map>().where(
      (entry) => entry['id'] == version,
    );
    if (entry.isEmpty) throw UnknownMinecraftVersionError(version);

    await FileDownloader.downloadAll([
      DownloadTask(
        path: file.path,
        url: entry.first['url'],
        sha1: entry.first['sha1'],
      ),
    ]);
  }

  static Future<bool> _isJson(File file) async {
    try {
      jsonDecode(await file.readAsString());
      return true;
    } catch (_) {
      return false;
    }
  }
}
