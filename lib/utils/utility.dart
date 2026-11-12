import 'package:bc_launcher/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class Utility {
  static final key = GlobalKey<NavigatorState>();

  static ValueNotifier<bool> isLaunching = ValueNotifier(false);

  /// The game is running.
  static ValueNotifier<bool> isPlaying = ValueNotifier(false);

  static AppLocalizations getLocalizations(BuildContext context) {
    return AppLocalizations.of(context)!;
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
