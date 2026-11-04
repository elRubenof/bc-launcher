import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// A file to download to [path], optionally checked against its [sha1] and
/// [size].
class DownloadTask {
  final String path;
  final String url;
  final String? sha1;
  final int? size;

  const DownloadTask({
    required this.path,
    required this.url,
    this.sha1,
    this.size,
  });

  /// Whether the file is missing or doesn't match. Without [verifyHash] only
  /// the size is checked, which is much faster.
  Future<bool> isMissing({bool verifyHash = false}) async {
    final file = File(path);
    if (!await file.exists()) return true;
    if (size != null && await file.length() != size) return true;
    if (verifyHash && sha1 != null) {
      return await FileDownloader.sha1Of(file) != sha1;
    }
    return false;
  }
}

/// Downloads files in parallel, each one to a `.part` file that is checked and
/// then moved into place.
class FileDownloader {
  static const _parallelDownloads = 8;

  static final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Downloads [tasks]. [onProgress] gets a value from 0 to 1 and is only
  /// called when there is something to download.
  static Future<void> downloadAll(
    List<DownloadTask> tasks, {
    void Function(double progress)? onProgress,
  }) async {
    if (tasks.isEmpty) return;

    final totalBytes = tasks.fold<int>(
      0,
      (sum, task) => sum + (task.size ?? 0),
    );
    var doneBytes = 0;
    var doneTasks = 0;
    onProgress?.call(0);

    final queue = tasks.iterator;
    Future<void> worker() async {
      while (queue.moveNext()) {
        final task = queue.current;
        await _download(task);

        doneBytes += task.size ?? 0;
        doneTasks++;
        onProgress?.call(
          totalBytes > 0 ? doneBytes / totalBytes : doneTasks / tasks.length,
        );
      }
    }

    await Future.wait(List.generate(_parallelDownloads, (_) => worker()));
  }

  static Future<void> _download(DownloadTask task) async {
    final part = File('${task.path}.part');
    await part.parent.create(recursive: true);
    await dio.download(task.url, part.path);

    if (task.sha1 != null && await sha1Of(part) != task.sha1) {
      await part.delete();
      throw FileSystemException('Hash mismatch', task.path);
    }

    await part.rename(task.path);
  }

  static Future<String> sha1Of(File file) async {
    return (await file.openRead().transform(sha1).first).toString();
  }
}
