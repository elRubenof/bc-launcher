import 'dart:convert';
import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/services/asset_manager.dart';
import 'package:bc_launcher/services/file_downloader.dart';
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

/// The instance's loader can't be installed by this launcher yet.
class UnsupportedLoaderError implements Exception {
  final LoaderType loader;

  const UnsupportedLoaderError(this.loader);

  @override
  String toString() => "UnsupportedLoaderError(${loader.name})";
}

/// Fabric or Quilt don't have [version] of their loader for this Minecraft.
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

  /// Installs Java (tests replace it).
  @visibleForTesting
  static Future<String> Function(
    Map versionData,
    Directory runtimesDir, {
    void Function(double progress)? onProgress,
  })
  ensureJava = JavaManager.ensureRuntime;

  static Future<String> install(
    Manifest manifest,
    Directory folder, {
    void Function(double progress)? onProgress,
  }) async {
    final loader = manifest.loaderType;
    if (loader != LoaderType.vanilla && !loaderMeta.containsKey(loader)) {
      throw UnsupportedLoaderError(loader);
    }

    const steps = 3;
    void Function(double) step(int index) =>
        (progress) => onProgress?.call((index + progress) / steps);

    await _ensureVersionJson(manifest.minecraftVersion, folder);

    final versionId = versionIdOf(manifest);
    if (loader != LoaderType.vanilla) {
      await _ensureLoaderProfile(manifest, versionId, folder);
    }

    final versionData = await MinecraftLauncherCore.loadVersionData(
      versionId,
      folder.path,
    );

    final shared = await InstanceManager.sharedFolder();
    await LibraryManager.ensureLibraries(
      versionData,
      folder,
      sharedRoot: shared,
      onProgress: step(0),
    );

    await AssetManager.ensureAssets(
      versionData,
      shared,
      folder,
      onProgress: step(1),
    );

    await ensureJava(
      versionData,
      Directory(join(shared.path, "runtime")),
      onProgress: step(2),
    );

    onProgress?.call(1);
    return versionId;
  }

  /// The version to launch: Minecraft's, or the loader's profile, named as
  /// Fabric and Quilt name it (`fabric-loader-0.16.5-1.21.1`).
  static String versionIdOf(Manifest manifest) =>
      manifest.loaderType == LoaderType.vanilla
      ? manifest.minecraftVersion
      : "${manifest.loaderType.name}-loader-${manifest.loaderVersion}-"
            "${manifest.minecraftVersion}";

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
