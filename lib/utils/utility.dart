import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:auto_update/auto_update.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/settings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:git2dart/git2dart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Utility {
  static final key = GlobalKey<NavigatorState>();

  static ValueNotifier<bool> isLoading = ValueNotifier(false);
  static ValueNotifier<String> loadingState = ValueNotifier("");
  static ValueNotifier<bool> isLaunching = ValueNotifier(false);
  static ValueNotifier<List> news = ValueNotifier([]);

  static AppLocalizations getLocalizations(BuildContext context) {
    return AppLocalizations.of(context)!;
  }

  static Future<void> init() async {
    Utility.isLoading.value = true;

    await Minecraft.authenticateOauth2();
    await loadFiles();
    await loadNews();

    Utility.isLoading.value = false;
  }

  static Future<void> loadSettings() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    Settings.autoConnect =
        preferences.getBool("autoConnect") ?? Constants.defaultAutoConnect;
    Settings.allocatedRAM =
        preferences.getInt("allocatedRAM") ?? Constants.defaultAllocatedRAM;
    Settings.gameWidth =
        preferences.getInt("gameWidth") ?? Constants.defaultGameWidth;
    Settings.gameHeight =
        preferences.getInt("gameHeight") ?? Constants.defaultGameHeight;
    Settings.fullscreen =
        preferences.getBool("fullscreen") ?? Constants.defaultFullscreen;
  }

  static Future<void> resetSettings() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    Settings.autoConnect = Constants.defaultAutoConnect;
    Settings.allocatedRAM = Constants.defaultAllocatedRAM;
    Settings.gameWidth = Constants.defaultGameWidth;
    Settings.gameHeight = Constants.defaultGameHeight;
    Settings.fullscreen = Constants.defaultFullscreen;

    preferences.remove("autoConnect");
    preferences.remove("allocatedRAM");
    preferences.remove("gameWidth");
    preferences.remove("gameHeight");
    preferences.remove("fullscreen");
  }

  static Future<void> loadFiles() async {
    await checkInstallation();
    await sincFiles();
  }

  static Future<void> checkInstallation() async {
    final supportDirectory = await getApplicationSupportDirectory();
    Settings.minecraftDirectory = Directory(
      "${supportDirectory.path}${Platform.isWindows ? r'\' : '/'}minecraft",
    );

    if (!Settings.minecraftDirectory.existsSync()) {
      final l = Utility.getLocalizations(key.currentContext!);
      Utility.loadingState.value = l.installingMinecraft;

      await compute<String, void>(
        cloneRepo,
        json.encode(
          {
            "url": Constants.minecraftRepo,
            "path": Settings.minecraftDirectory.path,
          },
        ),
      );
    }
  }

  static Future<void> sincFiles({bool force = false}) async {
    await sincRepo(Constants.modsRepo, force);
    await sincRepo(Constants.configRepo, force);
    await sincRepo(Constants.resourcePacksRepo, force);
  }

  static Future<void> loadNews() async {
    if (Constants.newsRepo.isEmpty) return;

    try {
      final response = await http.get(Uri.parse(Constants.newsRepo));
      news.value = json.decode(utf8.decode(response.bodyBytes));
    } catch (e) {
      return;
    }
  }

  static Future<void> setAutoConnect(bool value) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setBool("autoConnect", value);
    Settings.autoConnect = value;
  }

  static Future<void> sincRepo(String repoUrl, bool force) async {
    final name = repoUrl.split('/').last.replaceAll(".git", "");
    Directory repoDir = Directory("${Settings.minecraftDirectory.path}/$name");

    if (repoDir.existsSync() && (repoUrl.isEmpty || (isAdmin() && !force))) {
      return;
    }

    final l = Utility.getLocalizations(key.currentContext!);
    loadingState.value = "${l.syncing} $name";
    if (await repoDir.exists()) {
      Repository repo;

      try {
        repo = Repository.open(repoDir.path);
      } catch (e) {
        await Settings.minecraftDirectory.delete(recursive: true);
        await Utility.sincRepo(repoUrl, force);

        return;
      }

      //DELETES NEW / MODIFIED FILES
      for (String key in repo.status.keys) {
        try {
          if (repo.status[key]!.first != GitStatus.indexDeleted) {
            File("${repoDir.path}/$key").deleteSync();
            log("Deleted file: $key");
          }
        } catch (e) {
          log("Error deleting file: $key");
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
      await compute<String, void>(
        cloneRepo,
        json.encode(
          {
            "url": repoUrl,
            "path": repoDir.path,
          },
        ),
      );
    }
  }

  static void cloneRepo(String encodedData) {
    final data = json.decode(encodedData);
    final repo = Repository.clone(
      url: data["url"],
      localPath: data["path"],
    );

    repo.free();
  }

  static bool isAdmin() {
    if (Minecraft.profile.value == null) return false;

    return Constants.adminList.contains(Minecraft.profile.value!.uuid);
  }

  static Future<bool> isUpdated() async {
    if (Constants.versionEndPoint.isEmpty) return true;

    final packageInfo = await PackageInfo.fromPlatform();
    final versionResponse = await http.get(
      Uri.parse(Constants.versionEndPoint),
    );
    final version = json.decode(versionResponse.body);

    return packageInfo.version == version["version"];
  }

  static Future<bool> update() async {
    if (!Platform.isWindows) return false;

    try {
      final versionResponse = await http.get(
        Uri.parse(Constants.versionEndPoint),
      );
      final version = json.decode(versionResponse.body);

      await AutoUpdate.downloadAndUpdate(version[Platform.operatingSystem]);
      return true;
    } catch (e) {
      return false;
    }
  }
}
