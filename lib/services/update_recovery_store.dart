import 'dart:convert';
import 'dart:io';

import 'package:desktop_updater/updater_controller.dart';

/// Keeps `desktop_updater`'s pending install marker in a JSON file, so the
/// next start can tell whether the launcher update finished. Adapted from the
/// package's example store.
final class UpdateRecoveryFileStore implements UpdateRecoveryStore {
  final File file;

  UpdateRecoveryFileStore(this.file);

  @override
  Future<UpdateInstallRecoveryMarker?> readPendingInstall({
    required String channel,
  }) async {
    if (!await file.exists()) return null;

    final json = jsonDecode(await file.readAsString());
    if (json is! Map<String, dynamic>) {
      throw const FormatException("The recovery marker is not a JSON object.");
    }
    final marker = _fromJson(json);
    return marker.channel == channel ? marker : null;
  }

  /// Replaces the file atomically: the new marker is written next to it and
  /// renamed over it, restoring the old one if that fails.
  @override
  Future<void> writePendingInstall(UpdateInstallRecoveryMarker marker) async {
    await file.parent.create(recursive: true);
    final suffix = "$pid-${DateTime.now().microsecondsSinceEpoch}";
    final pending = File("${file.path}.pending-$suffix");
    final backup = File("${file.path}.backup-$suffix");
    await pending.writeAsString(
      "${jsonEncode(_toJson(marker))}\n",
      flush: true,
    );

    var movedExisting = false;
    try {
      if (await file.exists()) {
        await file.rename(backup.path);
        movedExisting = true;
      }
      await pending.rename(file.path);
      if (movedExisting && await backup.exists()) await backup.delete();
    } catch (_) {
      if (!await file.exists() && movedExisting && await backup.exists()) {
        await backup.rename(file.path);
      }
      rethrow;
    } finally {
      if (await pending.exists()) await pending.delete();
    }
  }

  @override
  Future<void> clearPendingInstall({required String channel}) async {
    final marker = await readPendingInstall(channel: channel);
    if (marker != null && await file.exists()) await file.delete();
  }

  static Map<String, Object?> _toJson(UpdateInstallRecoveryMarker marker) => {
    "createdAt": marker.createdAt.toUtc().toIso8601String(),
    "packageVersion": marker.packageVersion,
    "platform": marker.platform,
    "channel": marker.channel,
    "appVersion": marker.appVersion,
    "updateVersion": marker.updateVersion,
    "updateBuildNumber": marker.updateBuildNumber,
    "expectedPackageId": marker.expectedPackageId,
    "stagingPath": marker.stagingPath,
    "stageProvenanceSha256": marker.stageProvenanceSha256,
    "diagnosticsText": marker.diagnosticsText,
    "transactionId": marker.transactionId,
  };

  static UpdateInstallRecoveryMarker _fromJson(Map<String, dynamic> json) {
    return UpdateInstallRecoveryMarker(
      createdAt: DateTime.parse(_required(json, "createdAt")).toUtc(),
      packageVersion: _required(json, "packageVersion"),
      platform: _required(json, "platform"),
      channel: _required(json, "channel"),
      appVersion: _optional(json, "appVersion"),
      updateVersion: _optional(json, "updateVersion"),
      updateBuildNumber: json["updateBuildNumber"] as int?,
      expectedPackageId: _optional(json, "expectedPackageId"),
      stagingPath: _optional(json, "stagingPath"),
      stageProvenanceSha256: _optional(json, "stageProvenanceSha256"),
      diagnosticsText: _optional(json, "diagnosticsText"),
      transactionId: _optional(json, "transactionId"),
    );
  }

  static String _required(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException("The recovery marker has no $key.");
    }
    return value;
  }

  static String? _optional(Map<String, dynamic> json, String key) {
    final value = json[key];
    if (value != null && value is! String) {
      throw FormatException("The recovery marker's $key is not a string.");
    }
    return value as String?;
  }
}
