import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:bc_launcher/widgets/mascot/mascot.dart';
import 'package:bc_launcher/widgets/mascot/mascot_frames.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class NoOrganizationsScreen extends StatelessWidget {
  const NoOrganizationsScreen({super.key});

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
                  l.noOrganizationsTitle,
                  style: const TextStyle(
                    color: Constants.textColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.noOrganizationsDesc,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontSize: 14),
                ),
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
}
