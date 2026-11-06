import 'dart:convert';

import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/services/token_store.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures.dart';

Organization organization(String url, {String name = 'Org'}) =>
    Organization.fromDiscovery(
      fixture('discovery')..['name'] = name,
      url: url,
      apiVersion: 1,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await OrganizationStore.load();
  });

  group('OrganizationStore', () {
    test('starts empty', () {
      expect(OrganizationStore.organizations.value, isEmpty);
    });

    test('keeps the order, replaces by key and survives a reload', () async {
      await OrganizationStore.save(organization('https://a.com', name: 'A'));
      await OrganizationStore.save(
        organization('http://127.0.0.1:8787', name: 'Local'),
      );
      await OrganizationStore.save(organization('https://a.com', name: 'A2'));

      List<String> names() => [
        for (final o in OrganizationStore.organizations.value) o.name,
      ];
      expect(names(), ['A2', 'Local']);

      await OrganizationStore.load();
      expect(names(), ['A2', 'Local']);
      expect(OrganizationStore.byKey('127.0.0.1_8787')?.name, 'Local');
      expect(OrganizationStore.byKey('missing.com'), isNull);
    });

    test('notifies when the list changes', () async {
      var changes = 0;
      void listener() => changes++;
      OrganizationStore.organizations.addListener(listener);
      addTearDown(
        () => OrganizationStore.organizations.removeListener(listener),
      );

      await OrganizationStore.save(organization('https://a.com'));
      await OrganizationStore.remove(organization('https://a.com'));
      expect(changes, 2);
    });

    test('skips saved entries that can not be read', () async {
      SharedPreferences.setMockInitialValues({
        'organizations': jsonEncode([
          {'url': 'https://only-url.com'},
          {'name': 'no url'},
          7,
        ]),
      });
      await OrganizationStore.load();

      expect(OrganizationStore.organizations.value.map((o) => o.key), [
        'only-url.com',
      ]);
    });

    test('a broken saved list starts empty', () async {
      SharedPreferences.setMockInitialValues({'organizations': 'not json'});
      await OrganizationStore.load();

      expect(OrganizationStore.organizations.value, isEmpty);
    });

    test('removing an organization also removes its token', () async {
      final a = organization('https://a.com');
      final b = organization('https://b.com');
      final later = DateTime.now().add(const Duration(hours: 24));
      await OrganizationStore.save(a);
      await OrganizationStore.save(b);
      await TokenStore.save(a.key, token: 'token-a', expiresAt: later);
      await TokenStore.save(b.key, token: 'token-b', expiresAt: later);

      await OrganizationStore.remove(a);

      expect(OrganizationStore.organizations.value.map((o) => o.key), [b.key]);
      expect(await TokenStore.token(a.key), isNull);
      expect(await TokenStore.token(b.key), 'token-b');
    });
  });

  group('TokenStore', () {
    // TokenStore keeps what it read in memory; these keys are not reused by
    // other tests, so the cache can't hide a missing write.
    test('saves, replaces and keeps tokens per organization', () async {
      final later = DateTime.now().add(const Duration(hours: 24));

      expect(await TokenStore.token('t1.com'), isNull);
      await TokenStore.save('t1.com', token: 'one', expiresAt: later);
      await TokenStore.save('t2.com', token: 'two', expiresAt: later);
      await TokenStore.save('t1.com', token: 'uno', expiresAt: later);

      expect(await TokenStore.token('t1.com'), 'uno');
      expect(await TokenStore.token('t2.com'), 'two');
    });

    test('a token about to expire counts as expired', () async {
      final now = DateTime.now();
      await TokenStore.save(
        't3.com',
        token: 'soon',
        expiresAt: now.add(const Duration(minutes: 2)),
      );
      await TokenStore.save(
        't4.com',
        token: 'past',
        expiresAt: now.subtract(const Duration(hours: 1)),
      );

      expect(await TokenStore.token('t3.com'), isNull);
      expect(await TokenStore.token('t4.com'), isNull);
    });

    test('keeps every token in one secure entry', () async {
      await TokenStore.save(
        't5.com',
        token: 'five',
        expiresAt: DateTime.utc(2030),
      );
      final stored = await const FlutterSecureStorage().read(
        key: 'organization_tokens',
      );

      expect(jsonDecode(stored!)['t5.com'], {
        'token': 'five',
        'expiresAt': '2030-01-01T00:00:00.000Z',
      });
    });

    test('delete removes only that token', () async {
      final later = DateTime.now().add(const Duration(hours: 24));
      await TokenStore.save('t6.com', token: 'six', expiresAt: later);
      await TokenStore.save('t7.com', token: 'seven', expiresAt: later);

      await TokenStore.delete('t6.com');

      expect(await TokenStore.token('t6.com'), isNull);
      expect(await TokenStore.token('t7.com'), 'seven');
    });
  });
}
