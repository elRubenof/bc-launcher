import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

enum InstallStatus { notInstalled, updateAvailable, upToDate }

/// What was installed in an instance's folder, kept in
/// `.bc-launcher/state.json`.
class InstanceState {
  final int contentVersion;
  final String minecraftVersion;
  final LoaderType loaderType;
  final String? loaderVersion;

  /// `false` until the installation or update finishes.
  final bool complete;

  /// The server address the launcher wrote in `servers.dat`, if it did.
  final String? serverEntryAddress;

  const InstanceState({
    required this.contentVersion,
    required this.minecraftVersion,
    required this.loaderType,
    this.loaderVersion,
    required this.complete,
    this.serverEntryAddress,
  });

  factory InstanceState.fromJson(Map<String, dynamic> json) {
    return InstanceState(
      contentVersion: json['contentVersion'],
      minecraftVersion: json['minecraftVersion'],
      loaderType: LoaderType.values.byName(json['loaderType']),
      loaderVersion: json['loaderVersion'],
      complete: json['complete'] == true,
      serverEntryAddress: json['serverEntryAddress'],
    );
  }

  Map<String, dynamic> toJson() => {
    'contentVersion': contentVersion,
    'minecraftVersion': minecraftVersion,
    'loaderType': loaderType.name,
    'loaderVersion': loaderVersion,
    'complete': complete,
    'serverEntryAddress': serverEntryAddress,
  };
}

/// What the launcher keeps on disk for each instance.
class InstanceManager {
  /// Where instance folders live (tests replace it).
  @visibleForTesting
  static Future<Directory> Function() supportDirectory =
      getApplicationSupportDirectory;

  static Future<Directory> organizationFolder(String organizationKey) async {
    final support = await supportDirectory();
    return Directory(join(support.path, organizationKey));
  }

  static Future<Directory> instanceFolder(
    String organizationKey,
    String instanceId,
  ) async {
    final folder = await organizationFolder(organizationKey);
    return Directory(join(folder.path, instanceId));
  }

  /// The launcher's own files inside an instance folder.
  static Future<Directory> launcherFolder(
    String organizationKey,
    String instanceId,
  ) async {
    final folder = await instanceFolder(organizationKey, instanceId);
    return Directory(join(folder.path, ".bc-launcher"));
  }

  /// What is installed, or `null` when nothing is (or it can't be read).
  static Future<InstanceState?> readState(
    String organizationKey,
    String instanceId,
  ) async {
    final file = await _stateFile(organizationKey, instanceId);
    try {
      if (!await file.exists()) return null;
      return InstanceState.fromJson(
        jsonDecode(await file.readAsString()) as Map<String, dynamic>,
      );
    } catch (e) {
      log("Could not read the state of $instanceId: $e");
      return null;
    }
  }

  /// Saves [state], replacing the previous one at once.
  static Future<void> writeState(
    String organizationKey,
    String instanceId,
    InstanceState state,
  ) async {
    final file = await _stateFile(organizationKey, instanceId);
    await file.parent.create(recursive: true);
    final part = File("${file.path}.part");
    await part.writeAsString(jsonEncode(state.toJson()));
    await part.rename(file.path);
  }

  static Future<InstallStatus> status(
    String organizationKey,
    Instance instance,
  ) async => statusOf(instance, await readState(organizationKey, instance.id));

  /// Compares what the organization serves ([instance]) with what is
  /// installed ([state]).
  static InstallStatus statusOf(Instance instance, InstanceState? state) {
    if (state == null || !state.complete) return InstallStatus.notInstalled;

    final same =
        state.contentVersion == instance.contentVersion &&
        state.minecraftVersion == instance.minecraftVersion &&
        state.loaderType == instance.loaderType &&
        state.loaderVersion == instance.loaderVersion;
    return same ? InstallStatus.upToDate : InstallStatus.updateAvailable;
  }

  /// Deletes every instance of an organization from this computer.
  static Future<void> deleteOrganization(String organizationKey) async {
    try {
      final folder = await organizationFolder(organizationKey);
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (e) {
      log("Could not delete the folder of $organizationKey: $e");
    }
  }

  static Future<File> _stateFile(
    String organizationKey,
    String instanceId,
  ) async {
    final folder = await launcherFolder(organizationKey, instanceId);
    return File(join(folder.path, "state.json"));
  }
}
