import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/services/game_installer.dart';
import 'package:bc_launcher/services/library_manager.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_core.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_helper.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

/// A step of the Forge or NeoForge installer failed.
class LoaderInstallError implements Exception {
  final LoaderType loader;
  final String message;

  const LoaderInstallError(this.loader, this.message);

  @override
  String toString() => "LoaderInstallError(${loader.name}, $message)";
}

/// This launcher can't install [loader] for Minecraft [minecraft].
class UnsupportedLoaderError implements Exception {
  final LoaderType loader;
  final String minecraft;

  const UnsupportedLoaderError(this.loader, this.minecraft);

  @override
  String toString() => "UnsupportedLoaderError(${loader.name}, $minecraft)";
}

/// Installs Forge (1.7.10+) and NeoForge with their official installer: its
/// version JSON, its libraries and the files its processors make from
/// Minecraft's client jar (1.13+), which go to the shared `libraries/`.
///
/// Those files are in no version JSON, so the version JSON it saves lists
/// them under [generatedKey]; it is saved last, so an installation that
/// failed half way is done again.
class ForgeInstaller {
  static const generatedKey = "bcLauncherGenerated";

  static const _maven = {
    LoaderType.forge:
        "https://maven.minecraftforge.net/net/minecraftforge/forge",
    LoaderType.neoforge:
        "https://maven.neoforged.net/releases/net/neoforged/neoforge",
  };

  /// The oldest Minecraft each loader is installed for: older Forge needs
  /// files from servers that are gone or a Java older than Mojang's.
  static const _oldest = {
    LoaderType.forge: [1, 7, 10],
    LoaderType.neoforge: [1, 20, 2],
  };

  /// Whether it installs [loader] for Minecraft [minecraft].
  static bool supports(LoaderType loader, String minecraft) {
    final oldest = _oldest[loader]!;
    final parts = minecraft.split(".").map(int.tryParse).toList();
    if (parts.contains(null)) return true;

    for (var i = 0; i < oldest.length; i++) {
      final part = i < parts.length ? parts[i]! : 0;
      if (part != oldest[i]) return part > oldest[i];
    }
    return true;
  }

  /// Runs a processor (tests replace it).
  @visibleForTesting
  static Future<ProcessResult> Function(
    String executable,
    List<String> arguments,
  )
  runProcess = (executable, arguments) => Process.run(executable, arguments);

  /// The installer of [loader] [version] for Minecraft [minecraft]. The
  /// Forge one is named after both; NeoForge versions name Minecraft's.
  static String installerUrl(
    LoaderType loader,
    String minecraft,
    String version,
  ) {
    final artifact = loader == LoaderType.forge
        ? "$minecraft-$version"
        : version;
    return "${_maven[loader]}/$artifact/${loader.name}-$artifact-installer.jar";
  }

  /// The version to launch, named as the installers name it.
  static String versionId(
    LoaderType loader,
    String minecraft,
    String version,
  ) => loader == LoaderType.forge
      ? "$minecraft-forge-$version"
      : "neoforge-$version";

