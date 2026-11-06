import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/sync_plan.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';

/// How far a sync is, for "38 of 87 files · 140 MB of 310 MB".
class SyncProgress {
  final int files;
  final int totalFiles;
  final int bytes;
  final int totalBytes;

  const SyncProgress({
    required this.files,
    required this.totalFiles,
    required this.bytes,
    required this.totalBytes,
  });

  double get fraction => totalBytes > 0
      ? bytes / totalBytes
      : (totalFiles > 0 ? files / totalFiles : 1);
}

/// The disk doesn't have room for what the sync has to download.
class NotEnoughSpaceError implements Exception {
  final int needed;
  final int available;

  const NotEnoughSpaceError({required this.needed, required this.available});

  @override
  String toString() => "NotEnoughSpaceError($needed > $available)";
}

/// Makes an instance folder match its organization's manifest.
class SyncEngine {
  static Future<Manifest> sync(
    ApiClient client,
    String organizationKey,
    String instanceId, {
    void Function(SyncProgress progress)? onProgress,
  }) async {
    final folder = await InstanceManager.instanceFolder(
      organizationKey,
      instanceId,
    );
    final launcherFolder = await InstanceManager.launcherFolder(
      organizationKey,
      instanceId,
    );

    var manifest = await _fetchManifest(client, instanceId, launcherFolder);
    try {
      await _apply(manifest, folder, launcherFolder, onProgress);
    } on DioException catch (e) {
      // The download URLs expired (they last 6 to 12 hours): a fresh
      // manifest has new ones, and what was downloaded is kept.
      if (e.response?.statusCode != 403) rethrow;

      log("Download URLs expired, fetching the manifest again");
      manifest = await _fetchManifest(
        client,
        instanceId,
        launcherFolder,
        fresh: true,
      );

      await _apply(manifest, folder, launcherFolder, onProgress);
    }

    return manifest;
  }

  static Future<Manifest> _fetchManifest(
    ApiClient client,
    String instanceId,
    Directory launcherFolder, {
    bool fresh = false,
  }) async {
    final saved = File(join(launcherFolder.path, "manifest.json"));
    Map<String, dynamic>? previous;

    if (!fresh && await saved.exists()) {
      try {
        previous = jsonDecode(await saved.readAsString());
      } catch (e) {
        log("Could not read the saved manifest: $e");
      }
    }

    final result = await client.manifest(
      instanceId,
      etag: previous?['etag'] as String?,
    );

    if (result == null) return Manifest.fromJson(previous!['manifest']);
    await _writeJson(saved, {
      'etag': result.etag,
      'manifest': result.manifest.toJson(),
    });

    return result.manifest;
  }

  static Future<void> _apply(
    Manifest manifest,
    Directory folder,
    Directory launcherFolder,
    void Function(SyncProgress progress)? onProgress,
  ) async {
    final installedFile = File(join(launcherFolder.path, "installed.json"));
    final previouslyInstalled = await _readInstalled(installedFile);

    final plan = SyncPlanner.plan(
      manifest: manifest,
      local: await _scan(folder, manifest, previouslyInstalled),
      previouslyInstalled: previouslyInstalled,
    );

    final available = await _freeBytes(folder);
    if (available != null && plan.downloadBytes > available) {
      throw NotEnoughSpaceError(
        needed: plan.downloadBytes,
        available: available,
      );
    }

    var files = 0, bytes = 0;
    void report() => onProgress?.call(
      SyncProgress(
        files: files,
        totalFiles: plan.downloads.length,
        bytes: bytes,
        totalBytes: plan.downloadBytes,
      ),
    );
    report();

    await FileDownloader.downloadAll(
      [
        for (final file in plan.downloads)
          DownloadTask(
            path: _local(folder, file.path),
            url: file.url,
            sha256: file.sha256,
            size: file.size,
          ),
      ],
      onDownloaded: (task) {
        files++;
        bytes += task.size ?? 0;
        report();
      },
    );

    for (final path in plan.deletions) {
      try {
        await File(_local(folder, path)).delete();
      } on FileSystemException catch (e) {
        log("Could not delete $path: $e");
      }
    }

    // Written last: if anything above failed, the next sync still knows
    // what the previous one installed.
    await _writeJson(installedFile, plan.installed.toList()..sort());
  }

  /// The files [SyncPlanner] needs: every manifest path, every file in the
  /// managed folders and every path installed before, when they exist. The
  /// `always` manifest files whose size matches are hashed, away from the UI.
  static Future<Map<String, LocalFile>> _scan(
    Directory folder,
    Manifest manifest,
    Set<String> previouslyInstalled,
  ) async {
    final paths = <String>{
      for (final file in manifest.files) file.path,
      ...previouslyInstalled,
    };
    for (final managed in manifest.managedDirs) {
      final directory = Directory(_local(folder, managed));
      if (!await directory.exists()) continue;
      await for (final entity in directory.list(recursive: true)) {
        if (entity is! File || entity.path.endsWith(".part")) continue;
        paths.add(
          posix.joinAll(split(relative(entity.path, from: folder.path))),
        );
      }
    }

    final sizes = <String, int>{};
    for (final path in paths) {
      final file = File(_local(folder, path));
      if (await file.exists()) sizes[path] = await file.length();
    }

    final toHash = [
      for (final file in manifest.files)
        if (file.policy == FilePolicy.always && sizes[file.path] == file.size)
          _local(folder, file.path),
    ];
    final hashes = await Isolate.run(() => _hashAll(toHash));

    return {
      for (final MapEntry(key: path, value: size) in sizes.entries)
        path: LocalFile(size: size, sha256: hashes[_local(folder, path)]),
    };
  }

  static Map<String, String> _hashAll(List<String> paths) => {
    for (final path in paths)
      path: sha256.convert(File(path).readAsBytesSync()).toString(),
  };

  static Future<Set<String>> _readInstalled(File file) async {
    try {
      if (!await file.exists()) return {};
      return Set<String>.from(jsonDecode(await file.readAsString()) as List);
    } catch (e) {
      log("Could not read the installed files: $e");
      return {};
    }
  }

  /// Writes through a `.part` file and a rename, so a crash never leaves it
  /// half-written.
  static Future<void> _writeJson(File file, Object json) async {
    await file.parent.create(recursive: true);
    final part = File("${file.path}.part");
    await part.writeAsString(jsonEncode(json));
    await part.rename(file.path);
  }

  /// A manifest path (always `/`) inside [folder].
  static String _local(Directory folder, String path) =>
      joinAll([folder.path, ...posix.split(path)]);

  /// Free bytes on the disk of [folder].
  static Future<int?> _freeBytes(Directory folder) async {
    try {
      var existing = folder.absolute;
      while (!await existing.exists() &&
          existing.parent.path != existing.path) {
        existing = existing.parent;
      }

      if (Platform.isWindows) {
        final drive = existing.path.substring(0, 1);
        final result = await Process.run("powershell", [
          "-NoProfile",
          "-Command",
          "(Get-PSDrive -Name $drive).Free",
        ]);
        return int.tryParse("${result.stdout}".trim());
      }

      final result = await Process.run("df", ["-Pk", existing.path]);
      final columns = "${result.stdout}"
          .trim()
          .split("\n")
          .last
          .split(RegExp(r"\s+"));

      final kilobytes = int.tryParse(columns[3]);
      return kilobytes == null ? null : kilobytes * 1024;
    } catch (e) {
      log("Could not read the free disk space: $e");
      return null;
    }
  }
}
