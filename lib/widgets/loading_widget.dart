import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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
          Center(
            child: SvgPicture.asset(
              "assets/img/logo.svg",
              height: 300,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
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
