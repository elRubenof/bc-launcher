import 'package:bc_launcher/l10n/app_localizations.dart';
import 'package:bc_launcher/screens/login_screen.dart';
import 'package:bc_launcher/screens/no_organizations_screen.dart';
import 'package:bc_launcher/screens/organizations_screen.dart';
import 'package:bc_launcher/services/deep_links.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/global_settings.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/organization_dialog.dart';
import 'package:bc_launcher/widgets/fatal_error_message.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DeepLinks.listen();
  OrganizationDialog.listen();
  DeepLinks.register();
  _setUpWindow();

  await GlobalSettings.load();
  await OrganizationStore.load();
  OrganizationStore.refresh();

  runApp(
    MaterialApp(
      navigatorKey: Utility.key,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MyApp(),
    ),
  );
}

void _setUpWindow() {
  final window = WindowManager.instance.getCurrent();
  if (window == null) return;

  const initialSize = Size(1280, 750);
  window.titleBarStyle = TitleBarStyle.hidden;
  window.isWindowControlButtonsVisible = false;
  window.minimumSize = initialSize.toNative();
  window.setSize(initialSize.toNative(), false);
  window.center();
  window.show();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (Constants.clientID.isEmpty) {
      return Scaffold(
        backgroundColor: Constants.backgroundColor,
        body: FatalErrorMessage(
          message: Utility.getLocalizations(context).missingClientId,
        ),
      );
    }

    return FutureBuilder(
      future: Minecraft.authenticateOauth2(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoadingScreen();
        }

        if (!snapshot.data!) {
          return const LoginScreen();
        }

        return ValueListenableBuilder(
          valueListenable: OrganizationStore.organizations,
          builder: (context, organizations, _) => organizations.isEmpty
              ? const NoOrganizationsScreen()
              : const OrganizationsScreen(),
        );
      },
    );
  }
}
