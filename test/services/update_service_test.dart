import 'package:bc_launcher/services/update_service.dart';
import 'package:desktop_updater/desktop_updater.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

/// `desktop_updater`'s controller: the test moves its state and sees calls.
class FakeBackend extends ChangeNotifier implements UpdateBackend {
  UpdateState _state = const UpdateIdle();
  int checks = 0, downloads = 0;

  /// What a check or a download does next, if anything.
  UpdateState? onCheck, onDownload;

  @override
  UpdateState get state => _state;

  void emit(UpdateState state) {
    _state = state;
    notifyListeners();
  }

  @override
  Future<void> checkVersion() async {
    checks++;
    emit(const UpdateChecking());
    emit(onCheck ?? const UpdateIdle());
  }

  @override
  Future<void> downloadUpdate() async {
    downloads++;
    if (onDownload != null) emit(onDownload!);
  }
}

ReleaseDescriptor release(String version, {String platform = "windows"}) =>
    ReleaseDescriptor(
      schemaVersion: 3,
      packageId: "bc_launcher",
      appName: "BC Launcher",
      version: version,
      buildNumber: null,
      platform: platform,
      channel: "stable",
      artifact: ReleaseArtifact(
        kind: "zip",
        url: Uri.parse("https://example.com/app.zip"),
        sha256: "",
        length: 1,
      ),
      install: const ReleaseInstall(strategy: "wholeDirectoryReplace"),
      minimumUpdaterVersion: "3.1.0",
      generatedAt: DateTime.utc(2026, 11, 8),
    );

final policy = ReleaseSupportPolicy(
  minimumSupportedVersion: "1.2.0",
  enforcedAfter: DateTime.utc(2026, 11, 1),
);

