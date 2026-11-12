import 'package:bc_launcher/models/manifest.dart';

/// A manifest path the launcher refuses to write: it would leave the
/// instance folder or overwrite the launcher's own files.
class UnsafePathError implements Exception {
  final String path;

  const UnsafePathError(this.path);

  @override
  String toString() => "UnsafePathError($path)";
}

/// A file found in the instance folder. [sha256] is `null` when it wasn't
/// hashed (only files the manifest manages with `always` need it).
class LocalFile {
  final int size;
  final String? sha256;

  const LocalFile({required this.size, this.sha256});
}

/// What a sync has to do to make the instance folder match the manifest.
class SyncPlan {
  /// Missing or changed files to download.
  final List<ManifestFile> downloads;

  /// Paths to delete, relative to the instance folder.
  final List<String> deletions;

  /// The `always` paths the launcher manages after this sync: next time,
  /// the ones the organization removed are deleted.
  final Set<String> installed;

  const SyncPlan({
    required this.downloads,
    required this.deletions,
    required this.installed,
  });

  int get downloadBytes => downloads.fold(0, (sum, file) => sum + file.size);

  bool get isEmpty => downloads.isEmpty && deletions.isEmpty;
}

/// Decides what a sync does, without touching the disk:
/// - `always` files are downloaded when missing or different;
/// - `once` files only when missing, then they are the player's;
/// - in the manifest's managed folders, anything else is deleted;
/// - elsewhere, only `always` files the launcher installed before and the
///   organization removed are deleted;
/// - the player's worlds, screenshots, `options.txt`, `servers.dat` and the
///   launcher's own folder are never deleted.
class SyncPlanner {
  /// Folders that belong to the launcher (Minecraft and loader files and its
  /// own state); a manifest can't write there.
  static const reservedFolders = [
    "versions",
    "libraries",
    "assets",
    ".bc-launcher",
  ];

  /// Never deleted, wherever they are.
  static const _protectedFolders = ["saves", "screenshots", ".bc-launcher"];
  static const _protectedFiles = ["options.txt", "servers.dat"];

  static SyncPlan plan({
    required Manifest manifest,
    required Map<String, LocalFile> local,
    Set<String> previouslyInstalled = const {},
  }) {
    for (final file in manifest.files) {
      checkPath(file.path);
    }

    for (final folder in manifest.managedDirs) {
      checkPath(folder);
    }

    final downloads = <ManifestFile>[];
    for (final file in manifest.files) {
      final existing = local[file.path];
      final needed = switch (file.policy) {
        FilePolicy.once => existing == null,
        FilePolicy.always =>
          existing == null ||
              existing.size != file.size ||
              existing.sha256 != file.sha256,
      };
      if (needed) downloads.add(file);
    }

    // Compared ignoring case: on Windows and macOS `Mods/A.jar` is the same
    // file as `mods/a.jar`, and deleting it would delete the manifest's.
    final kept = {for (final file in manifest.files) file.path.toLowerCase()};

    bool managed(String path) => manifest.managedDirs.any(
      (folder) => path.toLowerCase().startsWith("${folder.toLowerCase()}/"),
    );

    final deletions = <String>[];
    for (final path in local.keys) {
      if (kept.contains(path.toLowerCase()) || isProtected(path)) continue;
      if (managed(path) || previouslyInstalled.contains(path)) {
        deletions.add(path);
      }
    }
    deletions.sort();

    return SyncPlan(
      downloads: downloads,
      deletions: deletions,
      installed: {
        for (final file in manifest.files)
          if (file.policy == FilePolicy.always) file.path,
      },
    );
  }

  /// Throws [UnsafePathError] unless [path] is a plain relative `/` path
  /// inside the instance folder and outside the launcher's folders.
  static void checkPath(String path) {
    final segments = path.split('/');
    final unsafe =
        path.isEmpty ||
        path.startsWith('/') ||
        path.contains('\\') ||
        path.contains(':') ||
        segments.any(
          (segment) => segment.isEmpty || segment == '.' || segment == '..',
        ) ||
        reservedFolders.contains(segments.first.toLowerCase());
    if (unsafe) throw UnsafePathError(path);
  }

  /// Whether [path] is one the player keeps no matter what.
  static bool isProtected(String path) {
    final lower = path.toLowerCase();
    return _protectedFiles.contains(lower) ||
        _protectedFolders.any(
          (folder) => lower == folder || lower.startsWith("$folder/"),
        );
  }
}
