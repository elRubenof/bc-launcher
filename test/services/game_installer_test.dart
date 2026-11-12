import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/services/asset_manager.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/services/game_installer.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/java_manager.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

/// Mojang's servers: the version manifest, one version JSON and its files.
class FakeMojang implements HttpClientAdapter {
  final files = <String, String>{};
  final binaries = <String, List<int>>{};
  final requests = <String>[];
  bool offline = false;

  /// Asset name → contents, in the version's asset index.
  Map<String, String> assets = {
    'minecraft/sounds/a.ogg': 'sound a',
    'minecraft/textures/b.png': 'texture b',
    // Same contents as another asset: one object for both.
    'minecraft/sounds/copy.ogg': 'sound a',
  };

  /// Extra fields of the asset index (`virtual`, `map_to_resources`).
  Map<String, Object> assetIndexFlags = {};

  static String sha1Of(String contents) =>
      sha1.convert(utf8.encode(contents)).toString();

  static int sizeOf(String contents) => utf8.encode(contents).length;

  void addVersion(String id) {
    for (final contents in assets.values) {
      final hash = sha1Of(contents);
      files['${AssetManager.resourcesUrl}/${hash.substring(0, 2)}/$hash'] =
          contents;
    }
    final assetIndex = jsonEncode({
      ...assetIndexFlags,
      'objects': {
        for (final MapEntry(key: name, value: contents) in assets.entries)
          name: {'hash': sha1Of(contents), 'size': sizeOf(contents)},
      },
    });
    files['https://piston-meta.example/v1/indexes/17.json'] = assetIndex;

    files['https://libraries.example/lib/a/1.0/a-1.0.jar'] = 'library a';
    files['https://client.example/$id.jar'] = 'client $id';
    final versionJson = jsonEncode({
      'id': id,
      'type': 'release',
      'mainClass': 'net.minecraft.client.main.Main',
      'javaVersion': {'component': 'java-runtime-delta', 'majorVersion': 21},
      'assets': '17',
      'assetIndex': {
        'id': '17',
        'url': 'https://piston-meta.example/v1/indexes/17.json',
        'sha1': sha1Of(assetIndex),
        'size': sizeOf(assetIndex),
      },
      'downloads': {
        'client': {
          'url': 'https://client.example/$id.jar',
          'sha1': sha1Of('client $id'),
          'size': utf8.encode('client $id').length,
        },
      },
      'libraries': [
        {
          'name': 'lib:a:1.0',
          'downloads': {
            'artifact': {
              'path': 'lib/a/1.0/a-1.0.jar',
              'url': 'https://libraries.example/lib/a/1.0/a-1.0.jar',
              'sha1': sha1Of('library a'),
              'size': utf8.encode('library a').length,
            },
          },
        },
      ],
    });
    files['https://piston-meta.example/v1/$id.json'] = versionJson;
    files[GameInstaller.versionManifestUrl] = jsonEncode({
      'versions': [
        {
          'id': id,
          'type': 'release',
          'url': 'https://piston-meta.example/v1/$id.json',
          'sha1': sha1Of(versionJson),
        },
      ],
    });
  }

