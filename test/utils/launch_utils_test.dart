import 'dart:convert';
import 'dart:io';

import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_core.dart';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

/// This machine's name in version JSON rules, and one that isn't.
final thisOs = Platform.isWindows
    ? 'windows'
    : Platform.isMacOS
    ? 'osx'
    : 'linux';
final otherOs = thisOs == 'linux' ? 'windows' : 'linux';

void main() {
  group('rules', () {
    bool allowed(List rules, [Map options = const {}]) =>
        MinecraftLauncherHelper.parseRuleList(rules, options);

    test('allow without conditions', () {
      expect(
        allowed([
          {'action': 'allow'},
        ]),
        isTrue,
      );
    });

    test('allow only on an OS', () {
      expect(
        allowed([
          {
            'action': 'allow',
            'os': {'name': thisOs},
          },
        ]),
        isTrue,
      );
      expect(
        allowed([
          {
            'action': 'allow',
            'os': {'name': otherOs},
          },
        ]),
        isFalse,
      );
    });

    test('disallow on an OS', () {
      expect(
        allowed([
          {'action': 'allow'},
          {
            'action': 'disallow',
            'os': {'name': thisOs},
          },
        ]),
        isFalse,
      );
      expect(
        allowed([
          {'action': 'allow'},
          {
            'action': 'disallow',
            'os': {'name': otherOs},
          },
        ]),
        isTrue,
      );
    });

    test('features need their option', () {
      final rule = [
        {
          'action': 'allow',
          'features': {'has_custom_resolution': true},
        },
      ];
      expect(allowed(rule), isFalse);
      expect(allowed(rule, {'customResolution': true}), isTrue);

      final quickPlay = [
        {
          'action': 'allow',
          'features': {'is_quick_play_multiplayer': true},
        },
      ];
      expect(allowed(quickPlay), isFalse);
      expect(
        allowed(quickPlay, {'quickPlayMultiplayer': 'play.example.com'}),
        isTrue,
      );
    });

    test('an empty list allows', () {
      expect(allowed([]), isTrue);
    });
  });

  group('libraries', () {
    final root = join('mc');

    test('path of a Maven name', () {
      expect(
        MinecraftLauncherHelper.getLibraryPath('org.lwjgl:lwjgl:3.3.3', root),
        join(
          root,
          'libraries',
          'org',
          'lwjgl',
          'lwjgl',
          '3.3.3',
          'lwjgl-3.3.3.jar',
        ),
      );
    });

    test('path with a classifier', () {
      expect(
        MinecraftLauncherHelper.getLibraryPath(
          'org.lwjgl:lwjgl:3.3.3:natives-macos-arm64',
          root,
        ),
        join(
          root,
          'libraries',
          'org',
          'lwjgl',
          'lwjgl',
          '3.3.3',
          'lwjgl-3.3.3-natives-macos-arm64.jar',
        ),
      );
    });

    test('path with another extension', () {
      expect(
        MinecraftLauncherHelper.getLibraryPath(
          'com.example:pack:1.0@zip',
          root,
        ),
        join(
          root,
          'libraries',
          'com',
          'example',
          'pack',
          '1.0',
          'pack-1.0.zip',
        ),
      );
    });

    test('natives of this OS', () {
      final natives = MinecraftLauncherHelper.getNatives({
        'natives': {
          'windows': 'natives-windows-\${arch}',
          'osx': 'natives-osx',
          'linux': 'natives-linux',
        },
      });
      expect(
        natives,
        startsWith('natives-${thisOs == 'osx' ? 'osx' : thisOs}'),
      );
      expect(natives, isNot(contains('\${arch}')));
      expect(MinecraftLauncherHelper.getNatives({'name': 'a:b:1'}), '');
    });

    test('classpath separator of this OS', () {
      expect(
        MinecraftLauncherHelper.getClasspathSeparator(),
        Platform.isWindows ? ';' : ':',
      );
    });

    test(
      'classpath skips libraries for other OSes and ends with the client jar',
      () {
        final classpath = MinecraftLauncherCore.getLibraries({
          'id': '1.21.1',
          'libraries': [
            {'name': 'com.google.code.gson:gson:2.10'},
            {
              'name': 'org.example:other-os:1.0',
              'rules': [
                {
                  'action': 'allow',
                  'os': {'name': otherOs},
                },
              ],
            },
          ],
        }, root);
        final entries = classpath.split(
          MinecraftLauncherHelper.getClasspathSeparator(),
        );

        expect(entries, [
          MinecraftLauncherHelper.getLibraryPath(
            'com.google.code.gson:gson:2.10',
            root,
          ),
          join(root, 'versions', '1.21.1', '1.21.1.jar'),
        ]);
      },
    );
  });

  group('versions', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('launch_utils_test');
    });
    tearDown(() => root.delete(recursive: true));

    Future<void> writeVersion(String id, Map json) async {
      final file = File(join(root.path, 'versions', id, '$id.json'));
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(json));
    }

    final vanilla = {
      'id': '1.21.1',
      'type': 'release',
      'mainClass': 'net.minecraft.client.main.Main',
      'assets': '17',
      'libraries': [
        {'name': 'com.google.code.gson:gson:2.10'},
        {'name': 'org.lwjgl:lwjgl:3.3.3'},
      ],
      'arguments': {
        'game': ['--username', '\${auth_player_name}'],
        'jvm': ['-cp', '\${classpath}'],
      },
    };
    final fabric = {
      'id': 'fabric-loader-0.16.5-1.21.1',
      'inheritsFrom': '1.21.1',
      'mainClass': 'net.fabricmc.loader.impl.launch.knot.KnotClient',
      'libraries': [
        {'name': 'net.fabricmc:fabric-loader:0.16.5'},
        {'name': 'com.google.code.gson:gson:2.11'},
      ],
      'arguments': {
        'game': ['--fabric'],
      },
    };

    test('a version that is not installed is an error', () {
      expect(
        MinecraftLauncherCore.loadVersionData('1.21.1', root.path),
        throwsException,
      );
    });

    test('inheritsFrom merges the loader onto vanilla', () async {
      await writeVersion('1.21.1', vanilla);
      await writeVersion('fabric-loader-0.16.5-1.21.1', fabric);

      final data = await MinecraftLauncherCore.loadVersionData(
        'fabric-loader-0.16.5-1.21.1',
        root.path,
      );

      expect(data['id'], 'fabric-loader-0.16.5-1.21.1');
      expect(data['mainClass'], fabric['mainClass']);
      expect(data['assets'], '17');
      // The loader's libraries win; vanilla only adds the ones it lacks.
      expect(
        [for (final lib in data['libraries']) lib['name']],
        [
          'net.fabricmc:fabric-loader:0.16.5',
          'com.google.code.gson:gson:2.11',
          'org.lwjgl:lwjgl:3.3.3',
        ],
      );
      expect(data['arguments']['game'], [
        '--username',
        '\${auth_player_name}',
        '--fabric',
      ]);
      expect(data['arguments']['jvm'], ['-cp', '\${classpath}']);
    });

    test('the command line of a modern version', () async {
      await writeVersion('1.21.1', vanilla);
      final data = await MinecraftLauncherCore.loadVersionData(
        '1.21.1',
        root.path,
      );

      final command = await MinecraftLauncherCore.getMinecraftCommand(
        data,
        root.path,
        {
          'executablePath': 'java',
          'jvmArguments': ['-Xmx4G'],
          'username': 'Nyxar',
        },
      );

      expect(command.first, 'java');
      expect(command[1], '-Xmx4G');
      expect(
        command,
        containsAllInOrder(['-cp', isNot(contains('\${classpath}'))]),
      );
      expect(
        command,
        containsAllInOrder([data['mainClass'], '--username', 'Nyxar']),
      );
    });

    test('libraries and assets can come from a shared folder', () async {
      await writeVersion('1.21.1', {
        ...vanilla,
        'arguments': {
          'game': ['--assetsDir', '\${assets_root}'],
          'jvm': ['-cp', '\${classpath}'],
        },
      });
      final data = await MinecraftLauncherCore.loadVersionData(
        '1.21.1',
        root.path,
      );
      final shared = join(root.path, 'shared');

      final command = await MinecraftLauncherCore.getMinecraftCommand(
        data,
        root.path,
        {'sharedRoot': shared},
      );

      final classpath = command[command.indexOf('-cp') + 1].split(
        MinecraftLauncherHelper.getClasspathSeparator(),
      );
      expect(classpath, [
        MinecraftLauncherHelper.getLibraryPath(
          'com.google.code.gson:gson:2.10',
          shared,
        ),
        MinecraftLauncherHelper.getLibraryPath('org.lwjgl:lwjgl:3.3.3', shared),
        // The client jar stays in the instance.
        join(root.path, 'versions', '1.21.1', '1.21.1.jar'),
      ]);
      expect(
        command,
        containsAllInOrder(['--assetsDir', join(shared, 'assets')]),
      );
    });

    test('fullscreen, or the resolution in a window', () async {
      final data = {
        ...vanilla,
        'arguments': {
          'game': [
            '--username',
            '\${auth_player_name}',
            {
              'rules': [
                {
                  'action': 'allow',
                  'features': {'has_custom_resolution': true},
                },
              ],
              'value': [
                '--width',
                '\${resolution_width}',
                '--height',
                '\${resolution_height}',
              ],
            },
          ],
          'jvm': ['-cp', '\${classpath}'],
        },
      };

      final fullscreen = await MinecraftLauncherCore.getMinecraftCommand(
        data,
        root.path,
        {'fullscreen': true},
      );
      expect(fullscreen, contains('--fullscreen'));
      expect(fullscreen, isNot(contains('--width')));

      final window = await MinecraftLauncherCore.getMinecraftCommand(
        data,
        root.path,
        {
          'customResolution': true,
          'resolutionWidth': '1280',
          'resolutionHeight': '720',
        },
      );
      expect(window, isNot(contains('--fullscreen')));
      expect(
        window,
        containsAllInOrder(['--width', '1280', '--height', '720']),
      );
    });

    test('Quick Play joins the server where the version has it', () {
      final quickPlay = {
        ...vanilla,
        'arguments': {
          'game': [
            {
              'rules': [
                {
                  'action': 'allow',
                  'features': {'is_quick_play_multiplayer': true},
                },
              ],
              'value': ['--quickPlayMultiplayer', '\${quickPlayMultiplayer}'],
            },
          ],
        },
      };

      expect(
        MinecraftLauncherCore.serverOptions(quickPlay, 'play.example.com'),
        {'quickPlayMultiplayer': 'play.example.com'},
      );
      expect(
        MinecraftLauncherCore.serverOptions(vanilla, 'play.example.com:25566'),
        {'server': 'play.example.com', 'port': '25566'},
      );
      expect(
        MinecraftLauncherCore.serverOptions({
          'minecraftArguments': '--username \${auth_player_name}',
        }, 'play.example.com'),
        {'server': 'play.example.com'},
      );
    });

    test('server addresses split into host and port', () {
      expect(MinecraftLauncherCore.splitAddress('example.com'), (
        'example.com',
        null,
      ));
      expect(MinecraftLauncherCore.splitAddress('example.com:25566'), (
        'example.com',
        '25566',
      ));
      expect(MinecraftLauncherCore.splitAddress('[2001:db8::1]:25566'), (
        '2001:db8::1',
        '25566',
      ));
      expect(MinecraftLauncherCore.splitAddress('2001:db8::1'), (
        '2001:db8::1',
        null,
      ));
    });

    test('the command line of a legacy version with a server', () async {
      final command = await MinecraftLauncherCore.getMinecraftCommand(
        {
          'id': '1.12.2',
          'type': 'release',
          'mainClass': 'net.minecraft.client.main.Main',
          'libraries': [],
          'minecraftArguments':
              '--username \${auth_player_name} --version \${version_name}',
        },
        root.path,
        {'username': 'Nyxar', 'server': 'play.example.com', 'port': '25565'},
      );

      expect(
        command,
        containsAllInOrder(['-cp', 'net.minecraft.client.main.Main']),
      );
      expect(
        command.sublist(command.indexOf('net.minecraft.client.main.Main') + 1),
        [
          '--username',
          'Nyxar',
          '--version',
          '1.12.2',
          '--server',
          'play.example.com',
          '--port',
          '25565',
        ],
      );
    });
  });
}
