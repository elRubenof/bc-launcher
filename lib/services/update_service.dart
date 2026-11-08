import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:bc_launcher/services/update_config.dart';
import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum UpdateStatus { none, ready, toDownload, required }

@immutable
class LauncherUpdate {
  final UpdateStatus status;

  /// The new version, once one is known.
  final String? version;

  /// macOS and Linux: the installer the "Download" button opens.
  final Uri? downloadUrl;

  /// A required update on Windows: how much is downloaded (0 to 1), `null`
  /// before the first bytes.
  final double? progress;

  /// A required update failed to download or install; "Retry" tries again.
  final bool failed;

  const LauncherUpdate(
    this.status, {
    this.version,
    this.downloadUrl,
    this.progress,
    this.failed = false,
  });

  static const none = LauncherUpdate(UpdateStatus.none);

  /// The release's page on GitHub, for "What's new".
  Uri? get notesUrl => version == null
      ? null
      : Uri.parse(
          "https://github.com/elRubenof/bc-launcher/releases/tag/v$version",
        );
}

/// The parts of `desktop_updater`'s controller the service uses, so tests can
/// replace it.
abstract interface class UpdateBackend implements Listenable {
  UpdateState get state;
  Future<void> checkVersion();
  Future<void> downloadUpdate();
  Future<void> restartApp();
}

class _ControllerBackend implements UpdateBackend {
  final DesktopUpdaterController controller;

  _ControllerBackend(this.controller);

  @override
  UpdateState get state => controller.state;
  @override
  Future<void> checkVersion() => controller.checkVersion();
  @override
  Future<void> downloadUpdate() => controller.downloadUpdate();
  @override
  Future<void> restartApp() => controller.restartApp();
  @override
  void addListener(VoidCallback listener) => controller.addListener(listener);
  @override
  void removeListener(VoidCallback listener) =>
      controller.removeListener(listener);
}

/// The launcher's own update, from this repo's GitHub Releases only.
///
/// It checks when it starts and every 6 hours. Windows downloads a new
/// version in the background and installs it on "Restart", never while the
/// game runs. macOS and Linux only say there is one: their releases are a
/// fresh download (`freshInstall`). A version past its `supportPolicy` makes
/// the update required.
class UpdateService {
  static const checkEvery = Duration(hours: 6);
  static const releasesUrl =
      "https://github.com/elRubenof/bc-launcher/releases/latest";

  /// The running launcher's service, once [start] has run.
  static UpdateService? current;

  final UpdateBackend backend;

  /// Whether this platform installs updates itself (Windows).
  final bool installs;

  /// Whether the game is running; the launcher never restarts meanwhile.
  final ValueListenable<bool> playing;

  final Future<void> Function(Uri url) _openUrl;

  final update = ValueNotifier<LauncherUpdate>(LauncherUpdate.none);

  /// The notice was closed; it comes back on the next start.
  final dismissed = ValueNotifier<bool>(false);

  /// The update must be installed now, from [UpdateBackend]'s policy or
  /// because [updateNow] was asked.
  bool _required = false;
  bool _restartWhenFree = false;
  String? _version;
  Timer? _timer;

  UpdateService({
    required this.backend,
    required this.installs,
    required this.playing,
    Future<void> Function(Uri url)? openUrl,
  }) : _openUrl = openUrl ?? _launch {
    backend.addListener(_onBackend);
    playing.addListener(_onPlaying);
  }

  /// Creates the service with `desktop_updater`, which checks right away.
  static Future<void> start({required ValueListenable<bool> playing}) async {
    if (current != null) return;
    try {
      final controller = DesktopUpdaterController(
        appArchiveUrl: UpdateConfig.appArchiveUrl,
        expectedPackageId: UpdateConfig.packageId,
        trustedReleasePublicKeys: UpdateConfig.trustedReleasePublicKeys,
        recoveryStore: await UpdateConfig.recoveryStore(),
      );
      current = UpdateService(
        backend: _ControllerBackend(controller),
        installs: Platform.isWindows,
        playing: playing,
      ).._schedule();
    } catch (e) {
      log("The update service could not start: $e");
    }
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer.periodic(checkEvery, (_) => check());
  }

  /// Looks for a new version, unless one is already downloaded or required
  /// (checking again would drop what is staged). Failures stay quiet.
  Future<void> check() async {
    final status = update.value.status;
    if (status == UpdateStatus.ready || status == UpdateStatus.required) {
      return;
    }
    try {
      await backend.checkVersion();
    } catch (e) {
      log("The update check failed: $e");
    }
  }

