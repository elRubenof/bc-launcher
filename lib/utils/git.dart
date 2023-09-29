import 'dart:developer';
import 'dart:io';

import 'package:launcher/utils/data.dart';
import 'package:simple_git/simple_git.dart';

class Git {
  static bool _hasChanges(SimpleGit gitSync) {
    var result = gitSync.status();

    return !result.resultMessage
        .contains("nothing to commit, working tree clean");
  }

  static Future<void> _update(SimpleGitAsync gitAsync) async {
    await gitAsync.pull();
  }

  static Future<String> init() async {
    if (!await initRepo("mods")) return "Failure mods";
    if (!await initRepo("resourcepacks")) return "Failure resourcepacks";

    return "Success";
  }

  static Future<bool> initRepo(String repo, {bool secondTry = false}) async {
    bool created = false;

    Directory repoDir = Directory("$minecraftPath/$repo");
    if (!await repoDir.exists()) {
      await repoDir.create();
      created = true;
    }

    final SimpleGit gitSync = SimpleGit(
      options: SimpleGitOptions(
        showOutput: true,
        binary: 'git',
        baseDir: "$minecraftPath/$repo",
      ),
    );

    final SimpleGitAsync gitAsync = SimpleGitAsync(
      options: SimpleGitOptions(
        showOutput: true,
        binary: 'git',
        baseDir: "$minecraftPath/$repo",
      ),
    );

    try {
      if (created) await _create(gitAsync, repo);

      if (_hasChanges(gitSync)) {
        await gitAsync.raw(['restore', '.'], showOutput: true);
        await gitAsync.raw(['clean', '-f', '-x', '-d'], showOutput: true);

        log("Corregidos cambios en $repo");
      }

      await _update(gitAsync);
    } catch (e) {
      if (secondTry) return false;

      await repoDir.delete(recursive: true);
      return await initRepo(repo, secondTry: true);
    }

    return true;
  }

  static Future<void> _create(SimpleGitAsync gitAsync, String repo) async {
    await gitAsync.raw(['init'], showOutput: true);
    await gitAsync.raw(
        ['remote', 'add', 'origin', 'https://github.com/elRubenof/$repo.git'],
        showOutput: true);
    try {
      await _update(gitAsync);
    } catch (e) {}
    await gitAsync.raw(['checkout', 'main'], showOutput: true);
    await _update(gitAsync);
  }

  static Future<void> donwloadMinecraft() async {
    final SimpleGitAsync gitAsync = SimpleGitAsync(
      options: SimpleGitOptions(
        showOutput: true,
        binary: 'git',
        baseDir: minecraftPath,
      ),
    );

    await _create(gitAsync, "minecraft");
  }
}
