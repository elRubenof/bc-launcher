import 'package:flutter/material.dart';

class Constants {
  static const backgroundColor = Color(0xFF23162a);
  static const mainColor = Color(0xFFA83CBB);
  static const mainColorDarked = Color(0xFF8F349D);
  static const textColor = Color(0xFFFFFFFF);

  static const topBarHeight = 65.0;
  static const horizontalPadding = 90.0;

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
