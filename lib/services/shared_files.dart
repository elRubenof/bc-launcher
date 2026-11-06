import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_helper.dart';
import 'package:path/path.dart';

/// The libraries and assets shared by every instance.
class SharedFiles {
  /// Deletes the libraries and assets in [shared] that no installed instance
  /// uses any more.
  static Future<void> cleanUnused(Directory shared) {
    final root = shared.path;
    return Isolate.run(() => _clean(root));
  }

  static void _clean(String root) {
    final libraries = <String>{};
    final indexes = <String>{};

    for (final versionJson in _versionJsons(root)) {
      final Map data;
      try {
        data = jsonDecode(versionJson.readAsStringSync()) as Map;
      } catch (_) {
        return;
      }

      for (final Map library in data['libraries'] ?? []) {
        libraries.add(
          normalize(
            MinecraftLauncherHelper.getLibraryPath(library['name'], root),
          ),
        );

        final classifiers = library['downloads']?['classifiers'] as Map?;
        for (final Map classifier in classifiers?.values ?? []) {
          libraries.add(
            normalize(
              joinAll([root, "libraries", ...posix.split(classifier['path'])]),
            ),
          );
        }
      }

      final index = data['assetIndex']?['id'];
      if (index != null) indexes.add("$index.json");
    }

    final objects = <String>{};
    final indexesDir = Directory(join(root, "assets", "indexes"));
    for (final name in indexes) {
      final file = File(join(indexesDir.path, name));
      if (!file.existsSync()) continue;

      try {
        final index = jsonDecode(file.readAsStringSync()) as Map;
        for (final Map object in (index['objects'] as Map).values) {
          objects.add(object['hash']);
        }
      } catch (_) {
        return;
      }
    }

    _deleteExcept(Directory(join(root, "libraries")), libraries.contains);
    _deleteExcept(indexesDir, (path) => indexes.contains(basename(path)));
    _deleteExcept(
      Directory(join(root, "assets", "objects")),
      (path) => objects.contains(basename(path)),
    );
  }

  /// The version JSONs of every instance (`<organization>/<instance>/` with a
  /// `.bc-launcher` folder).
  static Iterable<File> _versionJsons(String root) sync* {
    for (final organization in _folders(Directory(root))) {
      for (final instance in _folders(organization)) {
        if (!Directory(join(instance.path, ".bc-launcher")).existsSync()) {
          continue;
        }

        for (final version in _folders(
          Directory(join(instance.path, "versions")),
        )) {
          final file = File(
            join(version.path, "${basename(version.path)}.json"),
          );

          if (file.existsSync()) yield file;
        }
      }
    }
  }

  static Iterable<Directory> _folders(Directory directory) =>
      directory.existsSync()
      ? directory.listSync().whereType<Directory>()
      : const [];

  /// Deletes the files in [directory] that [keep] rejects, and the folders
  /// left empty.
  static void _deleteExcept(Directory directory, bool Function(String) keep) {
    if (!directory.existsSync()) return;

    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File && !keep(normalize(entity.path))) entity.deleteSync();
    }

    // Deepest first, so a folder is empty once its subfolders are gone.
    final folders =
        directory.listSync(recursive: true).whereType<Directory>().toList()
          ..sort((a, b) => b.path.length.compareTo(a.path.length));
    for (final folder in folders) {
      if (folder.listSync().isEmpty) folder.deleteSync();
    }
  }
}
