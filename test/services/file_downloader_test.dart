import 'dart:io';
import 'dart:typed_data';

import 'package:bc_launcher/services/file_downloader.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

/// Serves one file in [chunks] pieces, [pause] apart.
class SlowServer implements HttpClientAdapter {
  final List<int> body;
  final int chunks;
  final Duration pause;

  SlowServer(this.body, {this.chunks = 4, required this.pause});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final size = (body.length / chunks).ceil();
    Stream<Uint8List> stream() async* {
      for (var start = 0; start < body.length; start += size) {
        await Future.delayed(pause);
        final end = start + size > body.length ? body.length : start + size;
        yield Uint8List.fromList(body.sublist(start, end));
      }
    }

    return ResponseBody(
      stream(),
      200,
      headers: {
        Headers.contentLengthHeader: ['${body.length}'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory folder;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('file_downloader_test');
  });
  tearDown(() => folder.delete(recursive: true));

  test('reports the bytes as they arrive, not only per file', () async {
    final body = List.filled(4000, 7);
    FileDownloader.dio.httpClientAdapter = SlowServer(
      body,
      pause: const Duration(milliseconds: 150),
    );
    final progress = <double>[];
    final bytes = <int>[];

    await FileDownloader.downloadAll(
      [
        DownloadTask(
          path: join(folder.path, 'big.jar'),
          url: 'https://example.com/big.jar',
          size: body.length,
        ),
      ],
      onProgress: progress.add,
      onBytes: bytes.add,
    );

    expect(await File(join(folder.path, 'big.jar')).length(), body.length);
    expect(progress.first, 0);
    expect(progress.last, 1);
    // Halfway through the only file, the bar already moved.
    expect(progress.where((p) => p > 0 && p < 1), isNotEmpty);
    expect(progress, orderedEquals([...progress]..sort()));
    expect(bytes.last, body.length);
  });

  test('reports at most every 100 ms', () async {
    final body = List.filled(4000, 7);
    FileDownloader.dio.httpClientAdapter = SlowServer(
      body,
      chunks: 40,
      pause: const Duration(milliseconds: 5),
    );
    final progress = <double>[];

    await FileDownloader.downloadAll([
      DownloadTask(
        path: join(folder.path, 'big.jar'),
        url: 'https://example.com/big.jar',
        size: body.length,
      ),
    ], onProgress: progress.add);

    // 40 pieces in about 200 ms: the start, two or three more and the end.
    expect(progress.length, lessThan(10));
    expect(progress.last, 1);
  });
}
