import 'package:bc_launcher/l10n/app_localizations.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/settings.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utility {
  static final key = GlobalKey<NavigatorState>();

  static ValueNotifier<bool> isLaunching = ValueNotifier(false);

  /// The game is running.
  static ValueNotifier<bool> isPlaying = ValueNotifier(false);

  static AppLocalizations getLocalizations(BuildContext context) {
    return AppLocalizations.of(context)!;
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
    Settings.keepLauncherOpen =
        preferences.getBool("keepLauncherOpen") ??
        Constants.defaultKeepLauncherOpen;
  }

  static Future<void> resetSettings() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    Settings.autoConnect = Constants.defaultAutoConnect;
    Settings.allocatedRAM = Constants.defaultAllocatedRAM;
    Settings.gameWidth = Constants.defaultGameWidth;
    Settings.gameHeight = Constants.defaultGameHeight;
    Settings.fullscreen = Constants.defaultFullscreen;
    Settings.keepLauncherOpen = Constants.defaultKeepLauncherOpen;

    preferences.remove("autoConnect");
    preferences.remove("allocatedRAM");
    preferences.remove("gameWidth");
    preferences.remove("gameHeight");
    preferences.remove("fullscreen");
    preferences.remove("keepLauncherOpen");
  }

  static Future<void> setAutoConnect(bool value) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setBool("autoConnect", value);
    Settings.autoConnect = value;
  }

  static void pushReplacement(BuildContext context, Widget destination) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) {
          return destination;
        },
        transitionDuration: Duration.zero,
      ),
    );
  }
}
