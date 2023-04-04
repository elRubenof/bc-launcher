import 'dart:developer';
import 'dart:io';

import 'package:simple_git/simple_git.dart';

class Git {
  static var options = SimpleGitOptions(
    showOutput: true,
    binary: 'git',
    baseDir: "${Directory.current.path}/.minecraft/mods",
  );

  static Future<void> test() async {
    var git = SimpleGitAsync(options: options);

    log(Directory.current.path);
    Directory directory =
        Directory("${Directory.current.path}/.minecraft/mods");
    await directory.create();

    var result = await git.status();
    log('[STATUS]: ${result.resultMessage}');
  }
}
