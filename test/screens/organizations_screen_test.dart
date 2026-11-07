import 'dart:convert';
import 'dart:typed_data';

import 'package:bc_launcher/l10n/app_localizations.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/screens/organizations_screen.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/utils/global_settings.dart';
import 'package:bc_launcher/widgets/instance_card.dart';
import 'package:bc_launcher/widgets/organization_rail.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../fixtures.dart';

/// Answers each organization's `/instances` by host.
class FakeOrganizations implements HttpClientAdapter {
  final Map<String, (int, Object)> answers;

  FakeOrganizations(this.answers);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final (status, body) = answers[options.uri.host]!;
    return ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        'content-type': ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Organization organization(String host, String name) =>
    Organization.fromDiscovery(
      fixture('discovery')
        ..['name'] = name
        ..['logoUrl'] = null,
      url: 'https://$host',
      apiVersion: 1,
    );

void main() {
  late Map<String, (int, Object)> answers;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    await OrganizationStore.load();
    await GlobalSettings.load();
    InstanceCatalog.organizations.value = const {};
    InstanceCatalog.launcherVersion = () async => '1.0.1';
    answers = {};
    InstanceCatalog.clientFor = (organization) => ApiClient(
      organization,
      getToken: () async => 'token',
      dio: Dio()..httpClientAdapter = FakeOrganizations(answers),
    );
  });

  Future<void> show(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 750);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: OrganizationsScreen(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('one organization: its instances and no column', (tester) async {
    await OrganizationStore.save(organization('a.com', 'Boludo´s Company'));
    answers['a.com'] = (200, fixture('instances'));

    await show(tester);

    expect(find.byType(OrganizationRail), findsNothing);
    expect(find.text('Boludo´s Company'), findsOneWidget);
    expect(find.text('Elige una instancia'), findsOneWidget);
    expect(find.byType(InstanceCard), findsNWidgets(2));
    expect(find.text('1.21.1 · Fabric'), findsOneWidget);
  });

  testWidgets('two organizations: the column, and switching', (tester) async {
    await OrganizationStore.save(organization('a.com', 'Alpha'));
    await OrganizationStore.save(organization('b.com', 'Beta'));
    answers['a.com'] = (200, fixture('instances'));
    answers['b.com'] = (200, {'instances': []});

    await show(tester);
    expect(find.byType(OrganizationRail), findsOneWidget);
    expect(find.byType(InstanceCard), findsNWidgets(2));

    await tester.tap(find.byTooltip('Beta'));
    await tester.pumpAndSettle();

    expect(OrganizationStore.selected.value, 'b.com');
    expect(find.text('Aún no hay instancias para ti'), findsOneWidget);
  });

  testWidgets('lost access: explained, and it can be removed', (tester) async {
    await OrganizationStore.save(organization('a.com', 'Alpha'));
    await OrganizationStore.save(organization('b.com', 'Beta'));
    await OrganizationStore.select('b.com');
    answers['a.com'] = (200, {'instances': []});
    answers['b.com'] = (403, {'code': 'not_member'});

    await show(tester);
    expect(find.text('Ya no tienes acceso a Beta'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline_rounded), findsWidgets);

    await tester.tap(find.text('Eliminar organización'));
    await tester.pumpAndSettle();
    expect(find.text('¿Eliminar Beta?'), findsOneWidget);

    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(OrganizationStore.organizations.value.map((o) => o.key), ['a.com']);
    expect(OrganizationStore.selected.value, 'a.com');
    expect(find.byType(OrganizationRail), findsNothing);
  });

  testWidgets('incompatible: download and remove', (tester) async {
    await OrganizationStore.save(organization('a.com', 'Alpha'));
    InstanceCatalog.launcherVersion = () async => '0.0.1';
    final json = fixture('discovery')
      ..['name'] = 'Alpha'
      ..['logoUrl'] = null
      ..['minLauncherVersion'] = '9.0.0';
    await OrganizationStore.save(
      Organization.fromDiscovery(json, url: 'https://a.com', apiVersion: 1),
    );

    await show(tester);

    expect(find.text('Alpha ya no es compatible'), findsOneWidget);
    expect(find.text('Descargar la nueva versión'), findsOneWidget);
    expect(find.text('Eliminar organización'), findsOneWidget);
  });

  testWidgets('offline: explained, with retry', (tester) async {
    await OrganizationStore.save(organization('a.com', 'Alpha'));
    answers['a.com'] = (404, {'code': 'not_found'});

    await show(tester);
    expect(find.text('No se ha podido conectar con Alpha'), findsOneWidget);

    answers['a.com'] = (200, fixture('instances'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byType(InstanceCard), findsNWidgets(2));
  });
}
