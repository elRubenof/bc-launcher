import 'dart:developer';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/organization_auth.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum OrganizationStatus { loading, ready, noAccess, incompatible, offline }

class OrganizationView {
  final OrganizationStatus status;
  final List<Instance> instances;

  const OrganizationView(this.status, [this.instances = const []]);

  bool get greyedOut =>
      status == OrganizationStatus.noAccess ||
      status == OrganizationStatus.incompatible;
}

/// The instances of every added organization and whether each one can be
/// used, keyed by [Organization.key]. Organizations without an entry yet are
/// loading.
class InstanceCatalog {
  static final organizations = ValueNotifier<Map<String, OrganizationView>>(
    const {},
  );

  /// Builds the API client of an organization (tests replace it).
  @visibleForTesting
  static ApiClient Function(Organization) clientFor =
      OrganizationAuth.clientFor;

  /// The running launcher's version (tests replace it).
  @visibleForTesting
  static Future<String> Function() launcherVersion = () async =>
      (await PackageInfo.fromPlatform()).version;

  static OrganizationView viewOf(String key) =>
      organizations.value[key] ??
      const OrganizationView(OrganizationStatus.loading);

  /// Asks every added organization for its instances, in parallel.
  static Future<void> refreshAll() async {
    await Future.wait([
      for (final organization in OrganizationStore.organizations.value)
        refresh(organization),
    ]);
  }

  static Future<void> refresh(Organization organization) async {
    final key = organization.key;
    if (OrganizationStore.byKey(key) == null) return;
    _set(
      key,
      OrganizationView(OrganizationStatus.loading, viewOf(key).instances),
    );

    final view = await _load(organization);
    if (OrganizationStore.byKey(key) == null) {
      forget(key);
      return;
    }
    _set(key, view);
  }

  static Future<OrganizationView> _load(Organization organization) async {
    final previous = viewOf(organization.key).instances;
    try {
      if (organization.needsNewerLauncher(await launcherVersion())) {
        return const OrganizationView(OrganizationStatus.incompatible);
      }

      final instances = await clientFor(organization).instances();
      return OrganizationView(OrganizationStatus.ready, instances);
    } on ApiError catch (e) {
      return switch (e.type) {
        ApiErrorType.notMember => const OrganizationView(
          OrganizationStatus.noAccess,
        ),
        ApiErrorType.incompatible || ApiErrorType.upgradeRequired =>
          const OrganizationView(OrganizationStatus.incompatible),
        _ => OrganizationView(OrganizationStatus.offline, previous),
      };
    } catch (e) {
      log("Could not load the instances of ${organization.key}: $e");
      return OrganizationView(OrganizationStatus.offline, previous);
    }
  }

  /// Forgets a removed organization.
  static void forget(String key) {
    organizations.value = {...organizations.value}..remove(key);
  }

  static void _set(String key, OrganizationView view) {
    organizations.value = {...organizations.value, key: view};
  }
}
