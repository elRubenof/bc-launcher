import 'package:bc_launcher/main.dart';
import 'package:bc_launcher/screens/login_screen.dart';
import 'package:bc_launcher/services/xbox_auth.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/custom_button.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// Why the signed-in Microsoft account can't play; it is fixed outside the
/// launcher, then tried again or another account is used.
class AccountErrorScreen extends StatelessWidget {
  final AccountProblem problem;

  const AccountErrorScreen({super.key, required this.problem});

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);
    final textColor = Colors.white.withValues(alpha: 0.8);

    final (icon, title, description) = switch (problem) {
      AccountProblem.child => (
        Icons.family_restroom_rounded,
        l.accountChildTitle,
        l.accountChildDesc,
      ),
      AccountProblem.noXbox => (
        Icons.person_add_alt_rounded,
        l.accountNoXboxTitle,
        l.accountNoXboxDesc,
      ),
      AccountProblem.country => (
        Icons.public_off_rounded,
        l.accountCountryTitle,
        l.accountCountryDesc,
      ),
      AccountProblem.adultVerification => (
        Icons.verified_user_outlined,
        l.accountAdultTitle,
        l.accountAdultDesc,
      ),
      // Shown by the login itself; here only for completeness.
      AccountProblem.expired => (
        Icons.lock_clock_outlined,
        l.loginExpiredTitle,
        l.loginExpiredDesc,
      ),
      AccountProblem.noMinecraft => (
        Icons.view_in_ar_rounded,
        l.accountNoGameTitle,
        l.accountNoGameDesc,
      ),
    };

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Constants.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      CustomButton(
                        l.retry,
                        onPressed: () =>
                            Utility.pushReplacement(context, const MyApp()),
                      ),
                      CustomButton(
                        l.useAnotherAccount,
                        filled: false,
                        onPressed: () async {
                          await Minecraft.logout();
                          if (!context.mounted) return;
                          Utility.pushReplacement(context, const LoginScreen());
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: Constants.topBarHeight,
            // Not const: `flutter run` fails to compile a const DragToMoveArea.
            // ignore: prefer_const_constructors
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
}
