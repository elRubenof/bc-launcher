import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart';

/// Downloads the Java runtime a Minecraft version needs from Mojang and
/// returns the path to its executable.
class JavaManager {
  static const _runtimesUrl =
      'https://launchermeta.mojang.com/v1/products/java-runtime/'
      '2ec0cc96c44e5a76b9c8b7c39df7210883d12871/all.json';
  static const _parallelDownloads = 8;
  static const _installedMarker = '.installed';

  static final _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  /// Makes sure the runtime required by [versionData] (a version JSON) is
  /// installed under [runtimesDir] and returns its Java executable.
  ///
  /// [onProgress] is only called when files have to be downloaded, with a
  /// value from 0 to 1.
  static Future<String> ensureRuntime(
    Map versionData,
    Directory runtimesDir, {
    void Function(double progress)? onProgress,
  }) async {
    final component =
        versionData['javaVersion']?['component'] as String? ?? 'jre-legacy';

    Map? release;
    String? platform;
    try {
      final runtimes = (await _dio.get(_runtimesUrl)).data as Map;
      for (final candidate in _platforms()) {
        final releases = runtimes[candidate]?[component] as List?;
        if (releases != null && releases.isNotEmpty) {
          release = releases.first;
          platform = candidate;
          break;
        }
      }
    } on DioException {
      // Offline: fall back to any runtime that is already installed.
      for (final candidate in _platforms()) {
        final dir = Directory(join(runtimesDir.path, component, candidate));
        if (await File(join(dir.path, _installedMarker)).exists()) {
          return _executable(dir);
        }
      }
      rethrow;
    }

    if (release == null || platform == null) {
      throw UnsupportedError(
        'Java runtime $component is not available for this system',
      );
    }

    final dir = Directory(join(runtimesDir.path, component, platform));
    final marker = File(join(dir.path, _installedMarker));
    final manifestSha1 = release['manifest']['sha1'] as String;

    if (await marker.exists() && await marker.readAsString() == manifestSha1) {
      return _executable(dir);
    }

    final manifest = (await _dio.get(release['manifest']['url'])).data as Map;
    await _install(manifest['files'] as Map, dir, onProgress);
    await marker.writeAsString(manifestSha1);

    return _executable(dir);
  }

  /// Mojang platform names for this system, preferred first. ARM machines
  /// fall back to the x64 runtime, which runs under emulation.
  static List<String> _platforms() {
    final abi = Abi.current();

    if (Platform.isWindows) {
      if (abi == Abi.windowsArm64) return ['windows-arm64', 'windows-x64'];
      if (abi == Abi.windowsIA32) return ['windows-x86'];
      return ['windows-x64'];
    }
    if (Platform.isMacOS) {
      if (abi == Abi.macosArm64) return ['mac-os-arm64', 'mac-os'];
      return ['mac-os'];
    }
    if (Platform.isLinux) {
      if (abi == Abi.linuxIA32) return ['linux-i386'];
      if (abi == Abi.linuxX64) return ['linux'];
      return [];
    }

    return [];
  }

  static String _executable(Directory dir) {
    if (Platform.isWindows) return join(dir.path, 'bin', 'javaw.exe');
    if (Platform.isMacOS) {
      return join(dir.path, 'jre.bundle', 'Contents', 'Home', 'bin', 'java');
    }
    return join(dir.path, 'bin', 'java');
  }

  static Future<void> _install(
    Map files,
    Directory dir,
    void Function(double progress)? onProgress,
  ) async {
    final downloads = <_RuntimeFile>[];
    final links = <String, String>{};

    for (final entry in files.entries) {
      final path = _resolve(dir, entry.key as String);
      final info = entry.value as Map;

      switch (info['type']) {
        case 'directory':
          await Directory(path).create(recursive: true);
        case 'file':
          final raw = info['downloads']['raw'] as Map;
          downloads.add(
            _RuntimeFile(
              path: path,
              url: raw['url'],
              hash: raw['sha1'],
              size: raw['size'],
              executable: info['executable'] == true,
            ),
          );
        case 'link':
          links[path] = info['target'] as String;
      }
    }

    final pending = <_RuntimeFile>[];
    for (final file in downloads) {
      if (!await file.isValid()) pending.add(file);
    }

    final total = pending.fold<int>(0, (sum, file) => sum + file.size);
    var received = 0;
    if (pending.isNotEmpty) onProgress?.call(0);

    final queue = pending.iterator;
    Future<void> worker() async {
      while (queue.moveNext()) {
        final file = queue.current;
        await file.download(_dio);
        received += file.size;
        onProgress?.call(total == 0 ? 1 : received / total);
      }
    }

    await Future.wait(List.generate(_parallelDownloads, (_) => worker()));

    for (final entry in links.entries) {
      final link = Link(entry.key);
      if (await link.exists()) await link.delete();
      await link.create(entry.value);
    }

    if (!Platform.isWindows) {
      final executables = downloads
          .where((file) => file.executable)
          .map((file) => file.path)
          .toList();
      if (executables.isNotEmpty) {
        final result = await Process.run('chmod', ['+x', ...executables]);
        if (result.exitCode != 0) {
          throw FileSystemException('chmod failed: ${result.stderr}');
        }
      }
    }
  }

  /// Joins a manifest path, which always uses `/`, onto [dir], rejecting
  /// paths that would land outside it.
  static String _resolve(Directory dir, String manifestPath) {
    final path = normalize(joinAll([dir.path, ...posix.split(manifestPath)]));
    if (!isWithin(dir.path, path)) {
      throw FileSystemException('Unsafe path in runtime manifest', path);
    }
    return path;
  }
}

class _RuntimeFile {
  final String path;
  final String url;
  final String hash;
  final int size;
  final bool executable;

  const _RuntimeFile({
    required this.path,
    required this.url,
    required this.hash,
    required this.size,
    required this.executable,
  });

  Future<bool> isValid() async {
    final file = File(path);
    if (!await file.exists() || await file.length() != size) return false;
    return await _sha1(file) == hash;
  }

  /// Downloads to a `.part` file, checks the hash and then moves it into place.
  Future<void> download(Dio dio) async {
    final part = File('$path.part');
    await dio.download(url, part.path);

    if (await _sha1(part) != hash) {
      await part.delete();
      throw FileSystemException('Hash mismatch', path);
    }

    await part.rename(path);
  }

  static Future<String> _sha1(File file) async {
    return (await file.openRead().transform(sha1).first).toString();
  }
}
