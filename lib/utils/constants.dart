import 'package:flutter/material.dart';

class Constants {
  static const backgroundColor = Color(0xFF23162a);
  static const mainColor = Color(0xFFA83CBB);
  static const mainColorDarked = Color(0xFF8F349D);
  static const textColor = Color(0xFFFFFFFF);

  /// Actions that delete the player's files.
  static const dangerColor = Color(0xFFC93C3C);
  static const dangerTextColor = Color(0xFFFF8A8A);

  static const topBarHeight = 65.0;
  static const horizontalPadding = 90.0;

  /// Size of the animated mascot everywhere (loading, login, empty screens),
  /// as a factor of the sizes each screen gives it: 1 is the original design.
  /// Values that leave whole pixels per cell keep every pixel the same width:
  /// 8 / 9 gives 16 px on the loading screen and 8 px on login.
  static const mascotScale = 8 / 9;

  static const defaultAutoConnect = true;
  static const defaultAllocatedRAM = 8;
  static const defaultGameWidth = 854;
  static const defaultGameHeight = 480;
  static const defaultFullscreen = true;
  static const defaultKeepLauncherOpen = false;
  static const defaultOpenLastInstance = true;

  static const releasesUrl =
      "https://github.com/elRubenof/bc-launcher/releases/latest";

  static const clientID = String.fromEnvironment('MS_CLIENT_ID');
  static const redirectUrl = String.fromEnvironment(
    'MS_REDIRECT_URL',
    defaultValue: 'http://127.0.0.1',
  );
}
