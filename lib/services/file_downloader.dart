import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// A file to download to [path], optionally checked against its [sha1] or
/// [sha256] and [size].
class DownloadTask {
  final String path;
  final String url;
  final String? sha1;
  final String? sha256;
  final int? size;

  const DownloadTask({
    required this.path,
    required this.url,
    this.sha1,
    this.sha256,
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

/// What one part of an installation still has to download ([tasks]), and
/// what it does once they are in place ([finish]), so several parts share one
/// download and one progress bar.
class PendingDownloads {
  final List<DownloadTask> tasks;
  final Future<void> Function() finish;

  const PendingDownloads(this.tasks, {required this.finish});

  static Future<void> _nothing() async {}

  const PendingDownloads.none() : tasks = const [], finish = _nothing;
}

/// Downloads files in parallel, each one to a `.part` file that is checked and
/// then moved into place.
class FileDownloader {
  static const _parallelDownloads = 8;

  /// Progress is reported at most this often.
  static const _reportInterval = Duration(milliseconds: 100);

  static final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Downloads [tasks]. [onProgress] gets a value from 0 to 1 and [onBytes]
  /// the bytes received, both as they arrive, at most every
  /// [_reportInterval]; they are only called when there is something to
  /// download. [onDownloaded] is called after each file is in place.
  static Future<void> downloadAll(
    List<DownloadTask> tasks, {
    void Function(double progress)? onProgress,
    void Function(int bytes)? onBytes,
    void Function(DownloadTask task)? onDownloaded,
  }) async {
    if (tasks.isEmpty) return;

    final totalBytes = tasks.fold<int>(
      0,
      (sum, task) => sum + (task.size ?? 0),
    );
    var doneBytes = 0;
    var doneTasks = 0;
    // What the files being downloaded have received so far.
    final receiving = Map<DownloadTask, int>.identity();

    final clock = Stopwatch()..start();
    Duration? lastReport;
    void report({bool always = false}) {
      final now = clock.elapsed;
      if (!always &&
          lastReport != null &&
          now - lastReport! < _reportInterval) {
        return;
      }
      lastReport = now;

      final bytes = receiving.values.fold(doneBytes, (sum, b) => sum + b);
      onBytes?.call(bytes);
      onProgress?.call(
        totalBytes > 0
            ? min(bytes / totalBytes, 1.0)
            : doneTasks / tasks.length,
      );
    }

    report(always: true);

    final queue = tasks.iterator;
    Future<void> worker() async {
      while (queue.moveNext()) {
        final task = queue.current;
        await _download(task, (received) {
          final size = task.size;
          if (size == null) return;

          receiving[task] = min(received, size);
          report();
        });
        receiving.remove(task);
        doneBytes += task.size ?? 0;
        doneTasks++;
        onDownloaded?.call(task);
        report();
      }
    }

    await Future.wait(List.generate(_parallelDownloads, (_) => worker()));
    report(always: true);
  }

  static Future<void> _download(
    DownloadTask task,
    void Function(int received) onReceived,
  ) async {
    final part = File('${task.path}.part');
    await part.parent.create(recursive: true);
    await dio.download(
      task.url,
      part.path,
      onReceiveProgress: (received, _) => onReceived(received),
    );

    final mismatch =
        (task.sha1 != null && await sha1Of(part) != task.sha1) ||
        (task.sha256 != null && await sha256Of(part) != task.sha256);
    if (mismatch) {
      await part.delete();
      throw FileSystemException('Hash mismatch', task.path);
    }

    await part.rename(task.path);
  }

  static Future<String> sha1Of(File file) async {
    return (await file.openRead().transform(sha1).first).toString();
  }

  static Future<String> sha256Of(File file) async {
    return (await file.openRead().transform(sha256).first).toString();
  }
}
