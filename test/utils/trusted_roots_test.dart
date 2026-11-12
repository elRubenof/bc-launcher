import 'dart:io';

import 'package:bc_launcher/utils/trusted_roots.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final bundle = File(TrustedRoots.asset).readAsBytesSync();

  test('the bundle is a valid PEM with roots', () {
    final text = String.fromCharCodes(bundle);
    expect('BEGIN CERTIFICATE'.allMatches(text).length, greaterThan(100));
    expect(
      () => TrustedRoots.add(SecurityContext(withTrustedRoots: false), bundle),
      returnsNormally,
    );
  });

  test('adding it over the system roots keeps the duplicates quiet', () {
    expect(
      () => TrustedRoots.add(SecurityContext(withTrustedRoots: true), bundle),
      returnsNormally,
    );
  });
}