  /// "Restart": installs the downloaded update, never while playing.
  Future<void> restart() async {
    if (playing.value || backend.state is! UpdateReadyToInstall) return;
    try {
      await backend.restartApp();
    } catch (e) {
      log("The update could not be installed: $e");
      if (_required) _publishRequired(failed: true);
    }
  }

  /// "Update the launcher" from an organization that needs a newer one: on
  /// Windows the required update; elsewhere the download opens.
  Future<void> updateNow() async {
    if (!installs) {
      await download();
      return;
    }
    _required = true;
    _publishRequired();
    final state = backend.state;
    if (state is UpdateReadyToInstall) {
      _installWhenFree();
    } else if (state is UpdateAvailable ||
        state is UpdateBlockedBySupportPolicy) {
      await _download();
    } else if (state is! UpdateDownloading) {
      await retry();
    }
  }

  /// "Retry" on a required update that failed: checks again and downloads.
  Future<void> retry() async {
    _publishRequired();
    try {
      await backend.checkVersion();
    } catch (e) {
      log("The update check failed: $e");
    }
  }

  /// "Download": opens the release's installer, or the releases page.
  Future<void> download() =>
      _openUrl(update.value.downloadUrl ?? Uri.parse(releasesUrl));

  void dismiss() => dismissed.value = true;

  void dispose() {
    _timer?.cancel();
    backend.removeListener(_onBackend);
    playing.removeListener(_onPlaying);
  }

  void _onBackend() {
    switch (backend.state) {
      case UpdateIdle():
        // Required with no newer version published: nothing to install yet.
        if (_required) {
          _publishRequired(failed: true);
        } else {
          update.value = LauncherUpdate.none;
        }
      case UpdateChecking() || UpdateInstalling():
        break;
      case UpdateAvailable(:final descriptor, :final mandatory):
        _version = descriptor.version;
        if (mandatory) _required = true;
        if (installs) {
          if (_required) _publishRequired();
          unawaited(_download());
        } else {
          _publishDownload(Uri.parse(releasesUrl));
        }
      case UpdateFreshInstallRequired(
        :final descriptor,
        :final freshInstall,
        :final mandatory,
      ):
        _version = descriptor.version;
        if (mandatory) _required = true;
        _publishDownload(freshInstall.downloadUrl);
      case UpdateBlockedBySupportPolicy(:final descriptor, :final freshInstall):
        _version = descriptor.version;
        _required = true;
        if (installs && freshInstall == null) {
          _publishRequired();
          unawaited(_download());
        } else {
          _publishDownload(freshInstall?.downloadUrl ?? Uri.parse(releasesUrl));
        }
      case UpdateDownloading(:final receivedBytes, :final totalBytes):
        if (_required) {
          _publishRequired(
            progress: totalBytes > 0 ? receivedBytes / totalBytes : null,
          );
        }
      case UpdateReadyToInstall():
        if (_required) {
          _publishRequired(progress: 1);
          _installWhenFree();
        } else {
          update.value = LauncherUpdate(UpdateStatus.ready, version: _version);
        }
      case UpdateFailed(:final error):
        log("The launcher update failed: $error");
        if (_required) {
          _publishRequired(failed: true);
        } else if (update.value.status != UpdateStatus.toDownload) {
          update.value = LauncherUpdate.none;
        }
    }
  }

  Future<void> _download() async {
    try {
      await backend.downloadUpdate();
    } catch (e) {
      // The backend's state already says it failed.
      log("The update could not be downloaded: $e");
    }
  }

  void _installWhenFree() {
    if (playing.value) {
      _restartWhenFree = true;
    } else {
      unawaited(restart());
    }
  }

  void _onPlaying() {
    if (!playing.value && _restartWhenFree) {
      _restartWhenFree = false;
      unawaited(restart());
    }
  }

  void _publishDownload(Uri url) {
    update.value = LauncherUpdate(
      _required ? UpdateStatus.required : UpdateStatus.toDownload,
      version: _version,
      downloadUrl: url,
    );
  }

  void _publishRequired({double? progress, bool failed = false}) {
    update.value = LauncherUpdate(
      UpdateStatus.required,
      version: _version,
      progress: progress,
      failed: failed,
    );
  }

  static Future<void> _launch(Uri url) async {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
