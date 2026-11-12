import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/services/sync_plan.dart';
import 'package:flutter_test/flutter_test.dart';

ManifestFile file(
  String path, {
  String sha256 = 'aaa',
  int size = 10,
  FilePolicy policy = FilePolicy.always,
}) => ManifestFile(
  path: path,
  sha256: sha256,
  size: size,
  policy: policy,
  url: 'https://example.com/blobs/$sha256',
);

Manifest manifest(
  List<ManifestFile> files, {
  List<String> managedDirs = const ['mods'],
}) => Manifest(
  contentVersion: 1,
  minecraftVersion: '1.21.1',
  loaderType: LoaderType.fabric,
  loaderVersion: '0.16.5',
  managedDirs: managedDirs,
  files: files,
);

LocalFile same(ManifestFile file) =>
    LocalFile(size: file.size, sha256: file.sha256);

void main() {
  group('downloads', () {
    test('an empty folder downloads everything', () {
      final files = [
        file('mods/a.jar', size: 100),
        file('config/a.json', size: 5),
        file('options.txt', policy: FilePolicy.once, size: 2),
      ];
      final plan = SyncPlanner.plan(manifest: manifest(files), local: {});

      expect(plan.downloads, files);
      expect(plan.downloadBytes, 107);
      expect(plan.deletions, isEmpty);
    });

    test('nothing to do when everything matches', () {
      final files = [file('mods/a.jar'), file('config/a.json')];
      final plan = SyncPlanner.plan(
        manifest: manifest(files),
        local: {for (final f in files) f.path: same(f)},
      );

      expect(plan.isEmpty, isTrue);
    });

    test('an always file that changed is downloaded again', () {
      final mod = file('mods/a.jar', sha256: 'new');
      final plan = SyncPlanner.plan(
        manifest: manifest([mod]),
        local: {'mods/a.jar': const LocalFile(size: 10, sha256: 'old')},
      );

      expect(plan.downloads, [mod]);
    });

    test('a different size is enough, without hashing', () {
      final mod = file('mods/a.jar', size: 10);
      final plan = SyncPlanner.plan(
        manifest: manifest([mod]),
        local: {'mods/a.jar': const LocalFile(size: 9)},
      );

      expect(plan.downloads, [mod]);
    });

    test('a once file is only downloaded when missing', () {
      final options = file('options.txt', policy: FilePolicy.once);
      final changed = SyncPlanner.plan(
        manifest: manifest([options]),
        local: {'options.txt': const LocalFile(size: 99, sha256: 'mine')},
      );
      final missing = SyncPlanner.plan(
        manifest: manifest([options]),
        local: {},
      );

      expect(changed.downloads, isEmpty);
      expect(missing.downloads, [options]);
    });
  });

  group('deletions', () {
    test('a managed folder keeps only the manifest files', () {
      final plan = SyncPlanner.plan(
        manifest: manifest([file('mods/a.jar')]),
        local: {
          'mods/a.jar': same(file('mods/a.jar')),
          'mods/players-own.jar': const LocalFile(size: 1),
          'mods/sub/old.jar': const LocalFile(size: 1),
        },
      );

      expect(plan.deletions, ['mods/players-own.jar', 'mods/sub/old.jar']);
    });

    test('outside managed folders, only what the launcher installed', () {
      final plan = SyncPlanner.plan(
        manifest: manifest([file('config/new.json')]),
        local: {
          'config/new.json': same(file('config/new.json')),
          'config/removed.json': const LocalFile(size: 1),
          'config/players-own.json': const LocalFile(size: 1),
        },
        previouslyInstalled: {'config/removed.json', 'config/new.json'},
      );

      expect(plan.deletions, ['config/removed.json']);
    });

    test('never deletes what the player keeps', () {
      final plan = SyncPlanner.plan(
        manifest: manifest([], managedDirs: ['mods', 'saves']),
        local: {
          'saves/world/level.dat': const LocalFile(size: 1),
          'screenshots/a.png': const LocalFile(size: 1),
          'options.txt': const LocalFile(size: 1),
          'servers.dat': const LocalFile(size: 1),
          '.bc-launcher/state.json': const LocalFile(size: 1),
        },
        previouslyInstalled: {
          'saves/world/level.dat',
          'screenshots/a.png',
          'options.txt',
          'servers.dat',
          '.bc-launcher/state.json',
        },
      );

      expect(plan.deletions, isEmpty);
    });

    test('a file the manifest has in another case is never deleted', () {
      final plan = SyncPlanner.plan(
        manifest: manifest([file('mods/Sodium.jar')]),
        local: {'mods/sodium.jar': const LocalFile(size: 10, sha256: 'aaa')},
      );

      expect(plan.deletions, isEmpty);
    });

    test('managed folders match ignoring case', () {
      final plan = SyncPlanner.plan(
        manifest: manifest([], managedDirs: ['mods']),
        local: {'Mods/extra.jar': const LocalFile(size: 1)},
      );

      expect(plan.deletions, ['Mods/extra.jar']);
    });

    test('a folder named like a managed one is not managed', () {
      final plan = SyncPlanner.plan(
        manifest: manifest([], managedDirs: ['mods']),
        local: {'modsextra/a.jar': const LocalFile(size: 1)},
      );

      expect(plan.deletions, isEmpty);
    });
  });

  group('installed', () {
    test('lists only the always files', () {
      final plan = SyncPlanner.plan(
        manifest: manifest([
          file('mods/a.jar'),
          file('options.txt', policy: FilePolicy.once),
        ]),
        local: {},
      );

      expect(plan.installed, {'mods/a.jar'});
    });

    test('a once file removed from the manifest stays', () {
      final plan = SyncPlanner.plan(
        manifest: manifest([]),
        local: {'config/once.json': const LocalFile(size: 1)},
        previouslyInstalled: const {},
      );

      expect(plan.deletions, isEmpty);
    });
  });

  group('unsafe paths', () {
    for (final path in [
      '../outside.jar',
      'mods/../../outside.jar',
      '/etc/passwd',
      'C:/Windows/a.dll',
      'mods\\a.jar',
      'mods//a.jar',
      './a.jar',
      'mods/',
      '',
      'versions/1.21.1/1.21.1.jar',
      'libraries/a.jar',
      'Assets/a.png',
      '.bc-launcher/state.json',
    ]) {
      test('refuses "$path"', () {
        expect(
          () => SyncPlanner.plan(manifest: manifest([file(path)]), local: {}),
          throwsA(isA<UnsafePathError>()),
        );
      });
    }

    test('refuses an unsafe managed folder', () {
      expect(
        () => SyncPlanner.plan(
          manifest: manifest([], managedDirs: ['../mods']),
          local: {},
        ),
        throwsA(isA<UnsafePathError>()),
      );
    });

    test('accepts nested and dotted names', () {
      SyncPlanner.checkPath('config/sub/a.b.json');
      SyncPlanner.checkPath('.minecraft-like/file');
      SyncPlanner.checkPath('resourcepacks/pack v2.zip');
    });
  });
}
