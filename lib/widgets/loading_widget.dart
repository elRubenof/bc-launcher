import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

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
          SizedBox(
            height: Constants.topBarHeight,
            child: MoveWindow(),
          ),
          Center(
            child: SvgPicture.asset(
              "assets/img/logo.svg",
              height: 300,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ValueListenableBuilder(
                  valueListenable: Utility.loadingState,
                  builder: (context, value, child) => Text(
                    value ?? "",
                    style: TextStyle(color: color),
                  ),
                ),
              ),
              ValueListenableBuilder(
                valueListenable: Utility.loadingProgress,
                builder: (context, value, child) => LinearProgressIndicator(
                  value: value,
                  color: color,
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
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
      ),
    );
  }
}
