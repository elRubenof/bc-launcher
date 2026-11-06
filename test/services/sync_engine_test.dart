import 'dart:convert';
import 'dart:io';

import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/sync_engine.dart';
import 'package:bc_launcher/services/sync_plan.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import '../fixtures.dart';
import 'fake_server.dart';

void main() {
  late Directory support;
  late FakeServer server;
  late ApiClient client;
  late Directory instance;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('sync_engine_test');
    InstanceManager.supportDirectory = () async => support;
    server = FakeServer();
    FileDownloader.dio.httpClientAdapter = server;
    client = ApiClient(
      Organization.fromDiscovery(
        fixture('discovery'),
        url: 'https://example.com',
        apiVersion: 1,
      ),
      getToken: () async => 'token',
      dio: Dio()..httpClientAdapter = server,
    );
    instance = await InstanceManager.instanceFolder('example.com', 'test');
  });
  tearDown(() => support.delete(recursive: true));

  File local(String path) =>
      File(joinAll([instance.path, ...posix.split(path)]));
  Future<void> write(String path, String contents) async {
    await local(path).create(recursive: true);
    await local(path).writeAsString(contents);
  }

  Future<String> read(String path) => local(path).readAsString();

  Future<void> sync({void Function(SyncProgress)? onProgress}) =>
      SyncEngine.sync(client, 'example.com', 'test', onProgress: onProgress);

  test('an empty folder gets every file', () async {
    server.files = {'mods/a.jar': 'mod a', 'config/a.json': '{}'};
    final progress = <SyncProgress>[];

    await sync(onProgress: progress.add);

    expect(await read('mods/a.jar'), 'mod a');
    expect(await read('config/a.json'), '{}');
    expect(progress.first.files, 0);
    expect(progress.last.files, 2);
    expect(progress.last.totalFiles, 2);
    expect(progress.last.fraction, 1);
    final launcher = Directory(join(instance.path, '.bc-launcher'));
    expect(
      jsonDecode(
        await File(join(launcher.path, 'installed.json')).readAsString(),
      ),
      ['config/a.json', 'mods/a.jar'],
    );
    expect(await File(join(launcher.path, 'manifest.json')).exists(), isTrue);
  });

  test('a second sync repairs what the player changed or deleted', () async {
    server.files = {'mods/a.jar': 'mod a', 'config/a.json': '{}'};
    await sync();
    await write('mods/a.jar', 'tampered');
    await local('config/a.json').delete();

    await sync();

    expect(await read('mods/a.jar'), 'mod a');
    expect(await read('config/a.json'), '{}');
    // The manifest didn't change: the saved one was used.
    expect(server.manifests, 1);
  });

  test('a once file is not replaced once it exists', () async {
    server.files = {'options.txt': 'defaults'};
    server.policies = {'options.txt': 'once'};
    await sync();
    await write('options.txt', 'my options');

    await sync();

    expect(await read('options.txt'), 'my options');
  });

  test(
    'deletes extras in managed folders and what the organization removed',
    () async {
      server.files = {'mods/a.jar': 'mod a', 'config/old.json': 'old'};
      await sync();
      await write('mods/players-own.jar', 'mine');
      await write('config/players-own.json', 'mine');
      await write('saves/world/level.dat', 'world');

      server.files = {'mods/a.jar': 'mod a'};
      server.etag = '"2"';
      await sync();

      expect(await local('mods/players-own.jar').exists(), isFalse);
      expect(await local('config/old.json').exists(), isFalse);
      expect(await read('config/players-own.json'), 'mine');
      expect(await read('saves/world/level.dat'), 'world');
    },
  );

  test('a corrupted download fails and leaves nothing behind', () async {
    server.files = {'mods/a.jar': 'mod a'};
    server.corrupt = {'mods/a.jar': 'not mod a'};

    await expectLater(sync(), throwsA(isA<FileSystemException>()));

    expect(await local('mods/a.jar').exists(), isFalse);
    expect(await File('${local('mods/a.jar').path}.part').exists(), isFalse);
  });

  test('expired download URLs fetch a fresh manifest and carry on', () async {
    server.files = {'mods/a.jar': 'mod a'};
    server.expireUntilManifest = 1;

    await sync();

    expect(await read('mods/a.jar'), 'mod a');
    expect(server.manifests, 2);
    final manifestRequests = server.requests
        .where((r) => r.uri.path.endsWith('/manifest'))
        .toList();
    expect(manifestRequests.last.headers, isNot(contains('If-None-Match')));
  });

  test('an unsafe path writes nothing', () async {
    server.files = {'../outside.jar': 'evil'};

    await expectLater(sync(), throwsA(isA<UnsafePathError>()));

    expect(
      await File(join(instance.parent.path, 'outside.jar')).exists(),
      isFalse,
    );
  });
}
