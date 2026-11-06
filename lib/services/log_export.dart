import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/services/game_process.dart';
import 'package:file_selector/file_selector.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart';

/// The logs of an instance's last game, zipped for its organization's
/// support. They never hold the token (see [GameProcess]).
class LogExport {
  /// The last game's log of the instance in [folder], its crash report and
  /// an `info.txt` with [info], or null before its first game.
  static Future<Uint8List?> zip(
    Directory folder,
    Map<String, String> info,
  ) async {
    final logs = GameProcess.logsFolder(folder);
    if (!await logs.exists()) return null;

    final names = [
      await for (final entity in logs.list())
        if (entity is File && entity.path.endsWith(".log")) entity.path,
    ]..sort();
    if (names.isEmpty) return null;

    final log = File(names.last);
    final crashReport = File(GameProcess.crashReportOf(log));

    final archive = Archive()
      ..addFile(
        ArchiveFile.string(
          "info.txt",
          [for (final entry in info.entries) "${entry.key}: ${entry.value}"]
              .join("\n"),
        ),
      )
      ..addFile(ArchiveFile.bytes(basename(log.path), await log.readAsBytes()));
    if (await crashReport.exists()) {
      archive.addFile(
        ArchiveFile.bytes(
          basename(crashReport.path),
          await crashReport.readAsBytes(),
        ),
      );
    }

    return ZipEncoder().encodeBytes(archive);
  }

  /// Zips the last game's logs of [instance], in [folder], and asks where to
  /// save them, named by [fileName] with today's date. Returns false if it
  /// has no games yet.
  static Future<bool> export(
    Instance instance,
    Directory folder,
    String Function(String date) fileName,
  ) async {
    final logs = await zip(folder, await info(instance));
    if (logs == null) return false;

    final date = DateTime.now().toIso8601String().substring(0, 10);
    await save(logs, "${fileName(date)}.zip");
    return true;
  }

  /// What the organization needs to know about this launcher and [instance].
  static Future<Map<String, String>> info(Instance instance) async => {
    "launcher": (await PackageInfo.fromPlatform()).version,
    "system": "${Platform.operatingSystem} ${Platform.operatingSystemVersion}",
    "instance": instance.id,
    "minecraft": instance.minecraftVersion,
    "loader": [instance.loaderType.name, ?instance.loaderVersion].join(" "),
  };

  /// Asks where to save [zip], suggesting [name], and saves it there.
  /// Returns false if the player cancels.
  static Future<bool> save(Uint8List zip, String name) async {
    final location = await getSaveLocation(
      suggestedName: name,
      acceptedTypeGroups: const [
        XTypeGroup(label: "ZIP", extensions: ["zip"]),
      ],
    );
    if (location == null) return false;

    await File(location.path).writeAsBytes(zip);
    return true;
  }
}
