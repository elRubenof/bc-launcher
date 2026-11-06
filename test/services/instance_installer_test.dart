import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/services/instance_installer.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/server_list.dart';
import 'package:dart_minecraft/dart_nbt.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import '../fixtures.dart';
import 'fake_server.dart';

void main() {
  late Directory support;
  late FakeServer server;
  late ApiClient client;
  late Directory folder;
  late List<String> prepared;
  late Object? prepareError;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('instance_installer_test');
    InstanceManager.supportDirectory = () async => support;
    server = FakeServer()..files = {'mods/a.jar': 'mod a'};
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
    folder = await InstanceManager.instanceFolder('example.com', 'test');
    prepared = [];
    prepareError = null;
    InstanceInstaller.prepareGame = (manifest, folder, onProgress) async {
      if (prepareError != null) throw prepareError!;
      prepared.add(manifest.minecraftVersion);
      onProgress?.call(1);
    };
  });
  tearDown(() => support.delete(recursive: true));

  /// The instance `test` as the organization lists it, matching the fake
  /// server's manifest.
  Instance instance({int contentVersion = 1, String? serverAddress}) {
    final json = Map<String, dynamic>.of(fixture('instances')['instances'][0]);
    json['id'] = 'test';
    json['name'] = 'Test';
    json['minecraft'] = {'version': '1.21.1'};
    json['loader'] = {'type': 'fabric', 'version': '0.16.5'};
    json['contentVersion'] = contentVersion;
    json['serverAddress'] = serverAddress;
    return Instance.fromJson(json);
  }

  Future<List<EntryStep>> enter(Instance instance) async {
    final steps = <EntryStep>[];
    await InstanceInstaller.enter(
      client,
      'example.com',
      instance,
      onStep: steps.add,
    );
    return steps;
  }

  Future<InstanceState?> state() =>
      InstanceManager.readState('example.com', 'test');

  File serversDat() => File(join(folder.path, 'servers.dat'));

  group('steps', () {
    test('the first time downloads and then installs', () async {
      final steps = await enter(instance());

      expect(steps, [EntryStep.downloading, EntryStep.installing]);
      expect(await File(join(folder.path, 'mods', 'a.jar')).exists(), isTrue);
      expect(prepared, ['1.21.1']);
      final saved = (await state())!;
      expect(saved.complete, isTrue);
      expect(saved.contentVersion, 1);
      expect(saved.minecraftVersion, '1.21.1');
      expect(saved.loaderType, LoaderType.fabric);
      expect(saved.loaderVersion, '0.16.5');
    });

    test('an instance up to date is checked and repaired', () async {
      await enter(instance());
      final mod = File(join(folder.path, 'mods', 'a.jar'));
      await mod.writeAsString('tampered');

      expect(await enter(instance()), [EntryStep.checking]);
      expect(await mod.readAsString(), 'mod a');
      // The manifest hadn't changed: 304, nothing sent again but the mod.
      expect(server.manifests, 1);
      expect(prepared, hasLength(2));
    });

    test('a new content version is one update step', () async {
      await enter(instance());
      server
        ..contentVersion = 2
        ..etag = '"2"'
        ..files = {'mods/b.jar': 'mod b'};

      final steps = await enter(instance(contentVersion: 2));

      expect(steps, [EntryStep.updating]);
      expect(await File(join(folder.path, 'mods', 'a.jar')).exists(), isFalse);
      expect(await File(join(folder.path, 'mods', 'b.jar')).exists(), isTrue);
      expect((await state())!.contentVersion, 2);
    });

    test('the state saves the versions of the manifest applied', () async {
      // The list was older than the content when it was fetched.
      server.contentVersion = 2;

      await enter(instance());

      expect((await state())!.contentVersion, 2);
    });
  });

  group('offline', () {
    test('an instance installed and up to date is entered as it is', () async {
      await enter(instance());
      server.offline = true;

      await enter(instance());

      expect((await state())!.complete, isTrue);
    });

    test('an instance that is not installed fails', () async {
      server.offline = true;

      await expectLater(
        enter(instance()),
        throwsA(predicate(InstanceInstaller.isOffline)),
      );
    });

    test('an instance with an update fails', () async {
      await enter(instance());
      server.offline = true;

      await expectLater(
        enter(instance(contentVersion: 2)),
        throwsA(predicate(InstanceInstaller.isOffline)),
      );
    });

    test('playing fails, so the game never starts unrepaired', () async {
      await enter(instance());
      server.offline = true;

      await expectLater(
        InstanceInstaller.play(client, 'example.com', instance()),
        throwsA(predicate(InstanceInstaller.isOffline)),
      );
    });
  });

  group('play', () {
    test('repairs an instance that is up to date', () async {
      await enter(instance());
      final mod = File(join(folder.path, 'mods', 'a.jar'));
      await mod.writeAsString('tampered');

      final version = await InstanceInstaller.play(
        client,
        'example.com',
        instance(),
      );

      expect(version, 'fabric-loader-0.16.5-1.21.1');
      expect(await mod.readAsString(), 'mod a');
      expect(prepared, hasLength(2));
    });

    test('applies an update and saves it', () async {
      await enter(instance());
      server
        ..contentVersion = 2
        ..etag = '"2"'
        ..files = {'mods/b.jar': 'mod b'};

      await InstanceInstaller.play(client, 'example.com', instance());

      expect(await File(join(folder.path, 'mods', 'b.jar')).exists(), isTrue);
      expect((await state())!.contentVersion, 2);
    });

    test('fails like entering', () async {
      await enter(instance());
      prepareError = Exception('no network');

      await expectLater(
        InstanceInstaller.play(client, 'example.com', instance()),
        throwsA(isA<GameFilesError>()),
      );
    });
  });

  group('failures', () {
    test('the state is incomplete until the installation ends', () async {
      prepareError = Exception('Version not found');

      await expectLater(enter(instance()), throwsA(isA<GameFilesError>()));

      expect((await state())!.complete, isFalse);
      expect(
        InstanceManager.statusOf(instance(), await state()),
        InstallStatus.notInstalled,
      );
    });

    test('an interrupted first time starts again without downloading what '
        'is fine', () async {
      prepareError = Exception('Version not found');
      await expectLater(enter(instance()), throwsA(isA<GameFilesError>()));
      prepareError = null;
      final blobs = server.requests.where(
        (r) => r.uri.path.startsWith('/blobs'),
      );
      final downloaded = blobs.length;

      final steps = await enter(instance());

      expect(steps, [EntryStep.downloading, EntryStep.installing]);
      expect(
        server.requests.where((r) => r.uri.path.startsWith('/blobs')).length,
        downloaded,
      );
      expect((await state())!.complete, isTrue);
    });

    test('a failed update keeps the installed versions', () async {
      await enter(instance());
      server
        ..contentVersion = 2
        ..etag = '"2"';
      prepareError = Exception('no network');

      await expectLater(
        enter(instance(contentVersion: 2)),
        throwsA(isA<GameFilesError>()),
      );

      final saved = (await state())!;
      expect(saved.contentVersion, 1);
      expect(saved.complete, isTrue);
    });
  });

  group('isOffline', () {
    test('no connection or a failing server', () {
      expect(
        InstanceInstaller.isOffline(const ApiError(ApiErrorType.offline)),
        isTrue,
      );
      expect(
        InstanceInstaller.isOffline(
          const ApiError(ApiErrorType.serverUnavailable),
        ),
        isTrue,
      );
      expect(
        InstanceInstaller.isOffline(
          DioException.connectionError(
            requestOptions: RequestOptions(),
            reason: 'refused',
          ),
        ),
        isTrue,
      );
      expect(
        InstanceInstaller.isOffline(const SocketException('down')),
        isTrue,
      );
    });

    test('anything else', () {
      expect(
        InstanceInstaller.isOffline(const ApiError(ApiErrorType.notFound)),
        isFalse,
      );
      expect(
        InstanceInstaller.isOffline(
          DioException.badResponse(
            statusCode: 404,
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 404,
            ),
          ),
        ),
        isFalse,
      );
      expect(InstanceInstaller.isOffline(const GameFilesError('x')), isFalse);
    });
  });

  group('servers.dat', () {
    test('the first time adds the instance server', () async {
      server.serverAddress = 'play.example.com';

      await enter(instance(serverAddress: 'play.example.com'));

      expect(await ServerList.addresses(serversDat()), ['play.example.com']);
      expect((await state())!.serverEntryAddress, 'play.example.com');
    });

    test('nothing is added without an address', () async {
      await enter(instance());

      expect(await serversDat().exists(), isFalse);
      expect((await state())!.serverEntryAddress, isNull);
    });

    test('the content\'s own servers.dat is kept', () async {
      server
        ..serverAddress = 'play.example.com'
        ..files = {'servers.dat': 'from the organization'}
        ..policies = {'servers.dat': 'once'};

      await enter(instance(serverAddress: 'play.example.com'));

      expect(await serversDat().readAsString(), 'from the organization');
      expect((await state())!.serverEntryAddress, isNull);
    });

    test('a list the player already has is not replaced', () async {
      server.serverAddress = 'play.example.com';
      await ServerList.create(serversDat(), 'Mine', 'my.server');

      await enter(instance(serverAddress: 'play.example.com'));

      expect(await ServerList.addresses(serversDat()), ['my.server']);
    });

    test('updates never add it', () async {
      await enter(instance());
      server
        ..contentVersion = 2
        ..etag = '"2"'
        ..serverAddress = 'play.example.com';

      await enter(
        instance(contentVersion: 2, serverAddress: 'play.example.com'),
      );

      expect(await serversDat().exists(), isFalse);
    });

    test('once deleted by the player it is not created again', () async {
      server.serverAddress = 'play.example.com';
      await enter(instance(serverAddress: 'play.example.com'));
      await serversDat().delete();
      server
        ..contentVersion = 2
        ..etag = '"2"';

      await enter(
        instance(contentVersion: 2, serverAddress: 'play.example.com'),
      );

      expect(await serversDat().exists(), isFalse);
    });

    test('a new address moves only the entry the launcher wrote', () async {
      server.serverAddress = 'old.example.com';
      await enter(instance(serverAddress: 'old.example.com'));
      // The player adds their own server after it.
      await _addServer(serversDat(), 'Mine', 'my.server');
      server
        ..contentVersion = 2
        ..etag = '"2"'
        ..serverAddress = 'new.example.com';

      await enter(
        instance(contentVersion: 2, serverAddress: 'new.example.com'),
      );

      expect(await ServerList.addresses(serversDat()), [
        'new.example.com',
        'my.server',
      ]);
      expect((await state())!.serverEntryAddress, 'new.example.com');
    });
  });
}

/// Appends a server to an existing list, as the game would.
Future<void> _addServer(File file, String name, String address) async {
  final root = NbtReader(await file.readAsBytes()).read();
  final servers = root.getChildrenByName('servers').single as NbtList;
  servers.add(
    NbtCompound(
      name: '',
      children: [
        NbtString(name: 'name', value: name),
        NbtString(name: 'ip', value: address),
      ],
    )..parent = servers,
  );
  await file.writeAsBytes(NbtWriter().write(root));
}
