import 'dart:convert';
import 'dart:developer';

import 'package:bc_launcher/main.dart';
import 'package:bc_launcher/services/credentials_store.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:bc_launcher/widgets/mascot/mascot.dart';
import 'package:bc_launcher/widgets/mascot/mascot_frames.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

class LoginScreen extends StatefulWidget {
  /// Microsoft rejected the saved session: "Sign in again".
  final bool expired;

  const LoginScreen({super.key, this.expired = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  Uri? _authUrl;
  bool _failed = false;
  bool _copied = false;

  @override
  void initState() {
    super.initState();

    CredentialsStore.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _login());
  }

  @override
  void dispose() {
    Minecraft.closeRedirectServer();
    super.dispose();
  }

  /// Starts the redirect server and waits for the sign-in. The browser is only
  /// opened from the buttons.
  Future<void> _login() async {
    final l = Utility.getLocalizations(context);
    setState(() {
      _authUrl = null;
      _failed = false;
    });

    try {
      final grant = await Minecraft.getAuthorizationCode();
      final redirect = await Minecraft.startRedirectServer();
      final authUrl = Minecraft.getAuthorizationUrl(grant, redirect);
      if (!mounted) return;

      setState(() => _authUrl = authUrl);

      final params = await Minecraft.waitForRedirect(
        _browserPage(l.loginBrowserDone),
      );
      final client = await grant.handleAuthorizationResponse(params);

      await CredentialsStore.write(client.credentials.toJson());

      WindowManager.instance.getCurrent()?.focus();
      if (!mounted) return;
      Utility.pushReplacement(context, const MyApp());
    } catch (e) {
      log("Login failed: $e");
      await Minecraft.closeRedirectServer();
      if (mounted) setState(() => _failed = true);
    }
  }

  String _browserPage(String message) {
    final text = const HtmlEscape().convert(message);
    return '<!doctype html><html><head><meta charset="utf-8">'
        '<title>BC Launcher</title></head>'
        '<body style="margin:0;height:100vh;display:flex;align-items:center;'
        'justify-content:center;background:#23162a;color:#fff;'
        'font-family:sans-serif;font-size:18px;text-align:center">'
        '<p>$text</p><script>window.close()</script></body></html>';
  }

  Future<void> _openBrowser() async {
    try {
      await launchUrl(_authUrl!);
    } catch (e) {
      // The link can still be copied by hand.
      log("Couldn't open the browser: $e");
    }
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _authUrl.toString()));
    setState(() => _copied = true);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);
    final textColor = Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Mascot(scene: MascotScene.waiting, cell: 9),
                const SizedBox(height: 12),
                Text(
                  _failed
                      ? l.loginError
                      : widget.expired
                      ? l.loginExpiredTitle
                      : l.loginTitle,
                  style: const TextStyle(
                    color: Constants.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _failed
                      ? l.loginErrorDesc
                      : widget.expired
                      ? l.loginExpiredDesc
                      : l.loginInBrowser,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
                const SizedBox(height: 28),
                if (_failed)
                  _button(l.loginRetry, filled: true, onPressed: _login)
                else if (_authUrl != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _button(
                        l.loginOpenBrowser,
                        filled: true,
                        onPressed: _openBrowser,
                      ),
                      const SizedBox(width: 12),
                      _button(
                        _copied ? l.loginLinkCopied : l.loginCopyLink,
                        filled: false,
                        onPressed: _copyLink,
                      ),
                    ],
                  )
                else
                  const SizedBox(height: 44),
              ],
            ),
          ),
          SizedBox(
            height: Constants.topBarHeight,
            child: DragToMoveArea(
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
      ),
    );
  }

  Widget _button(
    String text, {
    required bool filled,
    required VoidCallback onPressed,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    const padding = EdgeInsets.symmetric(horizontal: 22, vertical: 16);
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Constants.mainColor,
          foregroundColor: Constants.textColor,
          shape: shape,
          padding: padding,
          textStyle: textStyle,
        ),
        child: Text(text),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Constants.textColor,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        shape: shape,
        padding: padding,
        textStyle: textStyle,
      ),
      child: Text(text),
    );
  }
}
