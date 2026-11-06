import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

/// An organization's server: the manifest of `test` and its blobs.
class FakeServer implements HttpClientAdapter {
  /// path → contents of the files the manifest lists.
  Map<String, String> files = {};
  Map<String, String> policies = {};
  List<String> managedDirs = ['mods'];
  int contentVersion = 1;
  String? serverAddress;

  /// The manifest's ETag; `If-None-Match` with it answers 304.
  String etag = '"1"';

  /// Blob requests answer 403 (expired URL) until this many manifests were
  /// served.
  int expireUntilManifest = 0;

  /// Contents served instead of the real ones, by path (a corrupted blob).
  Map<String, String> corrupt = {};

  final requests = <RequestOptions>[];
  int manifests = 0;

  static String hash(String contents) =>
      sha256.convert(utf8.encode(contents)).toString();

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final uri = options.uri;

    if (uri.path.endsWith('/manifest')) {
      if (options.headers['If-None-Match'] == etag) {
        return ResponseBody.fromString('', 304);
      }
      manifests++;
      return ResponseBody.fromString(
        jsonEncode({
          'contentVersion': contentVersion,
          'minecraft': {'version': '1.21.1'},
          'loader': {'type': 'fabric', 'version': '0.16.5'},
          'server': {'address': serverAddress},
          'managedDirs': managedDirs,
          'files': [
            for (final MapEntry(key: path, value: contents) in files.entries)
              {
                'path': path,
                'sha256': hash(contents),
                'size': utf8.encode(contents).length,
                'policy': policies[path] ?? 'always',
                'url': 'https://example.com/blobs/$path?m=$manifests',
              },
          ],
        }),
        200,
        headers: {
          'content-type': ['application/json'],
          'etag': [etag],
        },
      );
    }

    if (manifests <= expireUntilManifest) {
      return ResponseBody.fromString('', 403);
    }
    final path = uri.path.substring('/blobs/'.length);
    return ResponseBody.fromString(corrupt[path] ?? files[path]!, 200);
  }

  @override
  void close({bool force = false}) {}
}
