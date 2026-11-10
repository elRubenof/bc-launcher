import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Generates the unsigned `release.json` (Windows update descriptor) and
/// `app-archive.json` (multiplatform release index) for GitHub Releases.
///
/// Usage:
///   dart run installers/release_feed.dart <version> <path-to-windows-zip> [out-dir]
void main(List<String> args) {
  if (args.length < 2) {
    stderr.writeln(
      'Usage: dart run installers/release_feed.dart <version> <path-to-windows-zip> [out-dir]',
    );
    exit(1);
  }

  final version = args[0].replaceFirst(RegExp(r'^v'), '').trim();
  final zipFile = File(args[1]);
  final outDir = Directory(args.length > 2 ? args[2] : 'dist');

  if (!zipFile.existsSync()) {
    stderr.writeln('Windows zip not found at: ${zipFile.path}');
    exit(1);
  }

  outDir.createSync(recursive: true);

  final zipBytes = zipFile.readAsBytesSync();
  final zipSha256 = sha256.convert(zipBytes).toString();
  final zipLength = zipBytes.length;

  const repoUrl = 'https://github.com/elRubenof/bc-launcher/releases/download';
  final tagUrl = '$repoUrl/v$version';

  // Windows release.json
  final releaseJson = {
    'schemaVersion': 3,
    'packageId': 'bc_launcher',
    'appName': 'BC Launcher',
    'version': version,
    'buildNumber': null,
    'platform': 'windows',
    'channel': 'stable',
    'artifact': {
      'kind': 'zip',
      'url': '$tagUrl/BC-Launcher-windows.zip',
      'sha256': zipSha256,
      'length': zipLength,
    },
    'install': {
      'strategy': 'wholeDirectoryReplace',
    },
    'minimumUpdaterVersion': '3.1.0',
    'generatedAt': DateTime.now().toUtc().toIso8601String(),
  };

  final releaseFile = File(p.join(outDir.path, 'release.json'));
  releaseFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(releaseJson),
  );
  stdout.writeln('Wrote ${releaseFile.path}');

  // Multi-platform app-archive.json
  final appArchiveJson = {
    'schemaVersion': 3,
    'appName': 'BC Launcher',
    'items': [
      {
        'version': version,
        'buildNumber': null,
        'platform': 'windows',
        'channel': 'stable',
        'mandatory': false,
        'release': '$tagUrl/release.json',
      },
      {
        'version': version,
        'buildNumber': null,
        'platform': 'macos',
        'channel': 'stable',
        'mandatory': false,
        'release': '$tagUrl/release.json',
        'freshInstall': {
          'downloadUrl': '$tagUrl/BC-Launcher.dmg',
        },
      },
      {
        'version': version,
        'buildNumber': null,
        'platform': 'linux',
        'channel': 'stable',
        'mandatory': false,
        'release': '$tagUrl/release.json',
        'freshInstall': {
          'downloadUrl': '$tagUrl/BC-Launcher.AppImage',
        },
      },
    ],
  };

  final appArchiveFile = File(p.join(outDir.path, 'app-archive.json'));
  appArchiveFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(appArchiveJson),
  );
  stdout.writeln('Wrote ${appArchiveFile.path}');
}
