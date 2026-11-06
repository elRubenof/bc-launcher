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

  /// Reads the saved organizations. One that can't be read is left out.
  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString("organizations");
    if (saved == null) return;

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

  /// Removes [organization] and its token.
  static Future<void> remove(Organization organization) async {
    await _write([
      for (final saved in organizations.value)
        if (saved.key != organization.key) saved,
    ]);
    await TokenStore.delete(organization.key);
  }

  static Future<void> _write(List<Organization> list) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      "organizations",
      jsonEncode([for (final organization in list) organization.toJson()]),
    );
    organizations.value = List.unmodifiable(list);
  }
}
