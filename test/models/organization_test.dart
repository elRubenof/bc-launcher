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
}
