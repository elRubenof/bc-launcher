import 'dart:convert';
import 'dart:io';

import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/shared_files.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

void main() {
  late Directory shared;

  setUp(() async {
    shared = await Directory.systemTemp.createTemp('shared_files_test');
    InstanceManager.supportDirectory = () async => shared;
  });
  tearDown(() => shared.delete(recursive: true));

  File file(String path) => File(joinAll([shared.path, ...posix.split(path)]));

  Future<void> write(String path, [String contents = '']) async {
    await file(path).create(recursive: true);
    await file(path).writeAsString(contents);
  }

  /// An installed instance whose version uses [libraries] and the asset
  /// index [assets].
  Future<void> instance(
    String path, {
    required List<String> libraries,
    String assets = '17',
  }) async {
    await Directory(
      joinAll([shared.path, ...posix.split(path), '.bc-launcher']),
    ).create(recursive: true);
    await write(
      '$path/versions/1.21.1/1.21.1.json',
      jsonEncode({
        'id': '1.21.1',
        'assetIndex': {'id': assets},
        'libraries': [
          for (final name in libraries) {'name': name},
        ],
      }),
    );
  }

  Future<void> assetIndex(String id, List<String> hashes) => write(
    'assets/indexes/$id.json',
    jsonEncode({
      'objects': {
        for (final hash in hashes) 'name/$hash': {'hash': hash, 'size': 1},
      },
    }),
  );

  String object(String hash) => 'assets/objects/${hash.substring(0, 2)}/$hash';

  setUp(() async {
    await write('libraries/org/a/1.0/a-1.0.jar');
    await write('libraries/org/b/1.0/b-1.0.jar');
    await write('libraries/org/old/1.0/old-1.0.jar');
    await assetIndex('17', ['aa11', 'bb22']);
    await assetIndex('5', ['cc33']);
    for (final hash in ['aa11', 'bb22', 'cc33', 'dd44']) {
      await write(object(hash));
    }
    await write('runtime/java-runtime-delta/mac-os/.installed');
  });

  test('keeps what instances use and deletes the rest', () async {
    await instance('a.com/one', libraries: ['org:a:1.0']);
    await instance('b.com/two', libraries: ['org:b:1.0']);

    await SharedFiles.cleanUnused(shared);

    expect(await file('libraries/org/a/1.0/a-1.0.jar').exists(), isTrue);
    expect(await file('libraries/org/b/1.0/b-1.0.jar').exists(), isTrue);
    expect(await file('libraries/org/old/1.0/old-1.0.jar').exists(), isFalse);
    expect(
      await Directory(join(shared.path, 'libraries', 'org', 'old')).exists(),
      isFalse,
    );
    expect(await file('assets/indexes/17.json').exists(), isTrue);
    expect(await file('assets/indexes/5.json').exists(), isFalse);
    expect(await file(object('aa11')).exists(), isTrue);
    expect(await file(object('bb22')).exists(), isTrue);
    expect(await file(object('cc33')).exists(), isFalse);
    expect(await file(object('dd44')).exists(), isFalse);
    // Java is never cleaned.
    expect(
      await file('runtime/java-runtime-delta/mac-os/.installed').exists(),
      isTrue,
    );
  });

  test('removing an organization keeps what another one still uses', () async {
    await instance('a.com/one', libraries: ['org:a:1.0', 'org:b:1.0']);
    await instance('b.com/two', libraries: ['org:b:1.0']);

    await InstanceManager.deleteOrganization('a.com');

    expect(await Directory(join(shared.path, 'a.com')).exists(), isFalse);
    expect(await file('libraries/org/a/1.0/a-1.0.jar').exists(), isFalse);
    expect(await file('libraries/org/b/1.0/b-1.0.jar').exists(), isTrue);
    expect(await file(object('aa11')).exists(), isTrue);
  });

  test(
    'removing the last organization leaves nothing shared but Java',
    () async {
      await instance('a.com/one', libraries: ['org:a:1.0']);

      await InstanceManager.deleteOrganization('a.com');

      expect(await Directory(join(shared.path, 'libraries')).exists(), isTrue);
      expect(
        await Directory(join(shared.path, 'libraries')).list().isEmpty,
        isTrue,
      );
      expect(await file(object('aa11')).exists(), isFalse);
      expect(
        await file('runtime/java-runtime-delta/mac-os/.installed').exists(),
        isTrue,
      );
    },
  );

  test('a version JSON it can not read deletes nothing', () async {
    await instance('a.com/one', libraries: ['org:a:1.0']);
    await write('b.com/two/.bc-launcher/state.json', '{}');
    await write('b.com/two/versions/1.21.1/1.21.1.json', '{broken');

    await SharedFiles.cleanUnused(shared);

    expect(await file('libraries/org/old/1.0/old-1.0.jar').exists(), isTrue);
    expect(await file(object('dd44')).exists(), isTrue);
  });

  test('folders without .bc-launcher are not instances', () async {
    await instance('a.com/one', libraries: ['org:a:1.0']);
    // An old launcher's instance, or anything else in the folder.
    await write(
      'legacy/versions/1.21.1/1.21.1.json',
      jsonEncode({
        'libraries': [
          {'name': 'org:old:1.0'},
        ],
      }),
    );

    await SharedFiles.cleanUnused(shared);

    expect(await file('libraries/org/old/1.0/old-1.0.jar').exists(), isFalse);
  });
}
