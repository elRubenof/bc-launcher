import 'dart:convert';
import 'dart:developer';

import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/token_store.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The organizations the player added, saved on this device in the order
/// they were added. They are identified by [Organization.key].
class OrganizationStore {
  static final organizations = ValueNotifier<List<Organization>>(const []);
  static final selected = ValueNotifier<String?>(null);

  /// Reads the saved organizations. One that can't be read is left out.
  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString("organizations");
    if (saved == null) {
      organizations.value = const [];
      selected.value = null;
      return;
    }

    final result = <Organization>[];
    try {
      for (final item in jsonDecode(saved) as List) {
        try {
          result.add(Organization.fromJson(item as Map<String, dynamic>));
        } catch (e) {
          log("Skipping a saved organization that can't be read: $e");
        }
      }
    } catch (e) {
      log("The saved organizations can't be read: $e");
    }
    organizations.value = List.unmodifiable(result);

    final key = preferences.getString("selectedOrganization");
    selected.value = byKey(key ?? "") != null
        ? key
        : (result.isEmpty ? null : result.first.key);
  }

  /// Shows the organization with [key] and remembers it.
  static Future<void> select(String key) async {
    if (byKey(key) == null) return;
    selected.value = key;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString("selectedOrganization", key);
  }

  static Organization? byKey(String key) {
    for (final organization in organizations.value) {
      if (organization.key == key) return organization;
    }
    return null;
  }

  /// Adds [organization], or replaces the saved one with the same key (e.g.
  /// with the data of a newer discovery) keeping its place.
  static Future<void> save(Organization organization) async {
    final list = [...organizations.value];
    final index = list.indexWhere((saved) => saved.key == organization.key);
    if (index == -1) {
      list.add(organization);
    } else {
      list[index] = organization;
    }
    await _write(list);
  }

  /// Refreshes every saved organization with its discovery (name, logo,
  /// links, API version…).
  static Future<void> refresh() async {
    final fresh = await Future.wait([
      for (final organization in organizations.value) _discover(organization),
    ]);

    for (final organization in fresh) {
      if (organization == null || byKey(organization.key) == null) continue;
      await save(organization);
    }
  }

  static Future<Organization?> _discover(Organization organization) async {
    try {
      return await ApiClient.discovery(organization.url);
    } catch (e) {
      log("Could not refresh ${organization.key}: $e");
      return null;
    }
  }

  /// Removes [organization], its token and its last used instance.
  static Future<void> remove(Organization organization) async {
    await _write([
      for (final saved in organizations.value)
        if (saved.key != organization.key) saved,
    ]);
    await TokenStore.delete(organization.key);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lastInstanceKey(organization.key));
  }

  /// The instance of the organization with [key] entered last, if any.
  static Future<String?> lastInstance(String key) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_lastInstanceKey(key));
  }

  static Future<void> setLastInstance(String key, String instanceId) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_lastInstanceKey(key), instanceId);
  }

  /// Forgets the last instance of the organization with [key], so the
  /// launcher opens on its list next time.
  static Future<void> clearLastInstance(String key) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_lastInstanceKey(key));
  }

  static String _lastInstanceKey(String key) => "lastInstance.$key";

  static Future<void> _write(List<Organization> list) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      "organizations",
      jsonEncode([for (final organization in list) organization.toJson()]),
    );
    organizations.value = List.unmodifiable(list);

    // Keep a valid selection: the first organization when the selected one
    // was removed, or the first one added.
    if (byKey(selected.value ?? "") == null) {
      final first = list.isEmpty ? null : list.first.key;
      selected.value = first;
      if (first == null) {
        await preferences.remove("selectedOrganization");
      } else {
        await preferences.setString("selectedOrganization", first);
      }
    }
  }
}
