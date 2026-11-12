import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

/// How a game ended.
class GameExit {
  final int exitCode;

  /// Whether the game wrote anything; if not, it never started.
  final bool started;

  /// This game's output.
  final File log;

  /// The crash report the game wrote, if any, copied beside [log].
  final File? crashReport;

  const GameExit({
    required this.exitCode,
    required this.started,
    required this.log,
    this.crashReport,
  });

  /// The game started and then closed with an error.
  bool get crashed => started && (exitCode != 0 || crashReport != null);
}

/// Runs the game in an instance's folder and keeps its output in
/// `.bc-launcher/logs/`, one file per game (and its crash report), without
/// the [secrets] passed.
class GameProcess {
  /// Games whose log is kept per instance.
  static const keptLogs = 20;

  /// Starts processes (tests replace it).
  @visibleForTesting
  static Future<Process> Function(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
  })
  startProcess = Process.start;

  /// The folder with the game logs of the instance in [folder].
  static Directory logsFolder(Directory folder) =>
      Directory(join(folder.path, ".bc-launcher", "logs"));

  /// Runs [command] in [folder] until the game closes. [onStarted] is called
  /// with the game's first output.
  static Future<GameExit> run(
    List<String> command,
    Directory folder, {
    List<String> secrets = const [],
    VoidCallback? onStarted,
    DateTime? now,
  }) async {
    final logs = logsFolder(folder);
    await logs.create(recursive: true);
    final name = _timestamp(now ?? DateTime.now());
    final log = File(join(logs.path, "$name.log"));
    await _deleteOldLogs(logs);

    final crashReports = Directory(join(folder.path, "crash-reports"));
    final previousReports = await _files(crashReports);

    final process = await startProcess(
      command.first,
      command.sublist(1),
      workingDirectory: folder.path,
    );

    final sink = log.openWrite();
    var started = false;
    String hide(String text) {
      for (final secret in secrets) {
        if (secret.isNotEmpty) text = text.replaceAll(secret, "<hidden>");
      }
      return text;
    }

    void write(String line) {
      if (!started) {
        started = true;
        onStarted?.call();
      }

      sink.writeln(hide(line));
    }

    // Both pipes are always read, or the game blocks once they fill up.
    Future<void> read(Stream<List<int>> stream) => stream
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .forEach(write);

    final (exitCode, _, _) = await (
      process.exitCode,
      read(process.stdout),
      read(process.stderr),
    ).wait;
    await sink.close();

    final newReports = (await _files(
      crashReports,
    )).where((file) => !previousReports.contains(file)).toList()..sort();

    File? crashReport;
    if (newReports.isNotEmpty) {
      final report = await File(newReports.last).readAsString();
      crashReport = File(crashReportOf(log));
      await crashReport.writeAsString(hide(report));
    }

    return GameExit(
      exitCode: exitCode,
      started: started,
      log: log,
      crashReport: crashReport,
    );
  }

  /// Where the crash report of the game with [log] is kept.
  static String crashReportOf(File log) =>
      "${withoutExtension(log.path)}.crash.txt";

  /// `2026-11-06_18-42-05`, which sorts by date.
  static String _timestamp(DateTime time) {
    String two(int n) => n.toString().padLeft(2, "0");
    return "${time.year}-${two(time.month)}-${two(time.day)}_"
        "${two(time.hour)}-${two(time.minute)}-${two(time.second)}";
  }

  /// Leaves room for one more log among the [keptLogs] newest.
  static Future<void> _deleteOldLogs(Directory logs) async {
    final files = (await _files(
      logs,
    )).where((path) => path.endsWith(".log")).toList()..sort();

    final extra = files.length - keptLogs + 1;
    for (final path in files.take(extra < 0 ? 0 : extra)) {
      await File(path).delete();

      final crashReport = File(crashReportOf(File(path)));
      if (await crashReport.exists()) await crashReport.delete();
    }
  }

  static Future<Set<String>> _files(Directory directory) async {
    if (!await directory.exists()) return {};

    return {
      await for (final entity in directory.list())
        if (entity is File) entity.path,
    };
  }
}
