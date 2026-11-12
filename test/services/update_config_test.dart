import 'dart:convert';
import 'dart:io';

import 'package:bc_launcher/services/update_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final profile = jsonDecode(
    File("desktop_updater.keys.json").readAsStringSync(),
  ) as Map<String, dynamic>;

  test("the pinned keys are the release key profile's", () {
    expect(UpdateConfig.trustedReleasePublicKeys, profile['publicKeys']);
  });

  test("the feed is the one the release key is bound to", () {
    expect(UpdateConfig.appArchiveUrl.toString(), profile['feedUrl']);
  });
}
