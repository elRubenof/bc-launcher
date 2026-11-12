import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Mozilla's root certificates, bundled with the launcher.
///
/// On Windows, Dart only trusts the roots already in the system store, and
/// Windows downloads missing ones only when an app verifies through it (Dart
/// doesn't). A server whose root a player's Windows hasn't fetched yet, like
/// SSL.com's on Cloudflare, would fail with `CERTIFICATE_VERIFY_FAILED`.
/// Update `assets/certs/cacert.pem` from https://curl.se/ca/cacert.pem before
/// each release.
class TrustedRoots {
  static const asset = 'assets/certs/cacert.pem';

  /// Adds the bundled roots to every HTTP client of this isolate that uses
  /// the default context (`Image.network`, Dio). Only needed on Windows.
  static Future<void> load() async {
    if (!Platform.isWindows) return;
    try {
      final data = await rootBundle.load(asset);
      add(SecurityContext.defaultContext, data.buffer.asUint8List());
    } catch (e) {
      // The system's roots still work; only the missing ones would fail.
      debugPrint('Could not load the bundled root certificates: $e');
    }
  }

  /// Adds the PEM [bundle] to [context]'s trusted roots.
  static void add(SecurityContext context, Uint8List bundle) =>
      context.setTrustedCertificatesBytes(bundle);
}
