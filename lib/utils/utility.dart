import 'dart:developer';
import 'dart:io';

import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:git2dart/git2dart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utility {
  static final key = GlobalKey<NavigatorState>();

  static ValueNotifier<bool> isLoading = ValueNotifier(false);
  static ValueNotifier<String> loadingState = ValueNotifier("");
  static late Directory minecraftDirectory;

  static AppLocalizations getLocalizations(BuildContext context) {
    return AppLocalizations.of(context)!;
  }

  static Future<void> init() async {
    Utility.isLoading.value = true;

    await loadSettings();
    await loadFiles();

    Utility.isLoading.value = false;
  }

  static Future<void> loadSettings() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    Settings.autoConnect = preferences.getBool("autoConnect") ?? false;
  }

  static Future<void> loadFiles() async {
    final supportDirectory = await getApplicationSupportDirectory();
    minecraftDirectory = Directory("${supportDirectory.path}/.minecraft");

    if (!minecraftDirectory.existsSync()) {
      await minecraftDirectory.create();
    }

    if (Constants.modsRepo.isNotEmpty) await sincMods();
  }

  static Future<void> setAutoConnect(bool value) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setBool("autoConnect", value);
    Settings.autoConnect = value;
  }

  static Future<void> sincMods() async {
    final l = Utility.getLocalizations(key.currentContext!);
    loadingState.value = l.syncMods;

    Directory modsDir = Directory("${minecraftDirectory.path}/mods");
    if (await modsDir.exists()) {
      Repository repo;

      try {
        repo = Repository.open(modsDir.path);
      } catch (e) {
        await Utility.minecraftDirectory.delete(recursive: true);
        await Utility.sincMods();

        return;
      }

      //DELETES NEW / MODIFIED FILES
      for (String key in repo.status.keys) {
        try {
          if (repo.status[key]!.first != GitStatus.indexDeleted) {
            File("${modsDir.path}/$key").deleteSync();
            log("Deleted mod: $key");
          }
        } catch (e) {
          log("Error deleting mod: $key");
        }
      }

      //RECOVER LOCAL HEAD FILES
      repo.reset(oid: repo.headCommit.oid, resetType: GitReset.hard);

      //GET NEW CHANGES
      final remote = Remote.lookup(repo: repo, name: "origin");
      remote.fetch();

      Merge.commit(
        repo: repo,
        commit: AnnotatedCommit.fromReference(
          repo: repo,
          reference: Reference.lookup(
            repo: repo,
            name: 'refs/remotes/origin/main',
          ),
        ),
      );
    } else {
      await compute<Directory, void>(cloneRepo, modsDir);
    }
  }

  static void cloneRepo(Directory modsDir) {
    Repository.clone(url: Constants.modsRepo, localPath: modsDir.path);
  }
}
