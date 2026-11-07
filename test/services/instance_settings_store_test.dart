import 'dart:io';

import 'package:bc_launcher/models/instance_settings.dart';
import 'package:bc_launcher/services/instance_settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;

void main() {
  late Directory folder;
  File file() => File(join(folder.path, ".bc-launcher", "settings.json"));

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('instance_settings');
  });
  tearDown(() => folder.delete(recursive: true));

  test('without a file, the defaults', () async {
    final store = InstanceSettingsStore(folder);
    await store.load();
    expect(store.value.toJson(), isEmpty);
  });

  test('saves in .bc-launcher/settings.json and reads it back', () async {
    final store = InstanceSettingsStore(folder);
    await store.save(const InstanceSettings(ramGb: 6, autoConnect: false));
    expect(store.value.ramGb, 6);
    expect(await file().exists(), isTrue);
    expect(await File("${file().path}.part").exists(), isFalse);

    final again = InstanceSettingsStore(folder);
    await again.load();
    expect(again.value.toJson(), {'ramGb': 6, 'autoConnect': false});
  });

  test('a broken file is the defaults', () async {
    await file().parent.create(recursive: true);
    await file().writeAsString('{not json');

    final store = InstanceSettingsStore(folder);
    await store.load();
    expect(store.value.toJson(), isEmpty);
  });

  test('reset deletes the file', () async {
    final store = InstanceSettingsStore(folder);
    await store.save(const InstanceSettings(ramGb: 6));
    await store.reset();
    expect(store.value.toJson(), isEmpty);
    expect(await file().exists(), isFalse);
  });
}
