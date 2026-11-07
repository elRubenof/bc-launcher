import 'package:bc_launcher/utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The launcher's own settings, for every instance, in SharedPreferences;
/// each instance's game settings are in InstanceSettingsStore.
class GlobalSettings {
  static const _keepLauncherOpenKey = "keepLauncherOpen";
  static const _openLastInstanceKey = "openLastInstance";

  static bool _keepLauncherOpen = Constants.defaultKeepLauncherOpen;
  static bool _openLastInstance = Constants.defaultOpenLastInstance;

  /// The launcher stays open while playing and after the game ends.
  static bool get keepLauncherOpen => _keepLauncherOpen;

  /// On start, the last instance used opens without showing the list.
  static bool get openLastInstance => _openLastInstance;

  static Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _keepLauncherOpen =
        preferences.getBool(_keepLauncherOpenKey) ??
        Constants.defaultKeepLauncherOpen;
    _openLastInstance =
        preferences.getBool(_openLastInstanceKey) ??
        Constants.defaultOpenLastInstance;
  }

  static Future<void> setKeepLauncherOpen(bool value) async {
    _keepLauncherOpen = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_keepLauncherOpenKey, value);
  }

  static Future<void> setOpenLastInstance(bool value) async {
    _openLastInstance = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_openLastInstanceKey, value);
  }

  /// Back to the defaults.
  static Future<void> reset() async {
    _keepLauncherOpen = Constants.defaultKeepLauncherOpen;
    _openLastInstance = Constants.defaultOpenLastInstance;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_keepLauncherOpenKey);
    await preferences.remove(_openLastInstanceKey);
  }
}
