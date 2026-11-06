import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/services/file_downloader.dart';
import 'package:bc_launcher/services/forge_installer.dart';
import 'package:bc_launcher/services/game_installer.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/shared_files.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import 'game_installer_test.dart' show FakeMojang;

List<int> zip(Map<String, String> files) {
  final archive = Archive();
  for (final MapEntry(:key, :value) in files.entries) {
    archive.addFile(ArchiveFile.string(key, value));
  }
  return ZipEncoder().encodeBytes(archive);
}

/// What the patching processor writes.
const patched = 'patched client';

/// An installer shaped like Forge's: a library inside it (`maven/`), one
/// from its Maven repository, a server processor and a client one that
/// patches the client jar into a library no version JSON lists.
List<int> installer(String id) => zip({
  'install_profile.json': jsonEncode({
    'spec': 1,
    'version': id,
    'minecraft': '1.21.1',
    'json': '/version.json',
    'data': {
      'PATCHED': {
        'client': '[net.example:forge:1.0:client]',
        'server': '[net.example:forge:1.0:server]',
      },
      'PATCHED_SHA': {
        'client': "'${FakeMojang.sha1Of(patched)}'",
        'server': "'none'",
      },
      'BINPATCH': {
        'client': '/data/client.lzma',
        'server': '/data/server.lzma',
      },
      'MAPPINGS': {
        'client': '[net.example:mappings:1.0@txt]',
        'server': '[net.example:mappings:1.0@txt]',
      },
    },
    'processors': [
      {
        'sides': ['server'],
        'jar': 'net.example:tool:1.0',
        'classpath': [],
        'args': ['--server'],
      },
      {
        'jar': 'net.example:tool:1.0',
        'classpath': ['lib:a:1.0'],
        'args': [
          '--input',
          '{MINECRAFT_JAR}',
          '--apply',
          '{BINPATCH}',
          '--output',
          '{PATCHED}',
          '--side',
          '{SIDE}',
          '--mappings',
          '[net.example:mappings:1.0@txt]',
        ],
        'outputs': {'{PATCHED}': '{PATCHED_SHA}'},
      },
    ],
    'libraries': [
      {
        'name': 'net.example:tool:1.0',
        'downloads': {
          'artifact': {
            'path': 'net/example/tool/1.0/tool-1.0.jar',
            'url': 'https://maven.example/net/example/tool/1.0/tool-1.0.jar',
          },
        },
      },
    ],
  }),
  'version.json': jsonEncode({
    'id': id,
    'inheritsFrom': '1.21.1',
    'type': 'release',
    'mainClass': 'net.example.Launcher',
    'arguments': {'game': [], 'jvm': []},
    'libraries': [
      {
        'name': 'net.example:loader:1.0',
        'downloads': {
          'artifact': {
            'path': 'net/example/loader/1.0/loader-1.0.jar',
            'url': '',
          },
        },
      },
    ],
  }),
  'data/client.lzma': 'client patch',
  'maven/net/example/loader/1.0/loader-1.0.jar': 'loader',
});

