import 'dart:convert';
import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/services/java_manager.dart';
import 'package:bc_launcher/services/library_manager.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_core.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

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

/// Installs the game files an instance needs, which organizations never serve.
class GameInstaller {
  static const versionManifestUrl =
      "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json";

  /// Where Java runtimes are kept, shared by every instance (tests replace it).
  @visibleForTesting
  static Future<Directory> Function() runtimesDirectory = () async =>
      Directory(join((await getApplicationSupportDirectory()).path, "runtime"));

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
    if (manifest.loaderType != LoaderType.vanilla) {
      throw UnsupportedLoaderError(manifest.loaderType);
    }

    const steps = 2;
    void Function(double) step(int index) =>
        (progress) => onProgress?.call((index + progress) / steps);

    final versionId = manifest.minecraftVersion;
    await _ensureVersionJson(versionId, folder);

    final versionData = await MinecraftLauncherCore.loadVersionData(
      versionId,
      folder.path,
    );

    await LibraryManager.ensureLibraries(
      versionData,
      folder,
      onProgress: step(0),
    );

    await ensureJava(
      versionData,
      await runtimesDirectory(),
      onProgress: step(1),
    );
    
    onProgress?.call(1);
    return versionId;
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
