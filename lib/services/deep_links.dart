import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

class DeepLinks {
  static const scheme = "bclauncher";

  /// The server of the last link, waiting for the player
  /// to confirm it. The UI sets it back to `null` once handled.
  static final pendingAdd = ValueNotifier<String?>(null);

  static StreamSubscription<Uri>? _subscription;

  /// Starts listening, the link that opened the launcher included. Call it
  /// before `runApp` so that first link isn't missed.
  static void listen() {
    _subscription ??= AppLinks().uriLinkStream.listen((uri) {
      final server = parseAdd(uri);
      if (server == null) {
        log("Ignoring link: $uri");
        return;
      }
      pendingAdd.value = server;
    });
  }

  /// The server address of an "add organization" link, or `null` for any
  /// other link. `https://` is added when the address has no scheme.
  static String? parseAdd(Uri uri) {
    if (uri.scheme != scheme || uri.host != "add") return null;

    final server = uri.queryParameters['server'];
    if (server == null || server.trim().isEmpty) return null;

    final url = ApiClient.normalizeUrl(server);
    final parsed = Uri.tryParse(url);
    if (parsed == null ||
        !(parsed.scheme == "https" || parsed.scheme == "http") ||
        parsed.host.isEmpty) {
      return null;
    }
    return url;
  }

  /// Makes this launcher the handler of `bclauncher://` links on Windows
  /// and Linux. macOS reads it from the app's `Info.plist`.
  static Future<void> register() async {
    try {
      if (Platform.isWindows) await _registerWindows();
      if (Platform.isLinux) await _registerLinux();
    } catch (e) {
      log("Could not register the $scheme scheme: $e");
    }
  }

  /// Per-user registry keys, so no admin rights are needed.
  static Future<void> _registerWindows() async {
    const key = r"HKCU\Software\Classes\" + scheme;
    final command = '"${Platform.resolvedExecutable}" "%1"';

    for (final args in [
      [key, "/ve", "/d", "URL:BC Launcher", "/f"],
      [key, "/v", "URL Protocol", "/d", "", "/f"],
      ["$key\\shell\\open\\command", "/ve", "/d", command, "/f"],
    ]) {
      final result = await Process.run("reg", ["add", ...args]);
      if (result.exitCode != 0) throw "reg add failed: ${result.stderr}";
    }
  }

  /// A desktop entry for the scheme in the user's applications folder.
  static Future<void> _registerLinux() async {
    const fileName = "com.bcr.bc_launcher.desktop";
    final home = Platform.environment['HOME'];
    if (home == null) return;

    // Use $APPIMAGE if running as an AppImage, otherwise the resolved executable.
    final executable =
        Platform.environment['APPIMAGE'] ?? Platform.resolvedExecutable;

    // Install the app icon into ~/.local/share/icons if bundled with the app.
    try {
      final appDir = File(Platform.resolvedExecutable).parent.path;
      final bundledIcon = File(join(appDir, "com.bcr.bc_launcher.png"));
      if (await bundledIcon.exists()) {
        final targetIcon = File(join(
          home,
          ".local",
          "share",
          "icons",
          "hicolor",
          "512x512",
          "apps",
          "com.bcr.bc_launcher.png",
        ));
        if (!await targetIcon.exists()) {
          await targetIcon.parent.create(recursive: true);
          await bundledIcon.copy(targetIcon.path);
        }
      }
    } catch (_) {
      // Best-effort icon installation.
    }

    final file = File(join(home, ".local", "share", "applications", fileName));
    await file.parent.create(recursive: true);
    await file.writeAsString(
      "[Desktop Entry]\n"
      "Type=Application\n"
      "Name=BC Launcher\n"
      "Comment=A customizable Minecraft launcher\n"
      "Exec=\"$executable\" %u\n"
      "Icon=com.bcr.bc_launcher\n"
      "Terminal=false\n"
      "Categories=Game;\n"
      "StartupWMClass=com.bcr.bc_launcher\n"
      "MimeType=x-scheme-handler/$scheme;\n",
    );

    await Process.run("xdg-mime", [
      "default",
      fileName,
      "x-scheme-handler/$scheme",
    ]);
  }
}
