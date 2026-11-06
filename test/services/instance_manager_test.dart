import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import '../fixtures.dart';

void main() {
  late Directory support;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('instance_manager_test');
    InstanceManager.supportDirectory = () async => support;
  });
  tearDown(() => support.delete(recursive: true));

  final instance = Instance.fromJson(fixture('instances')['instances'][0]);

  InstanceState stateOf(Instance instance, {bool complete = true}) =>
      InstanceState(
        contentVersion: instance.contentVersion,
        minecraftVersion: instance.minecraftVersion,
        loaderType: instance.loaderType,
        loaderVersion: instance.loaderVersion,
        complete: complete,
      );

  group('folders', () {
    test('<support>/<organization>/<instance>/.bc-launcher', () async {
      expect(
        (await InstanceManager.launcherFolder('a.com', 'spartaland-3')).path,
        join(support.path, 'a.com', 'spartaland-3', '.bc-launcher'),
      );
    });

    test('deleting an organization deletes all its instances', () async {
      final a = await InstanceManager.instanceFolder('a.com', 'one');
      final b = await InstanceManager.instanceFolder('b.com', 'two');
      await File(join(a.path, 'saves', 'world.dat')).create(recursive: true);
      await b.create(recursive: true);

      await InstanceManager.deleteOrganization('a.com');

      expect(await Directory(join(support.path, 'a.com')).exists(), isFalse);
      expect(await b.exists(), isTrue);
    });

    test('deleting an organization without folder is fine', () async {
      await InstanceManager.deleteOrganization('missing.com');
    });
  });

  group('state', () {
    test('nothing installed reads as null', () async {
      expect(await InstanceManager.readState('a.com', 'x'), isNull);
    });

    test('is written and read back', () async {
      const state = InstanceState(
        contentVersion: 3,
        minecraftVersion: '1.21.1',
        loaderType: LoaderType.fabric,
        loaderVersion: '0.16.5',
        complete: true,
        serverEntryAddress: 'play.example.com',
      );
      await InstanceManager.writeState('a.com', 'x', state);

      final read = await InstanceManager.readState('a.com', 'x');
      expect(read!.toJson(), state.toJson());
      expect(
        await File(
          join(support.path, 'a.com', 'x', '.bc-launcher', 'state.json'),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          join(support.path, 'a.com', 'x', '.bc-launcher', 'state.json.part'),
        ).exists(),
        isFalse,
      );
    });

    test('a broken state file reads as null', () async {
      final folder = await InstanceManager.launcherFolder('a.com', 'x');
      await File(join(folder.path, 'state.json'))
          .create(recursive: true)
          .then((file) => file.writeAsString('{oops'));

      expect(await InstanceManager.readState('a.com', 'x'), isNull);
    });
  });

  group('status', () {
    test('nothing installed', () {
      expect(
        InstanceManager.statusOf(instance, null),
        InstallStatus.notInstalled,
      );
    });

    test('an unfinished first installation is not installed', () {
      expect(
        InstanceManager.statusOf(instance, stateOf(instance, complete: false)),
        InstallStatus.notInstalled,
      );
    });

    test('the same versions are up to date', () {
      expect(
        InstanceManager.statusOf(instance, stateOf(instance)),
        InstallStatus.upToDate,
      );
    });

    test('a change in content, Minecraft or loader is an update', () {
      final installed = stateOf(instance).toJson();
      for (final change in [
        {'contentVersion': 2},
        {'minecraftVersion': '1.21'},
        {'loaderType': 'quilt'},
        {'loaderVersion': '0.16.4'},
      ]) {
        final state = InstanceState.fromJson({...installed, ...change});
        expect(
          InstanceManager.statusOf(instance, state),
          InstallStatus.updateAvailable,
          reason: '$change',
        );
      }
    });

    test('reads the state from disk', () async {
      expect(
        await InstanceManager.status('a.com', instance),
        InstallStatus.notInstalled,
      );
      await InstanceManager.writeState('a.com', instance.id, stateOf(instance));
      expect(
        await InstanceManager.status('a.com', instance),
        InstallStatus.upToDate,
      );
    });
  });
}
