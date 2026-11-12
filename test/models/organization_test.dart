import 'dart:convert';

import 'package:bc_launcher/models/organization.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures.dart';

void main() {
  Organization fromDiscovery() => Organization.fromDiscovery(
    fixture('discovery'),
    url: 'https://example.com',
    apiVersion: 1,
  );

  test('reads the discovery document', () {
    final organization = fromDiscovery();

    expect(organization.url, 'https://example.com');
    expect(organization.apiVersion, 1);
    expect(organization.name, 'Boludo´s Company');
    expect(organization.description, isNull);
    expect(organization.logoUrl, startsWith('https://example.com/api/v1'));
    expect(organization.discordUrl, 'https://discord.gg/example');
    expect(organization.webUrl, isNull);
    expect(organization.visibility, OrganizationVisibility.public);
    expect(organization.apiVersions, [1]);
    expect(organization.minLauncherVersion, isNull);
    expect(organization.capabilities, isEmpty);
    expect(organization.authType, AuthType.unverified);
  });

  test('reads both auth types', () {
    final json = fixture('discovery')..['auth'] = {'type': 'mojang-session'};
    final organization = Organization.fromDiscovery(
      json,
      url: 'https://example.com',
      apiVersion: 1,
    );
    expect(organization.authType, AuthType.mojangSession);
  });

  test('saves and reads back the same organization', () {
    final organization = fromDiscovery();
    final saved = jsonDecode(jsonEncode(organization.toJson()));

    expect(Organization.fromJson(saved).toJson(), organization.toJson());
  });

  test('reads a saved organization with only its url', () {
    final organization = Organization.fromJson({
      'url': 'https://only-url.example.com',
    });

    expect(organization.name, 'only-url.example.com');
    expect(organization.apiVersion, 1);
    expect(organization.apiVersions, [1]);
    expect(organization.visibility, OrganizationVisibility.public);
    expect(organization.capabilities, isEmpty);
    expect(organization.authType, AuthType.mojangSession);
  });

  test('falls back to defaults for unknown saved values', () {
    final organization = Organization.fromJson({
      'url': 'https://example.com',
      'name': 'Example',
      'apiVersion': 2,
      'visibility': 'secret',
      'authType': 'magic',
      'description': 7,
    });

    expect(organization.apiVersion, 2);
    expect(organization.apiVersions, [2]);
    expect(organization.visibility, OrganizationVisibility.public);
    expect(organization.authType, AuthType.mojangSession);
    expect(organization.description, isNull);
  });

  test('a saved organization needs its url', () {
    expect(() => Organization.fromJson({'name': 'No url'}), throwsA(anything));
  });

  test('key is the host and port, valid as a folder name', () {
    Organization at(String url) => Organization.fromJson({'url': url});

    expect(at('https://example.com').key, 'example.com');
    expect(at('http://127.0.0.1:8787').key, '127.0.0.1_8787');
    expect(at('https://example.com').key, at('http://example.com').key);
  });

  test(
    'key keeps organizations on the same host under different paths apart',
    () {
      expect(Organization.keyOf('https://example.com/a'), 'example.com_a');
      expect(Organization.keyOf('https://example.com/a/b'), 'example.com_a_b');
      expect(
        Organization.keyOf('https://example.com/a'),
        isNot(Organization.keyOf('https://example.com/b')),
      );
    },
  );

  test('key ignores default ports, the scheme and the host case', () {
    expect(Organization.keyOf('https://example.com:443'), 'example.com');
    expect(Organization.keyOf('http://example.com:80'), 'example.com');
    expect(Organization.keyOf('https://Example.com'), 'example.com');
    expect(Organization.keyOf('example.com'), 'example.com');
    expect(Organization.keyOf('https://example.com:8443'), 'example.com_8443');
  });

  test('hasCapability', () {
    final json = fixture('discovery')..['capabilities'] = ['server-status'];
    final organization = Organization.fromDiscovery(
      json,
      url: 'https://example.com',
      apiVersion: 1,
    );

    expect(organization.hasCapability('server-status'), isTrue);
    expect(organization.hasCapability('optional-mods'), isFalse);
  });

  group('needsNewerLauncher', () {
    Organization requiring(String? minimum) => Organization.fromJson({
      'url': 'https://example.com',
      'minLauncherVersion': minimum,
    });

    test('without a minimum any launcher is fine', () {
      expect(requiring(null).needsNewerLauncher('0.0.1'), isFalse);
    });

    test('compares x.y.z numerically', () {
      final organization = requiring('1.10.0');
      expect(organization.needsNewerLauncher('1.9.9'), isTrue);
      expect(organization.needsNewerLauncher('1.10.0'), isFalse);
      expect(organization.needsNewerLauncher('1.10.1'), isFalse);
      expect(organization.needsNewerLauncher('2.0.0'), isFalse);
    });

    test('missing parts count as 0 and suffixes are ignored', () {
      expect(requiring('1.2').needsNewerLauncher('1.2.0'), isFalse);
      expect(requiring('1.2.1').needsNewerLauncher('1.2'), isTrue);
      expect(requiring('1.2.0').needsNewerLauncher('1.2.0+5'), isFalse);
      expect(requiring('1.2.0-beta').needsNewerLauncher('1.1.9'), isTrue);
    });
  });
}
