import 'dart:developer';
import 'dart:io';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

/// What the launcher keeps on disk for each instance.
class InstanceManager {
  static Future<Directory> organizationFolder(String organizationKey) async {
    final support = await getApplicationSupportDirectory();
    return Directory(join(support.path, organizationKey));
  }

  static Future<Directory> instanceFolder(
    String organizationKey,
    String instanceId,
  ) async {
    final folder = await organizationFolder(organizationKey);
    return Directory(join(folder.path, instanceId));
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
}
