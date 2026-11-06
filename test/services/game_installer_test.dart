import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/services/game_installer.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

/// Mojang's servers: the version manifest, one version JSON and its files.
class FakeMojang implements HttpClientAdapter {
  final files = <String, String>{};
  final requests = <String>[];
  bool offline = false;

  static String sha1Of(String contents) =>
      sha1.convert(utf8.encode(contents)).toString();

  void addVersion(String id) {
    files['https://libraries.example/lib/a/1.0/a-1.0.jar'] = 'library a';
    files['https://client.example/$id.jar'] = 'client $id';
    final versionJson = jsonEncode({
      'id': id,
      'type': 'release',
      'mainClass': 'net.minecraft.client.main.Main',
      'javaVersion': {'component': 'java-runtime-delta', 'majorVersion': 21},
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
  late Directory folder;
  late FakeMojang mojang;
  late List<String> javaFor;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('game_installer_test');
    mojang = FakeMojang()..addVersion('1.21.1');
    FileDownloader.dio.httpClientAdapter = mojang;
    javaFor = [];
    GameInstaller.runtimesDirectory = () async =>
        Directory(join(folder.path, 'runtime'));
    GameInstaller.ensureJava = (versionData, runtimesDir, {onProgress}) async {
      javaFor.add(versionData['javaVersion']['component']);
      onProgress?.call(1);
      return join(runtimesDir.path, 'java');
    };
  });
  tearDown(() => folder.delete(recursive: true));

  Manifest manifest({
    String version = '1.21.1',
    LoaderType loader = LoaderType.vanilla,
  }) => Manifest(
    contentVersion: 1,
    minecraftVersion: version,
    loaderType: loader,
    loaderVersion: loader == LoaderType.vanilla ? null : '1.0',
    managedDirs: const [],
    files: const [],
  );

  File local(String path) => File(joinAll([folder.path, ...posix.split(path)]));

  test('installs the version JSON, libraries, client jar and Java', () async {
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
      await local('libraries/lib/a/1.0/a-1.0.jar').readAsString(),
      'library a',
    );
    expect(
      await local('versions/1.21.1/1.21.1.jar').readAsString(),
      'client 1.21.1',
    );
    expect(javaFor, ['java-runtime-delta']);
    expect(progress.last, 1);
    expect(progress, everyElement(inInclusiveRange(0, 1)));
  });

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
    await local('libraries/lib/a/1.0/a-1.0.jar').delete();

    await GameInstaller.install(manifest(), folder);

    expect(
      await local('libraries/lib/a/1.0/a-1.0.jar').readAsString(),
      'library a',
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

  test('loaders it can not install yet', () async {
    for (final loader in [
      LoaderType.fabric,
      LoaderType.quilt,
      LoaderType.forge,
      LoaderType.neoforge,
    ]) {
      await expectLater(
        GameInstaller.install(manifest(loader: loader), folder),
        throwsA(
          isA<UnsupportedLoaderError>().having(
            (e) => e.loader,
            'loader',
            loader,
          ),
        ),
      );
    }
  });

  test('offline before anything is installed', () async {
    mojang.offline = true;

    await expectLater(
      GameInstaller.install(manifest(), folder),
      throwsA(isA<DioException>()),
    );
  });
}
