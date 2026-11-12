import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Generates the unsigned `release.json` (Windows update descriptor) and
/// `app-archive.json` (multiplatform release index) for GitHub Releases.
///
/// `app-archive.json` carries the `supportPolicy` in `support_policy.json`,
/// beside this script: launchers older than its `minimumSupportedVersion` have
/// to update once `enforcedAfter` has passed (at once when it is `null`).
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

  final supportPolicy = readSupportPolicy(version);

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
    'install': {'strategy': 'wholeDirectoryReplace'},
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
    if (supportPolicy != null) 'supportPolicy': supportPolicy,
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
        'freshInstall': {'downloadUrl': '$tagUrl/BC-Launcher.dmg'},
      },
      {
        'version': version,
        'buildNumber': null,
        'platform': 'linux',
        'channel': 'stable',
        'mandatory': false,
        'release': '$tagUrl/release.json',
        'freshInstall': {'downloadUrl': '$tagUrl/BC-Launcher.AppImage'},
      },
    ],
  };

  final appArchiveFile = File(p.join(outDir.path, 'app-archive.json'));
  appArchiveFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(appArchiveJson),
  );
  stdout.writeln('Wrote ${appArchiveFile.path}');
}

/// The `supportPolicy` for releasing [version], or `null` without a minimum
/// version. Exits when the file is wrong, so a release never ships a policy
/// its own version can't meet.
Map<String, String>? readSupportPolicy(String version) {
  final file = File(
    p.join(p.dirname(p.fromUri(Platform.script)), 'support_policy.json'),
  );
  if (!file.existsSync()) return null;

  final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  final minimum = (json['minimumSupportedVersion'] as String?)?.trim();
  if (minimum == null || minimum.isEmpty) return null;

  final minimumParts = versionParts(minimum);
  final releaseParts = versionParts(version);
  if (minimumParts == null || releaseParts == null) {
    fail('support_policy.json: versions must be X.Y.Z ($minimum, $version).');
  }
  if (compareVersions(minimumParts, releaseParts) > 0) {
    fail(
      'support_policy.json: minimumSupportedVersion $minimum is newer than '
      'the release $version, so nobody could meet it.',
    );
  }

  final enforcedAfter = (json['enforcedAfter'] as String?)?.trim();
  final DateTime enforced;
  if (enforcedAfter == null || enforcedAfter.isEmpty) {
    enforced = DateTime.now().toUtc();
  } else {
    final parsed = DateTime.tryParse(enforcedAfter);
    if (parsed == null) {
      fail('support_policy.json: enforcedAfter must be an ISO-8601 date.');
    }
    enforced = parsed.toUtc();
  }

  return {
    'minimumSupportedVersion': minimum,
    'enforcedAfter': enforced.toIso8601String(),
  };
}

/// X.Y.Z as three numbers, or `null`.
List<int>? versionParts(String version) {
  final match = RegExp(r'^(\d+)\.(\d+)\.(\d+)$').firstMatch(version);
  if (match == null) return null;
  return [for (var i = 1; i <= 3; i++) int.parse(match.group(i)!)];
}

int compareVersions(List<int> a, List<int> b) {
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i].compareTo(b[i]);
  }
  return 0;
}

Never fail(String message) {
  stderr.writeln(message);
  exit(1);
}
