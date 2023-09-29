import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:launcher/models/minecraft_account.dart';
import 'package:launcher/utils/data.dart';
import 'package:launcher/utils/git.dart';
import 'package:launcher/utils/microsoft.dart';
import 'package:launcher/utils/server.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utility {
  static ValueNotifier<bool> isLoading = ValueNotifier(false);

  static int allocatedRAM = 12;
  static bool autoConnect = true;
  static bool autoUpdate = true;
  static bool autoClose = true;

  static List<MinecraftAccount> accounts = [];
  static late MinecraftAccount selectedAccount;

  static Future<String> initApp() async {
    documentsDirectory = await getApplicationDocumentsDirectory();

    // Compruebo si existe el directorio .minecraft y lo creo en consecuencia
    Directory minecraftDir = Directory(minecraftPath);

    if (!await minecraftDir.exists()) {      
      await minecraftDir.create();
      await Git.donwloadMinecraft();
    }

    //Cargo los usuarios desde el archivo
    await _loadUsers();

    if (accounts.isEmpty) {
      await Microsoft.loginFromBrowser();
      if (selectedAccount.uuid.isEmpty) return "Login Failure";
    }

    await loadConfig();

    await Server.init();
    return await Git.init();
  }

  static Future<void> loadConfig() async {
    SharedPreferences pref = await SharedPreferences.getInstance();

    allocatedRAM = pref.getInt('allocatedRAM') ?? 12;
    autoConnect = pref.getBool('autoConnect') ?? true;
    autoUpdate = pref.getBool('autoUpdate') ?? true;
    autoClose = pref.getBool('autoClose') ?? true;
  }

  static Future<void> _loadUsers() async {
    File accountsFile = File("${documentsDirectory.path}/accounts.json");

    //Si el archivo no existe le creo y salgo indicando que no hay cuentas
    if (!await accountsFile.exists()) {
      await accountsFile.create();
      return;
    }

    try {
      String content = await accountsFile.readAsString();
      List users = json.decode(content);

      accounts.clear();
      for (var user in users) {
        MinecraftAccount mcAccount = MinecraftAccount.loadFull(
          user['uuid']!,
          user['username']!,
          user['xblToken']!,
          user['bearer']!,
        );

        accounts.add(mcAccount);
      }

      if (accounts.isNotEmpty) selectedAccount = accounts[0];
    } catch (e) {
      return;
    }
  }

  static Future<void> saveUsers() async {
    File accountsFile = File("${documentsDirectory.path}/accounts.json");

    //Si el archivo no existe le creo y salgo indicando que no hay cuentas
    if (await accountsFile.exists()) await accountsFile.delete();
    await accountsFile.create();

    var encoder = const JsonEncoder.withIndent("     ");
    await accountsFile.writeAsString(encoder.convert(accounts));
  }
}
