import 'dart:developer';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/organization_auth.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// `outdated`: it needs a newer launcher (its minLauncherVersion).
enum OrganizationStatus {
  loading,
  ready,
  noAccess,
  incompatible,
  outdated,
  offline,
}

class OrganizationView {
  final OrganizationStatus status;
  final List<Instance> instances;

  const OrganizationView(this.status, [this.instances = const []]);

  bool get greyedOut =>
      status == OrganizationStatus.noAccess ||
      status == OrganizationStatus.incompatible ||
      status == OrganizationStatus.outdated;
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

    // A list on screen stays while it refreshes. A message (offline, no
    // access, incompatible) stays until the answer arrives, so the instances
    // it had don't flash in between.
    final current = viewOf(key);
    if (current.status == OrganizationStatus.ready ||
        current.status == OrganizationStatus.loading) {
      _set(
        key,
        OrganizationView(OrganizationStatus.loading, current.instances),
      );
    }

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
        return const OrganizationView(OrganizationStatus.outdated);
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

  /// The list of [key] couldn't be loaded (no connection, a failing server
  /// or no API there): its installed instances are played without asking.
  /// An instance it answers 404 for while its list loads stays blocked.
  static bool isUnreachable(String key) =>
      viewOf(key).status == OrganizationStatus.offline;

  /// [key] stopped answering (e.g. before playing); a list on screen stays
  /// until the next refresh.
  static void markOffline(String key) {
    final current = viewOf(key);
    if (current.status != OrganizationStatus.ready &&
        current.status != OrganizationStatus.loading) {
      return;
    }
    _set(key, OrganizationView(OrganizationStatus.offline, current.instances));
  }

  /// Forgets a removed organization.
  static void forget(String key) {
    organizations.value = {...organizations.value}..remove(key);
  }

  static void _set(String key, OrganizationView view) {
    organizations.value = {...organizations.value, key: view};
  }
}