void main() {
  late Directory shared;
  late Directory folder;
  late FakeMojang mojang;
  late List<List<String>> processors;
  late int exitCode;

  setUp(() async {
    shared = await Directory.systemTemp.createTemp('forge_installer_test');
    InstanceManager.supportDirectory = () async => shared;
    folder = Directory(join(shared.path, 'example.com', 'test'));
    mojang = FakeMojang()..addVersion('1.21.1');
    mojang.binaries['https://maven.example/net/example/tool/1.0/tool-1.0.jar'] =
        zip({
          'META-INF/MANIFEST.MF':
              'Manifest-Version: 1.0\nMain-Class: net.example.Tool\n',
        });
    for (final loader in [LoaderType.forge, LoaderType.neoforge]) {
      final version = loader == LoaderType.forge ? '52.0.1' : '21.1.77';
      mojang.binaries[ForgeInstaller.installerUrl(loader, '1.21.1', version)] =
          installer(ForgeInstaller.versionId(loader, '1.21.1', version));
    }
    FileDownloader.dio.httpClientAdapter = mojang;
    GameInstaller.ensureJava = (versionData, runtimesDir, {onProgress}) async =>
        join(runtimesDir.path, 'java');

    processors = [];
    exitCode = 0;
    ForgeInstaller.runProcess = (executable, arguments) async {
      processors.add([executable, ...arguments]);
      if (exitCode == 0) {
        final output = File(arguments[arguments.indexOf('--output') + 1]);
        await output.parent.create(recursive: true);
        await output.writeAsString(patched);
      }
      return ProcessResult(1, exitCode, '', 'failed');
    };
  });
  tearDown(() => shared.delete(recursive: true));

  Manifest manifest(LoaderType loader, String? version) => Manifest(
    contentVersion: 1,
    minecraftVersion: '1.21.1',
    loaderType: loader,
    loaderVersion: version,
    managedDirs: const [],
    files: const [],
  );

  File sharedFile(String path) =>
      File(joinAll([shared.path, ...posix.split(path)]));

  test('the installers and the versions they install', () {
    expect(
      ForgeInstaller.installerUrl(LoaderType.forge, '1.20.1', '47.3.0'),
      'https://maven.minecraftforge.net/net/minecraftforge/forge/'
      '1.20.1-47.3.0/forge-1.20.1-47.3.0-installer.jar',
    );
    expect(
      ForgeInstaller.installerUrl(LoaderType.neoforge, '1.21.1', '21.1.77'),
      'https://maven.neoforged.net/releases/net/neoforged/neoforge/'
      '21.1.77/neoforge-21.1.77-installer.jar',
    );
    expect(
      GameInstaller.versionIdOf(manifest(LoaderType.forge, '47.3.0')),
      '1.21.1-forge-47.3.0',
    );
    expect(
      GameInstaller.versionIdOf(manifest(LoaderType.neoforge, '21.1.77')),
      'neoforge-21.1.77',
    );
  });

  for (final (loader, version) in [
    (LoaderType.forge, '52.0.1'),
    (LoaderType.neoforge, '21.1.77'),
  ]) {
    test('${loader.name}: runs the client processors with Java', () async {
      final id = await GameInstaller.install(manifest(loader, version), folder);

      expect(id, ForgeInstaller.versionId(loader, '1.21.1', version));
      final java = join(shared.path, 'runtime', 'java');
      final tool = join(
        shared.path,
        'libraries',
        'net',
        'example',
        'tool',
        '1.0',
        'tool-1.0.jar',
      );
      final library = sharedFile('libraries/lib/a/1.0/a-1.0.jar').path;
      final output = sharedFile(
        'libraries/net/example/forge/1.0/forge-1.0-client.jar',
      ).path;
      expect(processors, [
        [
          java,
          '-cp',
          [tool, library].join(Platform.isWindows ? ';' : ':'),
          'net.example.Tool',
          '--input',
          MinecraftLauncherCore.clientJarPath({'id': id}, folder.path),
          '--apply',
          isNot('{BINPATCH}'),
          '--output',
          output,
          '--side',
          'client',
          '--mappings',
          sharedFile('libraries/net/example/mappings/1.0/mappings-1.0.txt')
              .path,
        ],
      ]);

      // The library inside the installer, in the shared libraries.
      expect(
        await sharedFile('libraries/net/example/loader/1.0/loader-1.0.jar')
            .readAsString(),
        'loader',
      );
      final json = jsonDecode(
        await File(join(folder.path, 'versions', id, '$id.json'))
            .readAsString(),
      ) as Map;
      expect(json['id'], id);
      expect(json[ForgeInstaller.generatedKey], [
        'libraries/net/example/forge/1.0/forge-1.0-client.jar',
      ]);
      // The client jar the processors patched, where the game looks for it.
      expect(
        await File(MinecraftLauncherCore.clientJarPath({'id': id}, folder.path))
            .readAsString(),
        'client 1.21.1',
      );
    });
  }

  test('an installed loader is reused', () async {
    final forge = manifest(LoaderType.forge, '52.0.1');
    await GameInstaller.install(forge, folder);
    processors.clear();
    mojang.requests.clear();

    await GameInstaller.install(forge, folder);

    expect(processors, isEmpty);
    expect(mojang.requests, isEmpty);
  });

  test('a generated file that is gone installs it again', () async {
    final forge = manifest(LoaderType.forge, '52.0.1');
    await GameInstaller.install(forge, folder);
    await sharedFile('libraries/net/example/forge/1.0/forge-1.0-client.jar')
        .delete();
    processors.clear();

    await GameInstaller.install(forge, folder);

    expect(processors, hasLength(1));
  });

  test('a processor that fails leaves it uninstalled', () async {
    exitCode = 1;
    final forge = manifest(LoaderType.forge, '52.0.1');

    await expectLater(
      GameInstaller.install(forge, folder),
      throwsA(isA<LoaderInstallError>()),
    );
    expect(
      await ForgeInstaller.isInstalled('1.21.1-forge-52.0.1', folder, shared),
      isFalse,
    );

    exitCode = 0;
    await GameInstaller.install(forge, folder);
    expect(
      await ForgeInstaller.isInstalled('1.21.1-forge-52.0.1', folder, shared),
      isTrue,
    );
  });

  test('a loader version it does not have', () async {
    await expectLater(
      GameInstaller.install(manifest(LoaderType.forge, '1.0.0'), folder),
      throwsA(
        isA<UnknownLoaderVersionError>().having(
          (e) => e.version,
          'version',
          '1.0.0',
        ),
      ),
    );
  });

  test('cleaning the shared files keeps what the processors made', () async {
    await Directory(join(folder.path, '.bc-launcher')).create(recursive: true);
    await GameInstaller.install(manifest(LoaderType.forge, '52.0.1'), folder);

    await SharedFiles.cleanUnused(shared);

    expect(
      await sharedFile('libraries/net/example/forge/1.0/forge-1.0-client.jar')
          .exists(),
      isTrue,
    );
    expect(
      await sharedFile('libraries/net/example/loader/1.0/loader-1.0.jar')
          .exists(),
      isTrue,
    );
    // Only needed to install.
    expect(
      await sharedFile('libraries/net/example/tool/1.0/tool-1.0.jar').exists(),
      isFalse,
    );
  });
}
