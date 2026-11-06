import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bc_launcher/services/game_process.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

/// A game that writes [stdout] and [stderr], runs [whilePlaying] and exits
/// with [exitCode].
class FakeGame implements Process {
  final _stdout = StreamController<List<int>>();
  final _stderr = StreamController<List<int>>();
  final _exitCode = Completer<int>();

  final List<String> _out;
  final List<String> _err;
  final int _code;
  final Future<void> Function()? whilePlaying;

  FakeGame({
    List<String> stdout = const [],
    List<String> stderr = const [],
    int exitCode = 0,
    this.whilePlaying,
  }) : _out = stdout,
       _err = stderr,
       _code = exitCode;

  /// Plays once the launcher starts it.
  Future<void> start() async {
    for (final line in _out) {
      _stdout.add(utf8.encode("$line\n"));
    }
    for (final line in _err) {
      _stderr.add(utf8.encode("$line\n"));
    }
    await whilePlaying?.call();
    await _stdout.close();
    await _stderr.close();
    _exitCode.complete(_code);
  }

  @override
  Stream<List<int>> get stdout => _stdout.stream;

  @override
  Stream<List<int>> get stderr => _stderr.stream;

  @override
  Future<int> get exitCode => _exitCode.future;

  @override
  int get pid => 1;

  @override
  IOSink get stdin => throw UnimplementedError();

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) => false;
}

void main() {
  late Directory folder;
  late List<String> started;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('game_process_test');
    started = [];
  });
  tearDown(() => folder.delete(recursive: true));

  void play(FakeGame game) {
    GameProcess.startProcess =
        (executable, arguments, {workingDirectory}) async {
          started.add([executable, ...arguments, workingDirectory].join(' '));
          game.start();
          return game;
        };
  }

  test('keeps the output of the game, without the token', () async {
    play(
      FakeGame(
        stdout: ['Setting user: Nyxar', 'Token secret-token used'],
        stderr: ['A warning'],
      ),
    );
    var onStarted = 0;

    final exit = await GameProcess.run(
      ['java', '-jar', 'game.jar', '--accessToken', 'secret-token'],
      folder,
      secrets: ['secret-token'],
      onStarted: () => onStarted++,
      now: DateTime(2026, 11, 6, 18, 42, 5),
    );

    expect(started, [
      'java -jar game.jar --accessToken secret-token ${folder.path}',
    ]);
    expect(onStarted, 1);
    expect(exit.started, isTrue);
    expect(exit.crashed, isFalse);
    expect(
      exit.log.path,
      join(folder.path, '.bc-launcher', 'logs', '2026-11-06_18-42-05.log'),
    );

    final log = await exit.log.readAsString();
    expect(log, contains('Setting user: Nyxar'));
    expect(log, contains('Token <hidden> used'));
    expect(log, contains('A warning'));
    expect(log, isNot(contains('secret-token')));
  });

  test('a game that writes nothing never started', () async {
    play(FakeGame(exitCode: 1));
    var onStarted = 0;

    final exit = await GameProcess.run(
      ['java'],
      folder,
      onStarted: () => onStarted++,
    );

    expect(onStarted, 0);
    expect(exit.started, isFalse);
    expect(exit.crashed, isFalse);
  });

  test('an exit code other than 0 is a crash', () async {
    play(FakeGame(stdout: ['Loading'], exitCode: -1));

    final exit = await GameProcess.run(['java'], folder);

    expect(exit.exitCode, -1);
    expect(exit.crashed, isTrue);
    expect(exit.crashReport, isNull);
  });

  test('a new crash report is a crash, kept beside the log', () async {
    final reports = Directory(join(folder.path, 'crash-reports'));
    await reports.create();
    await File(join(reports.path, 'crash-2026-11-01_10.00.00-client.txt'))
        .writeAsString('old');

    play(
      FakeGame(
        stdout: ['Loading'],
        whilePlaying: () =>
            File(join(reports.path, 'crash-2026-11-06_18.50.00-client.txt'))
                .writeAsString('new, by secret-token'),
      ),
    );

    final exit = await GameProcess.run(
      ['java'],
      folder,
      secrets: ['secret-token'],
      now: DateTime(2026, 11, 6, 18, 42, 5),
    );

    expect(exit.exitCode, 0);
    expect(exit.crashed, isTrue);
    expect(
      exit.crashReport?.path,
      join(
        GameProcess.logsFolder(folder).path,
        '2026-11-06_18-42-05.crash.txt',
      ),
    );
    expect(await exit.crashReport!.readAsString(), 'new, by <hidden>');
  });

  test('keeps only the newest logs', () async {
    final logs = GameProcess.logsFolder(folder);
    await logs.create(recursive: true);
    for (var day = 1; day <= GameProcess.keptLogs; day++) {
      final name = '2026-10-${day.toString().padLeft(2, '0')}_12-00-00.log';
      await File(join(logs.path, name)).writeAsString('old');
    }
    await File(join(logs.path, '2026-10-01_12-00-00.crash.txt'))
        .writeAsString('old');
    play(FakeGame(stdout: ['Loading']));

    await GameProcess.run(['java'], folder, now: DateTime(2026, 11, 6));

    final names = [for (final file in logs.listSync()) basename(file.path)]
      ..sort();
    expect(names, hasLength(GameProcess.keptLogs));
    expect(names.first, '2026-10-02_12-00-00.log');
    expect(names.last, '2026-11-06_00-00-00.log');
  });
}
