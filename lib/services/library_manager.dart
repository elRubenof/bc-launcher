import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_core.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_helper.dart';
import 'package:path/path.dart';

/// Completes a version's libraries, natives and client jar for this system
/// from the URLs in its version JSON, so an instance made on another platform
/// still runs.
class LibraryManager {
  static const _defaultLibraryRepo = 'https://libraries.minecraft.net/';

  /// Downloads whatever [versionData] (a version JSON, already merged with the
  /// version it inherits from) is missing under [minecraftDir], then extracts
  /// the natives of versions before 1.19.
  ///
  /// Libraries go under [sharedRoot] (the folder holding `libraries/`) when
  /// given; the client jar and natives always go under [minecraftDir].
  ///
  /// [onProgress] is only called when files have to be downloaded.
  static Future<void> ensureLibraries(
    Map versionData,
    Directory minecraftDir, {
    Directory? sharedRoot,
    void Function(double progress)? onProgress,
  }) async {
    final path = minecraftDir.path;
    final librariesRoot = sharedRoot?.path ?? path;
    final tasks = <DownloadTask>[];
    final nativeJars = <String, List<String>>{};

    final client = versionData['downloads']?['client'];
    if (client != null) {
      tasks.add(
        DownloadTask(
          path: MinecraftLauncherCore.clientJarPath(versionData, path),
          url: client['url'],
          sha1: client['sha1'],
          size: client['size'],
        ),
      );
    }

    for (final Map library in versionData['libraries'] ?? []) {
      if (library.containsKey('rules') &&
          !MinecraftLauncherHelper.parseRuleList(library['rules'], {})) {
        continue;
      }

      final artifact = _artifactTask(library, librariesRoot);
      if (artifact != null) tasks.add(artifact);

      final native = MinecraftLauncherHelper.getNatives(library);
      final classifier = library['downloads']?['classifiers']?[native];
      if (native.isNotEmpty && classifier != null) {
        final jarPath = _libraryFile(librariesRoot, classifier['path']);
        tasks.add(
          DownloadTask(
            path: jarPath,
            url: classifier['url'],
            sha1: classifier['sha1'],
            size: classifier['size'],
          ),
        );
        nativeJars[jarPath] = List<String>.from(
          library['extract']?['exclude'] ?? [],
        );
      }
    }

    final pending = <DownloadTask>[];
    final seen = <String>{};
    for (final task in tasks) {
      if (seen.add(task.path) && await task.isMissing()) pending.add(task);
    }
    await FileDownloader.downloadAll(pending, onProgress: onProgress);

    final nativesDir = Directory(
      MinecraftLauncherCore.nativesDirectory(versionData, path),
    );
    for (final entry in nativeJars.entries) {
      await _extractNatives(File(entry.key), nativesDir, entry.value);
    }
  }

  /// The main jar of [library]. Mojang libraries list it under
  /// `downloads.artifact`; modloader ones (Fabric) only give a Maven
  /// repository in `url`. Natives-only libraries (before 1.19) have none.
  static DownloadTask? _artifactTask(Map library, String path) {
    final filePath = MinecraftLauncherHelper.getLibraryPath(
      library['name'],
      path,
    );
    final artifact = library['downloads']?['artifact'];

    if (artifact != null) {
      final url = artifact['url'] as String?;
      if (url == null || url.isEmpty) return null;

      return DownloadTask(
        path: filePath,
        url: url,
        sha1: artifact['sha1'],
        size: artifact['size'],
      );
    }

    if (library.containsKey('downloads')) return null;

    var repo = library['url'] as String? ?? _defaultLibraryRepo;
    if (!repo.endsWith('/')) repo += '/';

    return DownloadTask(
      path: filePath,
      url: repo + _mavenPath(library['name']),
      sha1: library['sha1'],
      size: library['size'],
    );
  }

  /// `group:name:version[:classifier][@ext]` as a Maven repository path.
  static String _mavenPath(String name) {
    var extension = 'jar';
    if (name.contains('@')) {
      final parts = name.split('@');
      name = parts[0];
      extension = parts[1];
    }

    final parts = name.split(':');
    final group = parts[0].replaceAll('.', '/');
    final artifact = parts[1];
    final version = parts[2];
    final classifier = parts.length > 3 ? '-${parts.sublist(3).join('-')}' : '';

    return '$group/$artifact/$version/$artifact-$version$classifier.$extension';
  }

  static String _libraryFile(String path, String libraryPath) {
    return joinAll([path, 'libraries', ...posix.split(libraryPath)]);
  }

  /// Extracts the files of a natives jar into [nativesDir], skipping the
  /// [exclude]d prefixes and files that are already there.
  static Future<void> _extractNatives(
    File jar,
    Directory nativesDir,
    List<String> exclude,
  ) async {
    final archive = ZipDecoder().decodeBytes(await jar.readAsBytes());

    for (final entry in archive) {
      if (!entry.isFile) continue;
      if (exclude.any((prefix) => entry.name.startsWith(prefix))) continue;

      final target = normalize(
        joinAll([nativesDir.path, ...posix.split(entry.name)]),
      );
      if (!isWithin(nativesDir.path, target)) continue;

      final file = File(target);
      if (await file.exists() && await file.length() == entry.size) continue;

      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.content as List<int>);
    }
  }
}
