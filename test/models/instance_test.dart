import 'dart:convert';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/instance_colors.dart';
import 'package:bc_launcher/models/web_tab.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  List<Instance> instances() => [
    for (final json in fixture('instances')['instances'])
      Instance.fromJson(json),
  ];

  test('reads an instance with everything', () {
    final instance = instances().first;

    expect(instance.id, 'spartaland-3');
    expect(instance.name, 'Spartaland 3');
    expect(instance.description, 'Tercera temporada');
    expect(instance.iconUrl, isNotNull);
    expect(instance.tabs, hasLength(2));
    expect(instance.discordUrl, 'https://discord.gg/example');
    expect(instance.webUrl, isNull);
    expect(instance.minecraftVersion, '1.21.1');
    expect(instance.loaderType, LoaderType.fabric);
    expect(instance.loaderVersion, '0.16.5');
    expect(instance.serverAddress, 'play.example.com');
    expect(instance.recommendedRamMb, 6144);
    expect(instance.contentVersion, 3);
  });

  test('reads an instance with the optional fields empty', () {
    final instance = instances().last;

    expect(instance.iconUrl, isNull);
    expect(instance.tabs, isEmpty);
    expect(instance.loaderType, LoaderType.vanilla);
    expect(instance.loaderVersion, isNull);
    expect(instance.serverAddress, isNull);
    expect(instance.recommendedRamMb, isNull);
  });

  test('saves and reads back the same instance', () {
    for (final instance in instances()) {
      final saved = jsonDecode(jsonEncode(instance.toJson()));
      expect(Instance.fromJson(saved).toJson(), instance.toJson());
    }
  });

  test('an unknown loader is an error', () {
    final json = fixture('instances')['instances'][0]
      ..['loader'] = {'type': 'liteloader', 'version': '1'};
    expect(() => Instance.fromJson(json), throwsArgumentError);
  });

  group('colors', () {
    test('reads #RRGGBB in any case as opaque colors', () {
      final colors = instances().first.colors;

      expect(colors.primary, const Color(0xFFA83CBB));
      expect(colors.primaryDark, const Color(0xFF8F349D));
      expect(colors.background, const Color(0xFF23162A));
      expect(colors.text, const Color(0xFFFFFFFF));
    });

    test('writes them back as upper-case #RRGGBB', () {
      final json = InstanceColors.fromJson({
        'primary': '#a83cbb',
        'primaryDark': '#000000',
        'background': '#0a0b0c',
        'text': '#FFFFFF',
      }).toJson();

      expect(json, {
        'primary': '#A83CBB',
        'primaryDark': '#000000',
        'background': '#0A0B0C',
        'text': '#FFFFFF',
      });
    });
  });

  group('web tabs', () {
    test('reads the label, url, icon and where it opens', () {
      final [map, ranking] = instances().first.tabs;

      expect(map.label, 'Mapa');
      expect(map.icon, WebTabIcon.map);
      expect(map.openIn, WebTabOpenIn.launcher);
      expect(ranking.icon, WebTabIcon.trophy);
      expect(ranking.openIn, WebTabOpenIn.browser);
    });

    test('resolveUrl puts in the player, encoded', () {
      final map = instances().first.tabs.first;
      final url = map.resolveUrl(uuid: 'abc-123', name: 'Nyx ar&b');

      expect(url.queryParameters, {'player': 'Nyx ar&b', 'id': 'abc-123'});
    });

    test('resolveUrl leaves a url without placeholders as it is', () {
      final ranking = instances().first.tabs.last;

      expect(
        ranking.resolveUrl(uuid: 'u', name: 'n').toString(),
        'https://example.com/ranking',
      );
    });

    test('an unknown icon is an error', () {
      expect(
        () => WebTab.fromJson({
          'label': 'x',
          'url': 'https://x',
          'icon': 'rocket',
          'openIn': 'browser',
        }),
        throwsArgumentError,
      );
    });
  });
}
