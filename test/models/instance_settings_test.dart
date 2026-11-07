import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/instance_settings.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  // 6144 MB recommended, and none.
  final [recommends, recommendsNone] = [
    for (final json in fixture('instances')['instances'])
      Instance.fromJson(json),
  ];

  test('what isn\'t changed takes its default', () {
    const settings = InstanceSettings.empty;
    expect(settings.width, Constants.defaultGameWidth);
    expect(settings.height, Constants.defaultGameHeight);
    expect(settings.isFullscreen, Constants.defaultFullscreen);
    expect(settings.connects, Constants.defaultAutoConnect);
    expect(settings.ram(recommendsNone, 64), Constants.defaultAllocatedRAM);
  });

  test(
    'the RAM is the recommended one, rounded up, until the player picks',
    () {
      expect(InstanceSettings.empty.ram(recommends, 64), 6);
      expect(const InstanceSettings(ramGb: 10).ram(recommends, 64), 10);
    },
  );

  test('the RAM never passes the computer\'s', () {
    expect(InstanceSettings.empty.ram(recommends, 4), 4);
    expect(const InstanceSettings(ramGb: 32).ram(recommends, 16), 16);
    expect(const InstanceSettings(ramGb: 0).ram(recommends, 16), 1);
  });

  test('saves only what was changed', () {
    const settings = InstanceSettings(ramGb: 4, fullscreen: false);
    expect(settings.toJson(), {'ramGb': 4, 'fullscreen': false});

    final read = InstanceSettings.fromJson(settings.toJson());
    expect(read.ramGb, 4);
    expect(read.fullscreen, isFalse);
    expect(read.gameWidth, isNull);
    expect(read.autoConnect, isNull);
  });

  test('copyWith keeps the rest', () {
    final settings = const InstanceSettings(ramGb: 4)
        .copyWith(autoConnect: false);
    expect(settings.ramGb, 4);
    expect(settings.autoConnect, isFalse);
  });
}