void main() {
  late FakeBackend backend;
  late ValueNotifier<bool> playing;
  late List<Uri> opened;

  /// The staging folders whose installer was run.
  late List<String> installed;

  /// What running the installer throws, if anything.
  Object? installError;

  UpdateService service({required bool installs}) => UpdateService(
    backend: backend,
    installs: installs,
    playing: playing,
    openUrl: (url) async => opened.add(url),
    install: (stagingPath) async {
      if (installError != null) throw installError!;
      installed.add(stagingPath);
    },
  );

  setUp(() {
    backend = FakeBackend();
    playing = ValueNotifier(false);
    opened = [];
    installed = [];
    installError = null;
  });

  group("Windows", () {
    test("a new version downloads quietly and then is ready", () {
      final updates = service(installs: true);
      backend.onDownload = const UpdateDownloading(
        receivedBytes: 5,
        totalBytes: 10,
      );

      backend.emit(
        UpdateAvailable(descriptor: release("1.2.0"), mandatory: false),
      );
      expect(backend.downloads, 1);
      expect(updates.update.value.status, UpdateStatus.none);

      backend.emit(const UpdateReadyToInstall(stagingPath: "stage"));
      expect(updates.update.value.status, UpdateStatus.ready);
      expect(updates.update.value.version, "1.2.0");
      expect(
        updates.update.value.notesUrl.toString(),
        "https://github.com/elRubenof/bc-launcher/releases/tag/v1.2.0",
      );
    });

    test("restart runs the downloaded installer, but never while the game "
        "runs", () async {
      final updates = service(installs: true);
      backend.emit(
        UpdateAvailable(descriptor: release("1.2.0"), mandatory: false),
      );
      backend.emit(const UpdateReadyToInstall(stagingPath: "stage"));

      playing.value = true;
      await updates.restart();
      expect(installed, isEmpty);

      playing.value = false;
      await updates.restart();
      expect(installed, ["stage"]);
    });

    test("an installer that can't run becomes a download", () async {
      final updates = service(installs: true);
      installError = StateError("no installer");
      backend.emit(
        UpdateAvailable(descriptor: release("1.2.0"), mandatory: false),
      );
      backend.emit(const UpdateReadyToInstall(stagingPath: "stage"));

      await updates.restart();
      expect(updates.update.value.status, UpdateStatus.toDownload);
      expect(updates.update.value.version, "1.2.0");

      await updates.download();
      expect(opened.single.toString(), UpdateService.releasesUrl);
    });

    test("a required update whose installer can't run fails", () async {
      final updates = service(installs: true);
      installError = StateError("no installer");
      backend.emit(
        UpdateBlockedBySupportPolicy(
          descriptor: release("1.2.0"),
          supportPolicy: policy,
        ),
      );
      backend.emit(const UpdateReadyToInstall(stagingPath: "stage"));
      await pumpEventQueue();

      expect(updates.update.value.status, UpdateStatus.required);
      expect(updates.update.value.failed, isTrue);
    });

    test("a downloaded update is not checked again", () async {
      final updates = service(installs: true);
      backend.emit(
        UpdateAvailable(descriptor: release("1.2.0"), mandatory: false),
      );
      backend.emit(const UpdateReadyToInstall(stagingPath: "stage"));

      await updates.check();
      expect(backend.checks, 0);
    });

    test("a failed check or download stays quiet", () {
      final updates = service(installs: true);
      backend.emit(UpdateFailed(Exception("offline")));
      expect(updates.update.value.status, UpdateStatus.none);
    });

    test("an unsupported version is required, with progress, and restarts "
        "by itself", () {
      final updates = service(installs: true);
      backend.emit(
        UpdateBlockedBySupportPolicy(
          descriptor: release("1.2.0"),
          supportPolicy: policy,
        ),
      );
      expect(backend.downloads, 1);
      expect(updates.update.value.status, UpdateStatus.required);
      expect(updates.update.value.progress, isNull);
      expect(updates.update.value.unsupported, isTrue);

      backend.emit(const UpdateDownloading(receivedBytes: 45, totalBytes: 100));
      expect(updates.update.value.progress, 0.45);

      backend.emit(const UpdateReadyToInstall(stagingPath: "stage"));
      expect(installed, ["stage"]);
    });

    test("a required update waits for the game to close", () {
      service(installs: true);
      playing.value = true;
      backend.emit(
        UpdateBlockedBySupportPolicy(
          descriptor: release("1.2.0"),
          supportPolicy: policy,
        ),
      );
      backend.emit(const UpdateReadyToInstall(stagingPath: "stage"));
      expect(installed, isEmpty);

      playing.value = false;
      expect(installed, ["stage"]);
    });

    test("a required update that fails can be retried", () async {
      final updates = service(installs: true);
      backend.emit(
        UpdateBlockedBySupportPolicy(
          descriptor: release("1.2.0"),
          supportPolicy: policy,
        ),
      );
      backend.emit(UpdateFailed(Exception("offline")));
      expect(updates.update.value.status, UpdateStatus.required);
      expect(updates.update.value.failed, isTrue);

      backend.onCheck = UpdateBlockedBySupportPolicy(
        descriptor: release("1.2.0"),
        supportPolicy: policy,
      );
      await updates.retry();
      expect(backend.checks, 1);
      expect(backend.downloads, 2);
      expect(updates.update.value.failed, isFalse);
    });

    test(
      "updating for an organization turns a ready update into a restart",
      () async {
        final updates = service(installs: true);
        backend.emit(
          UpdateAvailable(descriptor: release("1.2.0"), mandatory: false),
        );
        backend.emit(const UpdateReadyToInstall(stagingPath: "stage"));

        await updates.updateNow();
        expect(updates.update.value.status, UpdateStatus.required);
        expect(installed, ["stage"]);
      },
    );

    test("updating for an organization checks and downloads", () async {
      final updates = service(installs: true);
      backend.onCheck = UpdateAvailable(
        descriptor: release("1.3.0"),
        mandatory: false,
      );

      await updates.updateNow();
      expect(backend.checks, 1);
      expect(backend.downloads, 1);
      expect(updates.update.value.status, UpdateStatus.required);
      expect(updates.update.value.version, "1.3.0");
      expect(updates.update.value.unsupported, isFalse);
    });

    test("updating for an organization with nothing newer fails", () async {
      final updates = service(installs: true);
      await updates.updateNow();

      expect(updates.update.value.status, UpdateStatus.required);
      expect(updates.update.value.failed, isTrue);
    });
  });

  group("macOS and Linux", () {
    final dmg = Uri.parse(
      "https://github.com/elRubenof/bc-launcher/releases/download/v1.2.0/BC-Launcher.dmg",
    );

    test("a new version is to download from its installer", () async {
      final updates = service(installs: false);
      backend.emit(
        UpdateFreshInstallRequired(
          descriptor: release("1.2.0", platform: "macos"),
          freshInstall: ReleaseFreshInstall(downloadUrl: dmg),
          mandatory: false,
        ),
      );

      expect(updates.update.value.status, UpdateStatus.toDownload);
      expect(updates.update.value.version, "1.2.0");
      expect(backend.downloads, 0);

      await updates.download();
      expect(opened, [dmg]);
    });

    test("an unsupported version is required, still a download", () {
      final updates = service(installs: false);
      backend.emit(
        UpdateBlockedBySupportPolicy(
          descriptor: release("1.2.0", platform: "linux"),
          supportPolicy: policy,
          freshInstall: ReleaseFreshInstall(downloadUrl: dmg),
        ),
      );

      expect(updates.update.value.status, UpdateStatus.required);
      expect(updates.update.value.downloadUrl, dmg);
      expect(backend.downloads, 0);
    });

    test("a release without an installer opens the releases page", () async {
      final updates = service(installs: false);
      backend.emit(
        UpdateAvailable(
          descriptor: release("1.2.0", platform: "macos"),
          mandatory: false,
        ),
      );
      expect(updates.update.value.status, UpdateStatus.toDownload);

      await updates.download();
      expect(opened.single.toString(), UpdateService.releasesUrl);
    });

    test("updating for an organization opens the download", () async {
      final updates = service(installs: false);
      await updates.updateNow();

      expect(opened.single.toString(), UpdateService.releasesUrl);
      expect(backend.checks, 0);
    });
  });

  test("closing the notice lasts until the next start", () {
    final updates = service(installs: true);
    updates.dismiss();
    expect(updates.dismissed.value, isTrue);
    expect(service(installs: true).dismissed.value, isFalse);
  });
}
