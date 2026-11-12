import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:bc_launcher/models/instance_settings.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show join;

/// One instance's game settings, in `.bc-launcher/settings.json` inside its
/// folder, so they go when the instance is deleted.
class InstanceSettingsStore extends ValueNotifier<InstanceSettings> {
  /// The instance's folder.
  final Directory folder;

  InstanceSettingsStore(this.folder) : super(InstanceSettings.empty);

  File get _file => File(join(folder.path, ".bc-launcher", "settings.json"));

  /// Reads the saved settings; none, or ones that can't be read, are the
  /// defaults.
  Future<void> load() async {
    try {
      if (!await _file.exists()) return;
      value = InstanceSettings.fromJson(
        jsonDecode(await _file.readAsString()) as Map<String, dynamic>,
      );
    } catch (e) {
      log("Could not read the settings of ${folder.path}: $e");
    }
  }

  /// Shows [settings] and saves them, replacing the previous ones at once.
  Future<void> save(InstanceSettings settings) async {
    value = settings;
    try {
      await _file.parent.create(recursive: true);
      final part = File("${_file.path}.part");
      await part.writeAsString(jsonEncode(settings.toJson()));
      await part.rename(_file.path);
    } catch (e) {
      log("Could not save the settings of ${folder.path}: $e");
    }
  }

  /// Back to the defaults.
  Future<void> reset() async {
    value = InstanceSettings.empty;
    try {
      if (await _file.exists()) await _file.delete();
    } catch (e) {
      log("Could not delete the settings of ${folder.path}: $e");
    }
  }
}
