import 'dart:convert';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/manifest.dart';
import 'package:bc_launcher/models/news.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  group('manifest', () {
    test('reads the versions, managed folders and files', () {
      final manifest = Manifest.fromJson(fixture('manifest'));

      expect(manifest.contentVersion, 3);
      expect(manifest.minecraftVersion, '1.21.1');
      expect(manifest.loaderType, LoaderType.fabric);
      expect(manifest.loaderVersion, '0.16.5');
      expect(manifest.serverAddress, 'play.example.com');
      expect(manifest.managedDirs, ['mods']);

      final [mod, options] = manifest.files;
      expect(mod.path, 'mods/sodium.jar');
      expect(mod.sha256, hasLength(64));
      expect(mod.size, 1234567);
      expect(mod.policy, FilePolicy.always);
      expect(mod.url, contains('/api/v1/blobs/'));
      expect(options.policy, FilePolicy.once);
    });

    test('saves and reads back the same manifest', () {
      final manifest = Manifest.fromJson(fixture('manifest'));
      final saved = jsonDecode(jsonEncode(manifest.toJson()));

      expect(Manifest.fromJson(saved).toJson(), manifest.toJson());
    });

    test('an unknown file policy is an error', () {
      final json = fixture('manifest');
      json['files'][0]['policy'] = 'sometimes';

      expect(() => Manifest.fromJson(json), throwsArgumentError);
    });
  });

  group('news', () {
    test('reads a news item with and without image and link', () {
      final [first, second] = [
        for (final json in fixture('news')['items']) News.fromJson(json),
      ];

      expect(first.title, 'Empieza la temporada 3');
      expect(first.body, contains('**markdown**'));
      expect(first.imageUrl, isNotNull);
      expect(first.link, 'https://example.com/temporada-3');
      expect(first.pinned, isTrue);
      expect(first.publishedAt, DateTime.utc(2026, 11, 1, 18));

      expect(second.imageUrl, isNull);
      expect(second.link, isNull);
      expect(second.pinned, isFalse);
    });
  });
}
