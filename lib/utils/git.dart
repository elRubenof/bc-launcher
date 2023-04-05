import 'dart:developer';

import 'package:simple_git/simple_git.dart';

class Git {
  static const String _gitPath =
      "C:/Users/Tony/Documents/Development/.minecraft/mods";

  static SimpleGit _gitSync = SimpleGit(
    options: SimpleGitOptions(
      showOutput: true,
      binary: 'git',
      baseDir: _gitPath,
    ),
  );

  static SimpleGitAsync _gitAsync = SimpleGitAsync(
    options: SimpleGitOptions(
      showOutput: true,
      binary: 'git',
      baseDir: _gitPath,
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
    try {
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
