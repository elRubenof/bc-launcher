import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures.dart';

/// Answers each organization's `/instances` with [answers] by host.
class FakeOrganizations implements HttpClientAdapter {
  final Map<String, ResponseBody Function()> answers;

  FakeOrganizations(this.answers);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async => answers[options.uri.host]!();

  @override
  void close({bool force = false}) {}
}

ResponseBody json(int status, Object body) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    'content-type': ['application/json'],
  },
);

Organization organization(String host, {String? minLauncherVersion}) =>
    Organization.fromDiscovery(
      fixture('discovery')..['minLauncherVersion'] = minLauncherVersion,
      url: 'https://$host',
      apiVersion: 1,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Map<String, ResponseBody Function()> answers;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await OrganizationStore.load();
    InstanceCatalog.organizations.value = const {};
    InstanceCatalog.launcherVersion = () async => '1.0.1';
    answers = {};
    InstanceCatalog.clientFor = (organization) => ApiClient(
      organization,
      getToken: () async => 'token',
      dio: Dio()..httpClientAdapter = FakeOrganizations(answers),
    );
  });

  Future<OrganizationView> load(
    Organization organization,
    ResponseBody Function() answer,
  ) async {
    await OrganizationStore.save(organization);
    answers[Uri.parse(organization.url).host] = answer;
    await InstanceCatalog.refresh(organization);
    return InstanceCatalog.viewOf(organization.key);
  }

  test('an organization not loaded yet is loading', () {
    expect(InstanceCatalog.viewOf('a.com').status, OrganizationStatus.loading);
  });

  test('a member gets the instances', () async {
    final view = await load(
      organization('a.com'),
      () => json(200, fixture('instances')),
    );

    expect(view.status, OrganizationStatus.ready);
    expect(view.instances.map((i) => i.id), ['spartaland-3', 'cockwork']);
    expect(view.greyedOut, isFalse);
  });

  test('not_member greys it out', () async {
    final view = await load(
      organization('a.com'),
      () => json(403, {'code': 'not_member'}),
    );

    expect(view.status, OrganizationStatus.noAccess);
    expect(view.greyedOut, isTrue);
  });

  test('a launcher older than minLauncherVersion greys it out', () async {
    final view = await load(
      organization('a.com', minLauncherVersion: '1.2.0'),
      () => json(200, fixture('instances')),
    );

    expect(view.status, OrganizationStatus.incompatible);
    expect(view.greyedOut, isTrue);
  });

  test('offline keeps the instances it had', () async {
    final a = organization('a.com');
    await load(a, () => json(200, fixture('instances')));
    answers['a.com'] = () => json(503, {});

    await InstanceCatalog.refresh(a);
    final view = InstanceCatalog.viewOf(a.key);

    expect(view.status, OrganizationStatus.offline);
    expect(view.instances, hasLength(2));
    expect(view.greyedOut, isFalse);
  });

  test('a list answering 404 (no API there) does not answer either', () async {
    final view = await load(organization('a.com'), () => json(404, {}));

    expect(view.status, OrganizationStatus.offline);
    expect(InstanceCatalog.isUnreachable('a.com'), isTrue);
  });

  test('retrying while offline keeps the message until it answers', () async {
    final a = organization('a.com');
    await load(a, () => json(200, fixture('instances')));
    answers['a.com'] = () => json(503, {});
    await InstanceCatalog.refresh(a);

    final seen = <OrganizationStatus>[];
    void listener() => seen.add(InstanceCatalog.viewOf(a.key).status);
    InstanceCatalog.organizations.addListener(listener);
    addTearDown(() => InstanceCatalog.organizations.removeListener(listener));

    await InstanceCatalog.refresh(a);

    expect(seen, [OrganizationStatus.offline]);
  });

  test('markOffline keeps the list, and the next refresh decides', () async {
    final a = organization('a.com');
    await load(a, () => json(200, fixture('instances')));

    expect(InstanceCatalog.isUnreachable(a.key), isFalse);
    InstanceCatalog.markOffline(a.key);
    expect(InstanceCatalog.viewOf(a.key).status, OrganizationStatus.offline);
    expect(InstanceCatalog.isUnreachable(a.key), isTrue);
    expect(InstanceCatalog.viewOf(a.key).instances, hasLength(2));

    await InstanceCatalog.refresh(a);
    expect(InstanceCatalog.viewOf(a.key).status, OrganizationStatus.ready);
  });

  test('markOffline leaves a greyed out organization as it is', () async {
    final a = organization('a.com', minLauncherVersion: '1.2.0');
    await load(a, () => json(200, fixture('instances')));

    InstanceCatalog.markOffline(a.key);
    expect(
      InstanceCatalog.viewOf(a.key).status,
      OrganizationStatus.incompatible,
    );
  });

  test('a list refreshing stays on screen', () async {
    final a = organization('a.com');
    await load(a, () => json(200, fixture('instances')));

    final seen = <OrganizationView>[];
    void listener() => seen.add(InstanceCatalog.viewOf(a.key));
    InstanceCatalog.organizations.addListener(listener);
    addTearDown(() => InstanceCatalog.organizations.removeListener(listener));

    await InstanceCatalog.refresh(a);

    expect(seen.first.status, OrganizationStatus.loading);
    expect(seen.first.instances, hasLength(2));
    expect(seen.last.status, OrganizationStatus.ready);
  });

  test('comes back by itself when access returns', () async {
    final a = organization('a.com');
    await load(a, () => json(403, {'code': 'not_member'}));
    answers['a.com'] = () => json(200, {'instances': []});

    await InstanceCatalog.refreshAll();

    expect(InstanceCatalog.viewOf(a.key).status, OrganizationStatus.ready);
  });

  test('refreshAll loads every organization', () async {
    final a = organization('a.com'), b = organization('b.com');
    await OrganizationStore.save(a);
    await OrganizationStore.save(b);
    answers['a.com'] = () => json(200, fixture('instances'));
    answers['b.com'] = () => json(403, {'code': 'not_member'});

    await InstanceCatalog.refreshAll();

    expect(InstanceCatalog.viewOf(a.key).status, OrganizationStatus.ready);
    expect(InstanceCatalog.viewOf(b.key).status, OrganizationStatus.noAccess);
  });

  test('a removed organization is not brought back', () async {
    final a = organization('a.com');
    answers['a.com'] = () => json(200, {'instances': []});

    await InstanceCatalog.refresh(a);

    expect(InstanceCatalog.organizations.value, isNot(contains(a.key)));
  });
}
