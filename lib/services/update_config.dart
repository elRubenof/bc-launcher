import 'dart:io';

import 'package:bc_launcher/services/update_recovery_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the launcher's own updates come from and how they are trusted. The
/// feed is only ever this repo's GitHub Releases, never an organization.
class UpdateConfig {
  /// The signed index of releases, an asset of the latest GitHub release.
  /// The release key is bound to this exact URL (`desktop_updater.yaml`).
  static final appArchiveUrl = Uri.parse(
    "https://github.com/elRubenof/bc-launcher/releases/latest/download/app-archive.json",
  );

  /// The Ed25519 keys that sign the feed, copied from
  /// `desktop_updater.keys.json`. Pinned here, never read from a file.
  static const trustedReleasePublicKeys = {
    "release-defd1029f92a6249a0507dbd":
        "lvH8fKW8MX0P2mjr+eusVYCmUhPV9AcyvKnlZoeQV+4=",
  };

  /// The identity each platform's `release.json` must carry.
  static String get packageId {
    if (Platform.isMacOS) return "com.bcr.bclauncher";
    if (Platform.isWindows) return "bc_launcher";
    if (Platform.isLinux) return "com.bcr.bc_launcher";
    throw UnsupportedError("The launcher only updates on desktop.");
  }

  static Future<UpdateRecoveryFileStore> recoveryStore() async {
    final support = await getApplicationSupportDirectory();
    return UpdateRecoveryFileStore(
      File(p.join(support.path, "update", "pending-install.json")),
    );
  }
}
