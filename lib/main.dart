import 'package:bc_launcher/screens/login_screen.dart';
import 'package:bc_launcher/screens/main_screen.dart';
import 'package:bc_launcher/screens/update_screen.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

bool _updated = false;

void main() async {
  await Utility.loadSettings();
  _updated = await Utility.isUpdated();

  runApp(
    MaterialApp(
      navigatorKey: Utility.key,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: !_updated ? const UpdateScreen() : const MyApp(),
    ),
  );

  doWhenWindowReady(() {
    const initialSize = Size(1280, 750);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Minecraft.authenticateOauth2(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingScreen();
        }

        if (!snapshot.data!) {
          return const LoginScreen();
        }

        return const MainScreen();
      },
    );
  }
}
