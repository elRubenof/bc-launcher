import 'package:bc_launcher/main.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:oauth2/oauth2.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late AuthorizationCodeGrant grant;

  @override
  void initState() {
    super.initState();

    SharedPreferences.getInstance().then((pref) => pref.remove("credentials"));
    Minecraft.listenParameters().then((response) async {
      final client = await grant.handleAuthorizationResponse(response);

      final preferences = await SharedPreferences.getInstance();
      await preferences.setString("credentials", client.credentials.toJson());

      Utility.pushReplacement(context, const MyApp());
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: FutureBuilder(
        future: Minecraft.getAuthorizationCode(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingScreen();
          }

          grant = snapshot.data!;
          final authUrl = grant.getAuthorizationUrl(
            Uri.parse(Constants.redirectUrl),
            scopes: ['XboxLive.signin', 'offline_access'],
          );

          final initialUrl = URLRequest(
            url: WebUri(
              "$authUrl&cobrandid=8058f65d-ce06-4c30-9559-473c9275a65d&prompt=select_account",
            ),
          );

          return Stack(
            children: [
              const LoadingScreen(),
              InAppWebView(initialUrlRequest: initialUrl),
              SizedBox(
                height: Constants.topBarHeight,
                child: MoveWindow(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Constants.horizontalPadding,
                    ),
                    alignment: Alignment.centerRight,
                    child: const WindowButtons(
                      enableSettings: false,
                      darkMode: true,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
