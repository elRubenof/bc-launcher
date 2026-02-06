import 'dart:convert';
import 'dart:io';
import 'package:bc_launcher/utils/launch_utils/minecraft_launcher_helper.dart';
import 'package:path/path.dart' as p;

class MinecraftLauncherCore {
  static String getLibraries(Map data, String path) {
    final classpathSeparator = MinecraftLauncherHelper.getClasspathSeparator();

    String libstr = "";
    for (Map item in data["libraries"]) {
      if (item.containsKey("rules") &&
          !MinecraftLauncherHelper.parseRuleList(item["rules"], {})) {
        continue;
      }

      libstr +=
          MinecraftLauncherHelper.getLibraryPath(item["name"], path) +
          classpathSeparator;
      final native = MinecraftLauncherHelper.getNatives(item);
      if (native.isNotEmpty) {
        if (item.containsKey("downloads") &&
            item["downloads"]["classifiers"][native].containsKey("path")) {
          libstr +=
              p.join(
                path,
                "libraries",
                item["downloads"]["classifiers"][native]["path"],
              ) +
              classpathSeparator;
        } else {
          libstr +=
              MinecraftLauncherHelper.getLibraryPath(
                "${item['name']}-$native",
                path,
              ) +
              classpathSeparator;
        }
      }
    }

    if (data.containsKey("jar")) {
      libstr += p.join(path, "versions", data["jar"], data["jar"] + ".jar");
    } else {
      libstr += p.join(path, "versions", data["id"], data["id"] + ".jar");
    }

    return libstr;
  }

  static String replaceArguments(
    String argstr,
    Map versionData,
    String path,
    Map options,
    String classpath,
  ) {
    return argstr
        .replaceAll(r"${natives_directory}", options["nativesDirectory"])
        .replaceAll(
          r"${launcher_name}",
          options["launcherName"] ?? "BC Launcher",
        )
        .replaceAll(r"${launcher_version}", options["launcherVersion"] ?? "0.3")
        .replaceAll(r"${classpath}", classpath)
        .replaceAll(r"${auth_player_name}", options["username"] ?? "{username}")
        .replaceAll(r"${version_name}", versionData["id"])
        .replaceAll(r"${game_directory}", options["gameDirectory"] ?? path)
        .replaceAll(r"${assets_root}", p.join(path, "assets"))
        .replaceAll(
          r"${assets_index_name}",
          versionData["assets"] ?? versionData["id"],
        )
        .replaceAll(r"${auth_uuid}", options["uuid"] ?? "{uuid}")
        .replaceAll(r"${auth_access_token}", options["token"] ?? "{token}")
        .replaceAll(r"${user_type}", "msa")
        .replaceAll(r"${version_type}", versionData["type"])
        .replaceAll(r"${user_properties}", "{}")
        .replaceAll(r"${resolution_width}", options["resolutionWidth"] ?? "854")
        .replaceAll(
          r"${resolution_height}",
          options["resolutionHeight"] ?? "480",
        )
        .replaceAll(
          r"${game_assets}",
          p.join(path, "assets", "virtual", "legacy"),
        )
        .replaceAll(r"${auth_session}", options["token"] ?? "{token}")
        .replaceAll(r"${library_directory}", p.join(path, "libraries"))
        .replaceAll(
          r"${classpath_separator}",
          MinecraftLauncherHelper.getClasspathSeparator(),
        )
        .replaceAll(r"${quickPlayPath}", options["quickPlayPath"] ?? "")
        .replaceAll(
          r"${quickPlaySingleplayer}",
          options["quickPlaySingleplayer"] ?? "",
        )
        .replaceAll(
          r"${quickPlayMultiplayer}",
          options["quickPlayMultiplayer"] ?? "",
        )
        .replaceAll(r"${quickPlayRealms}", options["quickPlayRealms"] ?? "");
  }

  static List<String> getArgumentsString(
    Map versionData,
    String path,
    Map options,
    String classpath,
  ) {
    final List<String> argList = [];

    for (String v in versionData["minecraftArguments"].split(" ")) {
      v = replaceArguments(v, versionData, path, options, classpath);
      argList.add(v);
    }

    if (options['customResolution'] ?? false) {
      argList.add("--width");
      argList.add(options["resolutionWidth"] ?? "854");
      argList.add("--height");
      argList.add(options["resolutionHeight"] ?? "480");
    }

    if (options['demo'] ?? false) {
      argList.add("--demo");
    }

    return argList;
  }

  static List<String> getArguments(
    List data,
    Map versionData,
    String path,
    Map options,
    String classpath,
  ) {
    final List<String> argList = [];
    for (var item in data) {
      if (item is String) {
        argList.add(
          replaceArguments(item, versionData, path, options, classpath),
        );
      } else {
        if (item.containsKey("compatibilityRules") &&
            !MinecraftLauncherHelper.parseRuleList(
              item["compatibilityRules"],
              options,
            )) {
          continue;
        }

        if (item.containsKey("rules") &&
            !MinecraftLauncherHelper.parseRuleList(item["rules"], options)) {
          continue;
        }

        if (item["value"] is String) {
          argList.add(
            replaceArguments(
              item["value"],
              versionData,
              path,
              options,
              classpath,
            ),
          );
        } else {
          for (var v in item["value"]) {
            v = replaceArguments(v, versionData, path, options, classpath);
            argList.add(v);
          }
        }
      }
    }

    return argList;
  }

  static Future<List<String>> getMinecraftCommand(
    String version,
    String path,
    Map options,
  ) async {
    if (!Directory(p.join(path, "versions", version)).existsSync()) {
      throw Exception("Version not found");
    }

    final versionFile = File(
      p.join(path, "versions", version, "$version.json"),
    );

    var data = jsonDecode(await versionFile.readAsString());
    if (data["inheritsFrom"] != null) {
      data = await MinecraftLauncherHelper.inheritJson(data, path);
    }

    options["nativesDirectory"] =
        options['nativesDirectory'] ??
        p.join(path, "versions", data["id"], "natives");
    final classPath = getLibraries(data, path);

    List<String> command = [options["executablePath"] ?? "java"];
    if (options.containsKey("jvmArguments")) {
      command += options["jvmArguments"];
    }

    if (data["arguments"] is Map) {
      if (data["arguments"].containsKey("jvm")) {
        command += getArguments(
          data["arguments"]["jvm"],
          data,
          path,
          options,
          classPath,
        );
      } else {
        command.add("-Djava.library.path=${options['nativesDirectory']}");
        command.add("-cp");
        command.add(classPath);
      }
    } else {
      command.add("-Djava.library.path=${options['nativesDirectory']}");
      command.add("-cp");
      command.add(classPath);
    }

    command.add(data["mainClass"]);

    if (data["minecraftArguments"] != null) {
      command += getArgumentsString(data, path, options, classPath);
    } else {
      command += getArguments(
        data["arguments"]["game"],
        data,
        path,
        options,
        classPath,
      );
    }

    if (options.containsKey("server")) {
      command.add("--server");
      command.add(options["server"]);

      if (options.containsKey("port")) {
        command.add("--port");
        command.add(options["port"]);
      }
    }

    if (options['disableMultiplayer'] ?? false) {
      command.add("--disableMultiplayer");
    }

    if (options['disableChat'] ?? false) {
      command.add("--disableChat");
    }

    return command;
  }
}
