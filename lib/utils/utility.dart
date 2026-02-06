import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:auto_update/auto_update.dart';
import 'package:bc_launcher/l10n/app_localizations.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/settings.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:git2dart/git2dart.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Utility {
  static final key = GlobalKey<NavigatorState>();

  static ValueNotifier<bool> isLoading = ValueNotifier(false);
  static ValueNotifier<String?> loadingState = ValueNotifier(null);
  static ValueNotifier<double?> loadingProgress = ValueNotifier(null);

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

  static Future<Map<String, dynamic>> getAuth(String uuid) async {
    try {
      final response = await http.get(
        Uri.parse("${Constants.api}/auth?uuid=$uuid"),
      );

      if (response.statusCode != 200) {
        return {'error': true, 'statusCode': response.statusCode};
      }

      return json.decode(response.body);
    } catch (e) {
      return {'error': true, 'statusCode': e.toString()};
    }
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

  static Future<Directory> getInstanceDir(String serverId) async {
    final supportDirectory = await getApplicationSupportDirectory();
    final installDir = Directory(
      "${supportDirectory.path}${Platform.isWindows ? r'\' : '/'}$serverId",
    );

    Settings.minecraftDirectory = installDir;
    return installDir;
  }

  static Future<bool> installInstance(Map server, Directory installDir) async {
    try {
      await _downloadInstance(server, installDir);
      await _unZipInstance(server, installDir);

      return true;
    } catch (e) {
      log("Error on install instance ${server['id']}: \n${e.toString()}");

      return false;
    }
  }

  static Future<void> _downloadInstance(
    Map server,
    Directory installDir,
  ) async {
    final l = Utility.getLocalizations(key.currentContext!);

    log("Downloading ${server['id']}");
    await Dio().download(
      "${Constants.api}/server/install?id=${server['id']}",
      "${installDir.path}.zip",
      options: Options(method: 'POST', responseType: ResponseType.bytes),
      onReceiveProgress: (received, total) {
        if (total != -1) {
          Utility.loadingState.value ??= "${l.downloading} ${server['name']}";
          Utility.loadingProgress.value = received / total;
        }
      },
    );

    Utility.loadingState.value = null;
    Utility.loadingProgress.value = null;
    log("Download complete: ${installDir.path}.zip");
  }

  static Future<void> _unZipInstance(Map server, Directory installDir) async {
    final l = Utility.getLocalizations(key.currentContext!);
    Utility.loadingState.value = "${l.installing} ${server['name']}";

    String zipFilePath = "${installDir.path}.zip";
    File zipFile = File(zipFilePath);
    if (!await zipFile.exists()) return;

    Archive archive = ZipDecoder().decodeBytes(await zipFile.readAsBytes());

    for (ArchiveFile file in archive) {
      String filename = file.name;
      if (file.isFile) {
        List<int> data = file.content;
        File('${installDir.path}/$filename')
          ..createSync(recursive: true)
          ..writeAsBytesSync(data);
      } else {
        Directory('${installDir.path}/$filename').createSync(recursive: true);
      }
    }

    log("Unzip finished: ${installDir.path}");

    await zipFile.delete();
    Utility.loadingState.value = null;
  }

  static Future<void> checkFiles(String serverId) async {
    final response = await http.get(
      Uri.parse("${Constants.api}/server/version?id=$serverId"),
    );

    final version = json.decode(response.body);
    final preferences = await SharedPreferences.getInstance();

    if (preferences.getInt("$serverId-version") == version['version']) return;

    await _deleteUntrackedFolders(version);
    await _checkAndDownloadFiles(version);
  }

  static Future<void> _deleteUntrackedFolders(Map version) async {
    for (String path in version['delete_untracked_folders'] ?? []) {
      for (var file
          in Directory(
            "${Settings.minecraftDirectory.path}/$path",
          ).listSync()) {
        if (file is! File) continue;

        final fileName = file.path.replaceFirst("${file.parent.path}\\", "");
        if ((version['files'] as List)
            .where((e) => e['path'] == "$path/$fileName")
            .isEmpty) {
          await file.delete();
        }
      }
    }
  }

  static Future<void> _checkAndDownloadFiles(Map version) async {
    for (Map<String, dynamic> fileMap in version['files']) {
      final file = File(
        "${Settings.minecraftDirectory.path}/${fileMap['path']}",
      );
      final hash = file.existsSync() ? await _getHash(file) : null;

      if (hash != null && hash == fileMap['hash']) continue;

      log("Downloading ${fileMap['path']}");
      await Dio().download(
        "${Constants.api}/server/file?id=${version['instance']}&file=${fileMap['path']}",
        file.path,
        options: Options(method: 'POST', responseType: ResponseType.bytes),
      );
    }
  }

  static Future<String> _getHash(File file) async {
    return "${await file.openRead().transform(sha256).first}";
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
      Utility.loadingState.value = l.installing;

      await compute<String, void>(
        cloneRepo,
        json.encode({
          "url": Constants.minecraftRepo,
          "path": Settings.minecraftDirectory.path,
        }),
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
        json.encode({"url": repoUrl, "path": repoDir.path}),
      );
    }
  }

  static void cloneRepo(String encodedData) {
    final data = json.decode(encodedData);
    final repo = Repository.clone(url: data["url"], localPath: data["path"]);

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
