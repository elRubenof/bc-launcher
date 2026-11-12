import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:bc_launcher/widgets/mascot/mascot.dart';
import 'package:bc_launcher/widgets/mascot/mascot_frames.dart';
import 'package:window_manager/window_manager.dart';

/// The launcher's loading screen: its logo and, at the bottom, [status],
/// [detail] and a bar with [progress] (moving while it is `null`).
class LoadingScreen extends StatefulWidget {
  final String? status;
  final String? detail;
  final double? progress;

  const LoadingScreen({super.key, this.status, this.detail, this.progress});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  /// Room the status, its detail and the progress bar take at the bottom,
  /// with some margin.
  static const _bottomHeight = 72.0;

  final color = Colors.white.withValues(alpha: 0.8);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: Stack(
        children: [
          // Not const: `flutter run` fails to compile a const DragToMoveArea.
          // ignore: prefer_const_constructors
          SizedBox(
            height: Constants.topBarHeight,
            // ignore: prefer_const_constructors
            child: DragToMoveArea(child: SizedBox.expand()),
          ),
          // Floating while there is no progress, flying with it.
          Positioned.fill(
            child: Mascot(
              scene: widget.progress == null
                  ? MascotScene.loading
                  : MascotScene.flying,
              cell: 18,
              fill: true,
              // No wind on the bar that drags the window, nor on the status
              // text and progress bar at the bottom.
              windMargin: const EdgeInsets.only(
                top: Constants.topBarHeight,
                bottom: _bottomHeight,
              ),
            ),
          ),
          _bottom(widget.status, widget.detail, widget.progress),
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

  Widget _bottom(String? status, String? detail, double? progress) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status ?? "", style: TextStyle(color: color)),
              if (detail != null) ...[
                const SizedBox(height: 6),
                Text(
                  detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        ),
        LinearProgressIndicator(
          value: progress,
          color: color,
          backgroundColor: Colors.transparent,
        ),
      ],
    );
  }
}
