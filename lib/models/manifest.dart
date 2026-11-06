import 'package:bc_launcher/models/instance.dart';

enum FilePolicy { always, once }

/// What must be in an instance's folder
/// (`GET /api/v1/instances/:id/manifest`).
class Manifest {
  final int contentVersion;
  final String minecraftVersion;
  final LoaderType loaderType;
  final String? loaderVersion;
  final String? serverAddress;

  /// Folders where anything not in [files] is deleted.
  final List<String> managedDirs;
  final List<ManifestFile> files;

  const Manifest({
    required this.contentVersion,
    required this.minecraftVersion,
    required this.loaderType,
    this.loaderVersion,
    this.serverAddress,
    required this.managedDirs,
    required this.files,
  });

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      contentVersion: json['contentVersion'],
      minecraftVersion: json['minecraft']['version'],
      loaderType: LoaderType.values.byName(json['loader']['type']),
      loaderVersion: json['loader']['version'],
      serverAddress: json['server']['address'],
      managedDirs: List<String>.from(json['managedDirs']),
      files: [for (final file in json['files']) ManifestFile.fromJson(file)],
    );
  }

  Map<String, dynamic> toJson() => {
    'contentVersion': contentVersion,
    'minecraft': {'version': minecraftVersion},
    'loader': {'type': loaderType.name, 'version': loaderVersion},
    'server': {'address': serverAddress},
    'managedDirs': managedDirs,
    'files': [for (final file in files) file.toJson()],
  };
}

class ManifestFile {
  /// Relative path with `/`, inside the instance folder.
  final String path;
  final String sha256;
  final int size;
  final FilePolicy policy;

  /// Signed download URL, valid for 6 to 12 hours.
  final String url;

  const ManifestFile({
    required this.path,
    required this.sha256,
    required this.size,
    required this.policy,
    required this.url,
  });

  factory ManifestFile.fromJson(Map<String, dynamic> json) {
    return ManifestFile(
      path: json['path'],
      sha256: json['sha256'],
      size: json['size'],
      policy: FilePolicy.values.byName(json['policy']),
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() => {
    'path': path,
    'sha256': sha256,
    'size': size,
    'policy': policy.name,
    'url': url,
  };
}
