import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bc_launcher/services/game_process.dart';
import 'package:bc_launcher/services/log_export.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

void main() {
  late Directory folder;
  late Directory logs;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('log_export_test');
    logs = GameProcess.logsFolder(folder);
  });
  tearDown(() => folder.delete(recursive: true));

  Map<String, String> unzip(List<int> zip) => {
    for (final file in ZipDecoder().decodeBytes(zip).files)
      file.name: utf8.decode(file.content),
  };

  test('nothing to export before the first game', () async {
    expect(await LogExport.zip(folder, {}), isNull);

    await logs.create(recursive: true);
    expect(await LogExport.zip(folder, {}), isNull);
  });

  test('the last game, its crash report and the info', () async {
    await logs.create(recursive: true);
    await File(join(logs.path, '2026-11-05_10-00-00.log')).writeAsString('old');
    await File(join(logs.path, '2026-11-05_10-00-00.crash.txt'))
        .writeAsString('old crash');
    await File(join(logs.path, '2026-11-06_18-42-05.log')).writeAsString('new');
    await File(join(logs.path, '2026-11-06_18-42-05.crash.txt'))
        .writeAsString('new crash');

    final zip = await LogExport.zip(folder, {
      'launcher': '1.0.0',
      'instance': 'spartaland-3',
    });

    expect(unzip(zip!), {
      'info.txt': 'launcher: 1.0.0\ninstance: spartaland-3',
      '2026-11-06_18-42-05.log': 'new',
      '2026-11-06_18-42-05.crash.txt': 'new crash',
    });
  });

  test('a game without a crash report', () async {
    await logs.create(recursive: true);
    await File(join(logs.path, '2026-11-05_10-00-00.crash.txt'))
        .writeAsString('old crash');
    await File(join(logs.path, '2026-11-06_18-42-05.log')).writeAsString('new');

    final zip = await LogExport.zip(folder, {});

    expect(unzip(zip!).keys, ['info.txt', '2026-11-06_18-42-05.log']);
  });
}