  /// Whether [id] is installed in [folder]: its version JSON, saved by this
  /// installer, and every file its processors made in [shared].
  static Future<bool> isInstalled(
    String id,
    Directory folder,
    Directory shared,
  ) async {
    final file = File(join(folder.path, "versions", id, "$id.json"));
    try {
      final data = jsonDecode(await file.readAsString()) as Map;
      final generated = data[generatedKey] as List?;
      if (generated == null) return false;

      for (final String path in generated) {
        if (!await File(_sharedPath(shared, path)).exists()) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Installs [loader] [version] for Minecraft [minecraft], whose version
  /// JSON is already in [folder], unless it is installed. [java] gives the
  /// Java to run the processors with.
  static Future<void> install(
    LoaderType loader,
    String minecraft,
    String version,
    Directory folder,
    Directory shared, {
    required Future<String> Function(Map versionData) java,
    void Function(double progress)? onProgress,
  }) async {
    if (!supports(loader, minecraft)) {
      throw UnsupportedLoaderError(loader, minecraft);
    }

    final id = versionId(loader, minecraft, version);
    if (await isInstalled(id, folder, shared)) return;

    final temp = await Directory.systemTemp.createTemp("bc-launcher-forge");
    try {
      final jar = join(temp.path, "installer.jar");
      try {
        await FileDownloader.downloadAll([
          DownloadTask(
            path: jar,
            url: installerUrl(loader, minecraft, version),
          ),
        ]);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          throw UnknownLoaderVersionError(loader, version);
        }
        rethrow;
      }
      onProgress?.call(0.1);

      final installer = join(temp.path, "installer");
      await Isolate.run(() => extractFileToDisk(jar, installer));

      final profile = await _readJson(join(installer, "install_profile.json"));
      await _copyMaven(installer, shared);

      // Before 1.12.2's last builds the version JSON is in the profile and
      // Forge's jar beside it, with nothing to run.
      final legacy = profile["versionInfo"] as Map?;
      final versionJson =
          legacy ??
          await _readJson(
            _inInstaller(installer, profile["json"] ?? "/version.json"),
          );
      final generated = <String>[];
      if (legacy != null) {
        final install = profile["install"] as Map;
        final forge = File(_libraryPath(install["path"], shared));
        await forge.parent.create(recursive: true);
        await File(_inInstaller(installer, install["filePath"]))
            .copy(forge.path);
        generated.add(_relative(forge.path, shared));
      }

      // Saved now to read it with Minecraft's; without the generated files
      // it isn't installed yet.
      versionJson["id"] = id;
      final file = File(join(folder.path, "versions", id, "$id.json"));
      await _writeJson(file, versionJson);

      final versionData = await MinecraftLauncherCore.loadVersionData(
        id,
        folder.path,
      );
      await LibraryManager.ensureLibraries(
        versionData,
        folder,
        sharedRoot: shared,
      );
      await LibraryManager.ensureLibraries(
        {"id": id, "libraries": profile["libraries"] ?? []},
        folder,
        sharedRoot: shared,
      );
      onProgress?.call(0.3);

      final variables = _variables(
        profile,
        installer: installer,
        installerJar: jar,
        shared: shared,
        minecraft: minecraft,
        clientJar: MinecraftLauncherCore.clientJarPath(
          versionData,
          folder.path,
        ),
      );

      final processors = [
        for (final Map processor in profile["processors"] ?? [])
          if ((processor["sides"] as List?)?.contains("client") ?? true)
            processor,
      ];
      final executable = await java(versionData);
      for (final (index, processor) in processors.indexed) {
        await _runProcessor(loader, processor, variables, executable, shared);
        onProgress?.call(0.3 + 0.7 * (index + 1) / processors.length);
      }

      // Every file the processors made that the game may need.
      for (final Map value in (profile["data"] as Map? ?? {}).values) {
        final client = value["client"];
        if (client is! String || !_isArtifact(client)) continue;

        final path = _libraryPath(client, shared);
        if (await File(path).exists()) {
          generated.add(_relative(path, shared));
        }
      }
      versionJson[generatedKey] = generated;
      await _writeJson(file, versionJson);
      onProgress?.call(1);
    } finally {
      await temp.delete(recursive: true);
    }
  }

  /// The values of `{NAME}` in the processors' arguments.
  static Map<String, String> _variables(
    Map profile, {
    required String installer,
    required String installerJar,
    required Directory shared,
    required String minecraft,
    required String clientJar,
  }) {
    final variables = {
      "SIDE": "client",
      "MINECRAFT_JAR": clientJar,
      "MINECRAFT_VERSION": minecraft,
      "ROOT": shared.path,
      "INSTALLER": installerJar,
      "LIBRARY_DIR": join(shared.path, "libraries"),
    };

    for (final MapEntry(:key, :value)
        in (profile["data"] as Map? ?? {}).entries) {
      final client = (value as Map)["client"];
      if (client is! String) continue;

      variables[key as String] = switch (client) {
        _ when _isArtifact(client) => _libraryPath(client, shared),
        _ when client.startsWith("'") && client.endsWith("'") =>
          client.substring(1, client.length - 1),
        _ when client.startsWith("/") => _inInstaller(installer, client),
        _ => client,
      };
    }
    return variables;
  }

  static Future<void> _runProcessor(
    LoaderType loader,
    Map processor,
    Map<String, String> variables,
    String java,
    Directory shared,
  ) async {
    String resolve(String value) {
      value = value.replaceAllMapped(
        RegExp(r"\{(\w+)\}"),
        (match) => variables[match[1]] ?? match[0]!,
      );
      return _isArtifact(value) ? _libraryPath(value, shared) : value;
    }

    final outputs = {
      for (final MapEntry(:key, :value)
          in (processor["outputs"] as Map? ?? {}).entries)
        resolve(key as String): resolve(value as String),
    };
    if (outputs.isNotEmpty && await _matches(outputs)) return;

    final jar = _libraryPath(processor["jar"], shared);
    final classpath = [
      jar,
      for (final String name in processor["classpath"] ?? [])
        _libraryPath(name, shared),
    ];
    final mainClass = await Isolate.run(() => _mainClass(jar));
    if (mainClass == null) {
      throw LoaderInstallError(loader, "No main class in ${processor["jar"]}");
    }

    final result = await runProcess(java, [
      "-cp",
      classpath.join(MinecraftLauncherHelper.getClasspathSeparator()),
      mainClass,
      for (final String argument in processor["args"] ?? []) resolve(argument),
    ]);
    if (result.exitCode != 0) {
      log("${processor["jar"]} failed:\n${result.stdout}\n${result.stderr}");
      throw LoaderInstallError(
        loader,
        "${processor["jar"]} exited with ${result.exitCode}",
      );
    }

    if (outputs.isNotEmpty && !await _matches(outputs)) {
      throw LoaderInstallError(
        loader,
        "${processor["jar"]} made files that don't match",
      );
    }
  }

  /// Whether every output exists with its sha1.
  static Future<bool> _matches(Map<String, String> outputs) async {
    for (final MapEntry(key: path, value: sha1) in outputs.entries) {
      final file = File(path);
      if (!await file.exists() || await FileDownloader.sha1Of(file) != sha1) {
        return false;
      }
    }
    return true;
  }

  /// The `Main-Class` of a jar's manifest.
  static String? _mainClass(String jar) {
    final archive = ZipDecoder().decodeBytes(File(jar).readAsBytesSync());
    final manifest = archive.findFile("META-INF/MANIFEST.MF");
    if (manifest == null) return null;

    for (final line in const LineSplitter().convert(
      utf8.decode(manifest.content as List<int>),
    )) {
      if (line.startsWith("Main-Class:")) {
        return line.substring("Main-Class:".length).trim();
      }
    }
    return null;
  }

  /// Copies the libraries the installer brings (`maven/`, before 1.17) to
  /// the shared `libraries/`.
  static Future<void> _copyMaven(String installer, Directory shared) async {
    final maven = Directory(join(installer, "maven"));
    if (!await maven.exists()) return;

    await for (final entity in maven.list(recursive: true)) {
      if (entity is! File) continue;

      final target = File(
        join(shared.path, "libraries", relative(entity.path, from: maven.path)),
      );
      if (await target.exists()) continue;

      await target.parent.create(recursive: true);
      await entity.copy(target.path);
    }
  }

  /// `[group:name:version:classifier@ext]`, a library.
  static bool _isArtifact(String value) =>
      value.startsWith("[") && value.endsWith("]");

  static String _libraryPath(String name, Directory shared) {
    if (_isArtifact(name)) name = name.substring(1, name.length - 1);
    return MinecraftLauncherHelper.getLibraryPath(name, shared.path);
  }

  /// A file of the installer, by its path in the jar (`/data/client.lzma`).
  static String _inInstaller(String installer, String path) =>
      joinAll([installer, ...posix.split(path).where((part) => part != "/")]);

  /// [path] in [shared], as the version JSON lists it.
  static String _relative(String path, Directory shared) =>
      posix.joinAll(split(relative(path, from: shared.path)));

  static String _sharedPath(Directory shared, String path) =>
      joinAll([shared.path, ...posix.split(path)]);

  static Future<Map> _readJson(String path) async =>
      jsonDecode(await File(path).readAsString()) as Map;

  static Future<void> _writeJson(File file, Map json) async {
    await file.parent.create(recursive: true);
    final part = File("${file.path}.part");
    await part.writeAsString(jsonEncode(json));
    await part.rename(file.path);
  }
}
