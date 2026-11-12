import 'dart:convert';
import 'dart:io';

import 'package:bc_launcher/services/file_downloader.dart';
import 'package:path/path.dart';

/// The game's assets (textures, sounds, languages) from Mojang. They are
/// stored by hash in `assets/`, so every instance can share them.
class AssetManager {
  static const resourcesUrl = "https://resources.download.minecraft.net";

  static Future<void> ensureAssets(
    Map versionData,
    Directory sharedRoot,
    Directory gameDir, {
    void Function(double progress)? onProgress,
  }) async {
    final pending = await plan(versionData, sharedRoot, gameDir);
    await FileDownloader.downloadAll(pending.tasks, onProgress: onProgress);
    await pending.finish();
  }

  /// What [ensureAssets] downloads (it gets the small asset index first),
  /// and copying them where old versions look for them after.
  static Future<PendingDownloads> plan(
    Map versionData,
    Directory sharedRoot,
    Directory gameDir,
  ) async {
    final assetIndex = versionData['assetIndex'] as Map?;
    if (assetIndex == null) return const PendingDownloads.none();

    final assets = join(sharedRoot.path, "assets");
    final indexTask = DownloadTask(
      path: join(assets, "indexes", "${assetIndex['id']}.json"),
      url: assetIndex['url'],
      sha1: assetIndex['sha1'],
      size: assetIndex['size'],
    );

    if (await indexTask.isMissing(verifyHash: true)) {
      await FileDownloader.downloadAll([indexTask]);
    }

    final index = jsonDecode(await File(indexTask.path).readAsString()) as Map;
    final objects = (index['objects'] as Map).cast<String, Map>();

    final pending = <DownloadTask>[];
    final seen = <String>{};
    for (final object in objects.values) {
      final hash = object['hash'] as String;
      if (!seen.add(hash)) continue;

      final task = DownloadTask(
        path: objectPath(sharedRoot, hash),
        url: "$resourcesUrl/${hash.substring(0, 2)}/$hash",
        sha1: hash,
        size: object['size'],
      );

      if (await task.isMissing()) pending.add(task);
    }

    final copyTo = index['map_to_resources'] == true
        ? join(gameDir.path, "resources")
        : index['virtual'] == true
        ? join(assets, "virtual", "legacy")
        : null;

    return PendingDownloads(
      pending,
      finish: () async {
        if (copyTo == null) return;

        for (final MapEntry(key: name, value: object) in objects.entries) {
          final target = normalize(joinAll([copyTo, ...posix.split(name)]));
          if (!isWithin(copyTo, target)) continue;

          final file = File(target);
          if (await file.exists() && await file.length() == object['size']) {
            continue;
          }

          await file.parent.create(recursive: true);
          await File(objectPath(sharedRoot, object['hash'])).copy(target);
        }
      },
    );
  }

  /// Where the object with [hash] is kept.
  static String objectPath(Directory sharedRoot, String hash) =>
      join(sharedRoot.path, "assets", "objects", hash.substring(0, 2), hash);
}
