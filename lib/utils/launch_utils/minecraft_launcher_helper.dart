import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart';

class MinecraftLauncherHelper {
  static bool parseSingeRule(Map rule, Map options) {
    late bool returnValue;

    if (rule['action'] == "allow") {
      returnValue = false;
    } else if (rule['action'] == "disallow") {
      returnValue = true;
    }

    if (rule.containsKey("os")) {
      for (var entry in (rule["os"] as Map).entries) {
        final key = entry.key;
        final value = entry.value;

        if (key == "name") {
          if (value == "windows" && !Platform.isWindows) return returnValue;
          if (value == "osx" && !Platform.isMacOS) return returnValue;
          if (value == "linux" && !Platform.isLinux) return returnValue;
        }
      }
    }

    if (rule.containsKey("features")) {
      for (var entry in (rule["features"] as Map).entries) {
        final key = entry.key;

        if (key == "has_custom_resolution" &&
            !(options["customResolution"] ?? false)) {
          return returnValue;
        }
        if (key == "is_demo_user" && !(options["demo"] ?? false)) {
          return returnValue;
        }
        if (key == "has_quick_plays_support" &&
            options["quickPlayPath"] == null) {
          return returnValue;
        }
        if (key == "is_quick_play_singleplayer" &&
            options["quickPlaySingleplayer"] == null) {
          return returnValue;
        }
        if (key == "is_quick_play_multiplayer" &&
            options["quickPlayMultiplayer"] == null) {
          return returnValue;
        }
        if (key == "is_quick_play_realms" &&
            options["quickPlayRealms"] == null) {
          return returnValue;
        }
      }
    }

    return !returnValue;
  }

  static bool parseRuleList(List rules, Map options) {
    for (var item in rules) {
      if (!parseSingeRule(item, options)) return false;
    }

    return true;
  }

  static String getNatives(Map data) {
    const archType = "64";

    if (data.containsKey("natives")) {
      if (Platform.isWindows && data["natives"].containsKey("windows")) {
        return data["natives"]["windows"].replaceAll(r"${arch}", archType);
      }

      if (Platform.isMacOS && data["natives"].containsKey("osx")) {
        return data["natives"]["osx"].replaceAll(r"${arch}", archType);
      }

      if (Platform.isLinux && data["natives"].containsKey("linux")) {
        return data["natives"]["linux"].replaceAll(r"${arch}", archType);
      }
    }

    return "";
  }

  static String getClasspathSeparator() {
    return Platform.isWindows ? ";" : ":";
  }

  static String getLibraryPath(String name, String path) {
    String suffix = "";

    if (name.contains("@")) {
      final nameParts = name.split('@');
      name = nameParts[0];
      suffix = nameParts[1];
    } else {
      suffix = "jar";
    }

    String libpath = join(path, "libraries");
    final parts = name.split(':');
    final basePath = parts[0];
    final libname = parts[1];
    final version = parts[2];
    for (String item in basePath.split('.')) {
      libpath = join(libpath, item);
    }

    String extraParts = "";
    if (parts.length > 3) {
      extraParts = parts.sublist(3).map((p) => '-$p').join('');
    }

    String fileName = '$libname-$version$extraParts.$suffix';
    libpath = join(libpath, libname, version, fileName);

    return libpath;
  }

  static Future<dynamic> inheritJson(Map originalData, path) async {
    final inheritVersion = originalData["inheritsFrom"];

    final versionFile = File(
      join(path, "versions", inheritVersion, "$inheritVersion.json"),
    );
    final newData = jsonDecode(await versionFile.readAsString());

    Map<String, bool> originalLibs = {};
    for (Map item in originalData["libraries"] ?? []) {
      final libName = _getLibNameWithoutVersion(item);
      originalLibs[libName] = true;
    }

    final List libList = originalData["libraries"] ?? [];
    for (Map item in newData["libraries"]) {
      final libName = _getLibNameWithoutVersion(item);
      if (!originalLibs.containsKey(libName)) {
        libList.add(item);
      }
    }

    newData["libraries"] = libList;

    for (var entry in originalData.entries) {
      final key = entry.key;
      final value = entry.value;

      if (key == "libraries") continue;

      if (value is List && newData[key] is List) {
        newData[key] = value + newData[key];
      } else if (value is Map && newData[key] is Map) {
        for (var subEntry in value.entries) {
          if (subEntry.value is List) {
            newData[key][subEntry.key] =
                newData[key][subEntry.key] + subEntry.value;
          }
        }
      } else {
        newData[key] = value;
      }
    }

    return newData;
  }

  static String _getLibNameWithoutVersion(Map lib) {
    final nameParts = lib['name'].split(':');
    return nameParts.getRange(0, nameParts.length - 1).join(':');
  }
}
