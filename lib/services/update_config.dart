import 'dart:io';

import 'package:bc_launcher/services/update_recovery_store.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where the launcher's own updates come from and how they are trusted. The
/// feed is only ever this repo's GitHub Releases, never an organization.
class UpdateConfig {
  /// A local feed for testing updates (`UPDATE_FEED_URL`, never set in
  /// releases). Its releases are signed with a test key, [_testKey].
  static const _testFeedUrl = String.fromEnvironment('UPDATE_FEED_URL');

  /// `<key id>=<base64 public key>` of that test feed (`UPDATE_TEST_KEY`).
  static const _testKey = String.fromEnvironment('UPDATE_TEST_KEY');

  /// The signed index of releases, an asset of the latest GitHub release.
  /// The release key is bound to this exact URL (`desktop_updater.yaml`).
  static final appArchiveUrl = Uri.parse(
    _testFeedUrl.isNotEmpty ? _testFeedUrl : "https://github.com/elRubenof/bc-launcher/releases/latest/download/app-archive.json",
  );

  /// The Ed25519 keys that sign the feed, copied from
  /// `desktop_updater.keys.json`. Pinned here, never read from a file.
  static const _releaseKeys = {
    "release-defd1029f92a6249a0507dbd":
        "lvH8fKW8MX0P2mjr+eusVYCmUhPV9AcyvKnlZoeQV+4=",
  };

  /// [_releaseKeys], plus the test key in a build made to test updates.
  static Map<String, String> get trustedReleasePublicKeys {
    final separator = _testKey.indexOf("=");
    if (separator <= 0) return _releaseKeys;
    return {
      ..._releaseKeys,
      _testKey.substring(0, separator): _testKey.substring(separator + 1),
    };
  }

  /// The identity each platform's `release.json` must carry.
  static String get packageId {
    if (Platform.isMacOS) return "com.bcr.bclauncher";
    if (Platform.isWindows) return "bc_launcher";
    if (Platform.isLinux) return "com.bcr.bc_launcher";
    throw UnsupportedError("The launcher only updates on desktop.");
  }

  /// Windows: the Inno Setup installer, the only file in the update's zip.
  static const windowsInstaller = "BC-Launcher-Installer.exe";

  /// How the launcher runs [windowsInstaller]: only a progress window, no
  /// questions or cancel, closing what is still open, and opening the launcher
  /// again when it's done (`/RELAUNCH=1`, read by `bc-launcher.iss`).
  static List<String> windowsInstallerArguments(String log) => [
    "/SILENT",
    "/SP-",
    "/SUPPRESSMSGBOXES",
    "/NOCANCEL",
    "/NORESTART",
    "/CLOSEAPPLICATIONS",
    "/RELAUNCH=1",
    "/LOG=$log",
  ];

  static Future<Directory> _updateFolder() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, "update"));
  }

  static Future<UpdateRecoveryFileStore> recoveryStore() async {
    final folder = await _updateFolder();
    return UpdateRecoveryFileStore(
      File(p.join(folder.path, "pending-install.json")),
    );
  }

  /// The last Windows installation's log, for support.
  static Future<String> installLog() async {
    final folder = await _updateFolder();
    await folder.create(recursive: true);
    return p.join(folder.path, "install.log");
  }
}
