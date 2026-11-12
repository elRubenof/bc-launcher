import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// A full-screen error: [message] in a box in the middle, with the window
/// buttons on top.
class FatalErrorMessage extends StatelessWidget {
  final String message;

  const FatalErrorMessage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                width: 0.5,
                color: Colors.white.withValues(alpha: 0.5),
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
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
              child: const WindowButtons(enableSettings: false, darkMode: true),
            ),
          ),
        ),
      ],
    );
  }
}
