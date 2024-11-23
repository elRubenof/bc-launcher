import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utility {
  static ValueNotifier<bool> isLoading = ValueNotifier(false);
  static bool autoConnect = false;
  static late Directory minecraftDirectory;

  static Future<void> init() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    autoConnect = preferences.getBool("autoConnect") ?? false;

    final supportDirectory = await getApplicationSupportDirectory();
    minecraftDirectory = Directory("${supportDirectory.path}/.minecraft");
    await minecraftDirectory.create();
  }

  static AppLocalizations getLocalizations(BuildContext context) {
    return AppLocalizations.of(context)!;
  }

  static Future<void> setAutoConnect(bool value) async {
    SharedPreferences preferences = await SharedPreferences.getInstance();

    await preferences.setBool("autoConnect", value);
    autoConnect = value;
  }
}
