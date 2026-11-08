import 'dart:io';

import 'package:bc_launcher/services/update_recovery_store.dart';
import 'package:desktop_updater/updater_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late UpdateRecoveryFileStore store;

  final marker = UpdateInstallRecoveryMarker(
    createdAt: DateTime.utc(2026, 11, 8, 12),
    packageVersion: "3.2.11",
    platform: "windows",
    channel: "stable",
    appVersion: "1.1.0",
    updateVersion: "1.2.0",
    expectedPackageId: "bc_launcher",
    stagingPath: r"C:\stage",
    transactionId: "0b9b1c7e-3f43-4a52-9d1c-2f3c4a5b6c7d",
  );

  setUp(() async {
    dir = await Directory.systemTemp.createTemp("recovery_store_test");
    store = UpdateRecoveryFileStore(File("${dir.path}/update/pending.json"));
  });

  tearDown(() => dir.delete(recursive: true));

  test("nothing is pending without a file", () async {
    expect(await store.readPendingInstall(channel: "stable"), isNull);
  });

  test("a written marker is read back as it was", () async {
    await store.writePendingInstall(marker);
    final read = await store.readPendingInstall(channel: "stable");

    expect(read, isNotNull);
    expect(read!.createdAt, marker.createdAt);
    expect(read.packageVersion, "3.2.11");
    expect(read.platform, "windows");
    expect(read.appVersion, "1.1.0");
    expect(read.updateVersion, "1.2.0");
    expect(read.updateBuildNumber, isNull);
    expect(read.expectedPackageId, "bc_launcher");
    expect(read.stagingPath, r"C:\stage");
    expect(read.transactionId, marker.transactionId);
  });

  test(
    "writing again replaces the marker and leaves no temporary files",
    () async {
      await store.writePendingInstall(marker);
      await store.writePendingInstall(
        UpdateInstallRecoveryMarker(
          createdAt: DateTime.utc(2026, 11, 9),
          packageVersion: "3.2.11",
          platform: "windows",
          channel: "stable",
          updateVersion: "1.3.0",
        ),
      );

      final read = await store.readPendingInstall(channel: "stable");
      expect(read!.updateVersion, "1.3.0");
      expect(store.file.parent.listSync(), hasLength(1));
    },
  );

  test("a marker of another channel is not pending here", () async {
    await store.writePendingInstall(marker);
    expect(await store.readPendingInstall(channel: "beta"), isNull);

    await store.clearPendingInstall(channel: "beta");
    expect(await store.file.exists(), isTrue);
  });

  test("clearing deletes the marker", () async {
    await store.writePendingInstall(marker);
    await store.clearPendingInstall(channel: "stable");

    expect(await store.file.exists(), isFalse);
    expect(await store.readPendingInstall(channel: "stable"), isNull);
  });

  test("a broken file is an error, not a missing marker", () async {
    await store.file.parent.create(recursive: true);
    await store.file.writeAsString('{"platform": "windows"}');

    expect(
      () => store.readPendingInstall(channel: "stable"),
      throwsFormatException,
    );
  });
}
