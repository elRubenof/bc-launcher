import 'dart:developer';
import 'dart:io';

import 'package:launcher/utils/data.dart';
import 'package:simple_git/simple_git.dart';

class Git {
  static final SimpleGit _gitSync = SimpleGit(
    options: SimpleGitOptions(
      showOutput: true,
      binary: 'git',
      baseDir: "$minecraftPath/mods",
    ),
  );

  static final SimpleGitAsync _gitAsync = SimpleGitAsync(
    options: SimpleGitOptions(
      showOutput: true,
      binary: 'git',
      baseDir: "$minecraftPath/mods",
    ),
  );

  static bool _hasChanges() {
    var result = _gitSync.status();

    return !result.resultMessage
        .contains("nothing to commit, working tree clean");
  }

  static Future<void> _update() async {
    await _gitAsync.pull();

    log("ACTUALIZADO");
  }

  static Future<String> init() async {
    if (!Platform.isWindows) return "Success";

    try {
      await Directory("$minecraftPath/mods").create();

      if (_hasChanges()) {
        await _gitAsync.raw(['restore', '.'], showOutput: true);
        await _gitAsync.raw(['clean', '-f', '-x'], showOutput: true);

        log("Corregidos cambios en el repo");
      }

      await _update();
    } catch (e) {
      return e.toString();
    }

    return "Success";
  }
}
