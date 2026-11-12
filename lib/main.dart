import 'package:bc_launcher/l10n/app_localizations.dart';
import 'package:bc_launcher/screens/account_error_screen.dart';
import 'package:bc_launcher/screens/login_screen.dart';
import 'package:bc_launcher/screens/no_organizations_screen.dart';
import 'package:bc_launcher/screens/organizations_screen.dart';
import 'package:bc_launcher/screens/update_required_screen.dart';
import 'package:bc_launcher/services/deep_links.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/services/update_service.dart';
import 'package:bc_launcher/services/xbox_auth.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/global_settings.dart';
import 'package:bc_launcher/utils/trusted_roots.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/organization_dialog.dart';
import 'package:bc_launcher/widgets/fatal_error_message.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await TrustedRoots.load();
  DeepLinks.listen();
  OrganizationDialog.listen();
  DeepLinks.register();
  _setUpWindow();

  await UpdateService.start(playing: Utility.isPlaying);
  await GlobalSettings.load();
  await OrganizationStore.load();
  OrganizationStore.refresh();
  // Back online: the organizations and their instances are asked again.
  Minecraft.offline.addListener(() {
    if (Minecraft.offline.value) return;
    OrganizationStore.refresh();
    InstanceCatalog.refreshAll();
  });

  runApp(
    MaterialApp(
      navigatorKey: Utility.key,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) => _UpdateGate(child: child!),
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

/// A required launcher update covers every screen until it is installed;
/// what is under it (a running game's screen too) stays as it is.
class _UpdateGate extends StatelessWidget {
  final Widget child;

  const _UpdateGate({required this.child});

  @override
  Widget build(BuildContext context) {
    final service = UpdateService.current;
    if (service == null) return child;

    return ValueListenableBuilder(
      valueListenable: service.update,
      builder: (context, update, _) => Stack(
        children: [
          child,
          if (update.status == UpdateStatus.required)
            // Above the navigator, so it brings its own overlay.
            Positioned.fill(
              child: Overlay(
                initialEntries: [
                  OverlayEntry(
                    builder: (context) => ValueListenableBuilder(
                      valueListenable: service.update,
                      builder: (context, update, _) => UpdateRequiredScreen(
                        service: service,
                        update: update,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
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
          return LoadingScreen(
            status: Utility.getLocalizations(context).loadingSigningIn,
          );
        }

        if (snapshot.data == SignIn.signedOut) {
          return switch (Minecraft.accountProblem) {
            null => const LoginScreen(),
            AccountProblem.expired => const LoginScreen(expired: true),
            final problem => AccountErrorScreen(problem: problem),
          };
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