  /// The profile of [loader] [version] for Minecraft [minecraft], with one
  /// library of its own from its Maven repository.
  void addLoader(LoaderType loader, String minecraft, String version) {
    final name = '${loader.name}-loader';
    final jar = '$name $version';
    files['https://maven.example/org/$name/$version/$name-$version.jar'] = jar;
    files['${GameInstaller.loaderMeta[loader]}/$minecraft/$version/profile/json'] =
        jsonEncode({
          'id': '$name-$version-$minecraft',
          'inheritsFrom': minecraft,
          'releaseTime': DateTime.now().toIso8601String(),
          'mainClass': 'org.$name.Knot',
          'arguments': {'game': [], 'jvm': []},
          'libraries': [
            {
              'name': 'org:$name:$version',
              'url': 'https://maven.example/',
              // Fabric gives its hash and size; Quilt doesn't.
              if (loader == LoaderType.fabric) ...{
                'sha1': sha1Of(jar),
                'size': sizeOf(jar),
              },
            },
          ],
        });
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    requests.add(url);
    if (offline) {
      throw DioException.connectionError(
        requestOptions: options,
        reason: 'offline',
      );
    }

    final bytes = binaries[url];
    if (bytes != null) return ResponseBody.fromBytes(bytes, 200);

    final body = files[url];
    if (body == null) return ResponseBody.fromString('', 404);
    return ResponseBody.fromString(
      body,
      200,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Directory shared;
  late Directory folder;
  late FakeMojang mojang;
  late List<String> javaIn;

  setUp(() async {
    shared = await Directory.systemTemp.createTemp('game_installer_test');
    InstanceManager.supportDirectory = () async => shared;
    folder = Directory(join(shared.path, 'example.com', 'test'));
    mojang = FakeMojang()..addVersion('1.21.1');
    FileDownloader.dio.httpClientAdapter = mojang;
    javaIn = [];
    GameInstaller.planJava = (versionData, runtimesDir) async {
      javaIn.add(
        '${versionData['javaVersion']['component']} in ${runtimesDir.path}',
      );
      return JavaPlan.ready(join(runtimesDir.path, 'java'));
    };
  });
  tearDown(() => shared.delete(recursive: true));

  Manifest manifest({
    String version = '1.21.1',
    LoaderType loader = LoaderType.vanilla,
  }) => Manifest(
    contentVersion: 1,
    minecraftVersion: version,
    loaderType: loader,
    loaderVersion: loader == LoaderType.vanilla ? null : '0.16.5',
    managedDirs: const [],
    files: const [],
  );

  File local(String path) => File(joinAll([folder.path, ...posix.split(path)]));
  File sharedFile(String path) =>
      File(joinAll([shared.path, ...posix.split(path)]));
  File object(String contents) {
    final hash = FakeMojang.sha1Of(contents);
    return sharedFile('assets/objects/${hash.substring(0, 2)}/$hash');
  }

  test(
    'installs the version JSON, libraries, client jar, assets and Java',
    () async {
      final progress = <double>[];

      final id = await GameInstaller.install(
        manifest(),
        folder,
        onProgress: progress.add,
      );

      expect(id, '1.21.1');
      expect(
        jsonDecode(
          await local('versions/1.21.1/1.21.1.json').readAsString(),
        )['id'],
        '1.21.1',
      );
      expect(
        await local('versions/1.21.1/1.21.1.jar').readAsString(),
        'client 1.21.1',
      );
      // Shared by every instance.
      expect(
        await sharedFile('libraries/lib/a/1.0/a-1.0.jar').readAsString(),
        'library a',
      );
      expect(await sharedFile('assets/indexes/17.json').exists(), isTrue);
      expect(await object('sound a').readAsString(), 'sound a');
      expect(await object('texture b').readAsString(), 'texture b');
      expect(await local('libraries').exists(), isFalse);
      expect(javaIn, ['java-runtime-delta in ${join(shared.path, 'runtime')}']);
      expect(progress.last, 1);
      expect(progress, everyElement(inInclusiveRange(0, 1)));
    },
  );

  test('an installed instance needs no network', () async {
    await GameInstaller.install(manifest(), folder);
    mojang
      ..requests.clear()
      ..offline = true;

    expect(await GameInstaller.install(manifest(), folder), '1.21.1');
    expect(mojang.requests, isEmpty);
  });

  test('a deleted library is downloaded again', () async {
    await GameInstaller.install(manifest(), folder);
    await sharedFile('libraries/lib/a/1.0/a-1.0.jar').delete();
    await object('texture b').delete();

    await GameInstaller.install(manifest(), folder);

    expect(
      await sharedFile('libraries/lib/a/1.0/a-1.0.jar').readAsString(),
      'library a',
    );
    expect(await object('texture b').readAsString(), 'texture b');
  });

  test('a second instance reuses the shared files', () async {
    await GameInstaller.install(manifest(), folder);
    mojang.requests.clear();

    await GameInstaller.install(
      manifest(),
      Directory(join(shared.path, 'example.com', 'other')),
    );

    // Only its own version JSON and client jar.
    expect(mojang.requests, [
      GameInstaller.versionManifestUrl,
      'https://piston-meta.example/v1/1.21.1.json',
      'https://client.example/1.21.1.jar',
    ]);
  });

  test('the bar follows only what is missing', () async {
    await GameInstaller.install(manifest(), folder);
    final progress = <double>[];

    await GameInstaller.install(
      manifest(),
      Directory(join(shared.path, 'example.com', 'other')),
      onProgress: progress.add,
    );

    // Only the client jar is missing: it fills the whole bar, with no jump
    // for libraries, assets and Java that are already there.
    expect(progress.first, 0);
    expect(progress.last, 1);
    expect(progress.every((p) => p == 0 || p == 1), isTrue);
  });

  test('old versions get their assets by name', () async {
    mojang
      ..assetIndexFlags = {'virtual': true}
      ..addVersion('1.21.1');

    await GameInstaller.install(manifest(), folder);

    expect(
      await sharedFile('assets/virtual/legacy/minecraft/textures/b.png')
          .readAsString(),
      'texture b',
    );
  });

  test('the oldest versions get them in the instance', () async {
    mojang
      ..assetIndexFlags = {'map_to_resources': true}
      ..addVersion('1.21.1');

    await GameInstaller.install(manifest(), folder);

    expect(
      await local('resources/minecraft/sounds/copy.ogg').readAsString(),
      'sound a',
    );
  });

  test('a broken version JSON is downloaded again', () async {
    await local('versions/1.21.1/1.21.1.json').create(recursive: true);
    await local('versions/1.21.1/1.21.1.json').writeAsString('{not json');

    await GameInstaller.install(manifest(), folder);

    expect(
      jsonDecode(
        await local('versions/1.21.1/1.21.1.json').readAsString(),
      )['id'],
      '1.21.1',
    );
  });

  test('a version JSON that does not match its sha1 is rejected', () async {
    mojang.files['https://piston-meta.example/v1/1.21.1.json'] = '{}';

    await expectLater(
      GameInstaller.install(manifest(), folder),
      throwsA(isA<FileSystemException>()),
    );
    expect(await local('versions/1.21.1/1.21.1.json').exists(), isFalse);
  });

  test('an unknown Minecraft version', () async {
    await expectLater(
      GameInstaller.install(manifest(version: '0.0.1'), folder),
      throwsA(
        isA<UnknownMinecraftVersionError>().having(
          (e) => e.version,
          'version',
          '0.0.1',
        ),
      ),
    );
  });

  for (final loader in [LoaderType.fabric, LoaderType.quilt]) {
    final id = '${loader.name}-loader-0.16.5-1.21.1';

    test('${loader.name}: its profile on top of Minecraft', () async {
      mojang.addLoader(loader, '1.21.1', '0.16.5');

      expect(await GameInstaller.install(manifest(loader: loader), folder), id);

      final profile = jsonDecode(
        await local('versions/$id/$id.json').readAsString(),
      );
      expect(profile['inheritsFrom'], '1.21.1');
      expect(await local('versions/1.21.1/1.21.1.json').exists(), isTrue);
      // The loader's library and Minecraft's, in the shared folder.
      expect(
        await sharedFile(
          'libraries/org/${loader.name}-loader/0.16.5/'
          '${loader.name}-loader-0.16.5.jar',
        ).readAsString(),
        '${loader.name}-loader 0.16.5',
      );
      expect(
        await sharedFile('libraries/lib/a/1.0/a-1.0.jar').exists(),
        isTrue,
      );
      // The client jar of the version that is launched.
      expect(
        await local('versions/$id/$id.jar').readAsString(),
        'client 1.21.1',
      );
    });

    test('${loader.name}: its profile is fetched only once', () async {
      mojang.addLoader(loader, '1.21.1', '0.16.5');
      await GameInstaller.install(manifest(loader: loader), folder);
      mojang
        ..requests.clear()
        ..offline = true;

      expect(await GameInstaller.install(manifest(loader: loader), folder), id);
      expect(mojang.requests, isEmpty);
    });

    test('${loader.name}: a loader version it does not have', () async {
      await expectLater(
        GameInstaller.install(manifest(loader: loader), folder),
        throwsA(
          isA<UnknownLoaderVersionError>()
              .having((e) => e.loader, 'loader', loader)
              .having((e) => e.version, 'version', '0.16.5'),
        ),
      );
    });
  }

  test('the version to launch', () {
    expect(GameInstaller.versionIdOf(manifest()), '1.21.1');
    expect(
      GameInstaller.versionIdOf(manifest(loader: LoaderType.quilt)),
      'quilt-loader-0.16.5-1.21.1',
    );
  });

  test('offline before anything is installed', () async {
    mojang.offline = true;

    await expectLater(
      GameInstaller.install(manifest(), folder),
      throwsA(isA<DioException>()),
    );
  });
}
