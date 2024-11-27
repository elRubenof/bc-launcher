import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class LoginScreen extends StatefulWidget {
  static late Uri authorizationUrl;

  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final initialUrl = URLRequest(
    url: WebUri(
      "${LoginScreen.authorizationUrl}&cobrandid=8058f65d-ce06-4c30-9559-473c9275a65d&prompt=select_account",
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InAppWebView(
          initialUrlRequest: initialUrl,
          onLoadStart: (controller, url) {
            if (!"$url".startsWith(Constants.redirectUrl)) return;

            controller.loadUrl(urlRequest: initialUrl);
            Utility.isLoging.value = false;
          },
        ),
        SizedBox(
          height: Constants.topBarHeight,
          child: MoveWindow(),
        ),
      ],
    );
  }
}
