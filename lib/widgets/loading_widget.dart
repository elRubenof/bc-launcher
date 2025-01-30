import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LoadingWidget extends StatefulWidget {
  const LoadingWidget({super.key});

  @override
  State<LoadingWidget> createState() => _LoadingWidgetState();
}

class _LoadingWidgetState extends State<LoadingWidget> {
  final color = Colors.white.withValues(alpha: 0.8);
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Utility.isLoging,
      builder: (context, isLoging, child) {
        return Stack(
          children: [
            SizedBox(
              height: Constants.topBarHeight,
              child: MoveWindow(),
            ),
            Center(
              child: Constants.appLogo.isNotEmpty
                  ? SvgPicture.asset(
                      Constants.appLogo,
                      height: 300,
                      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                    )
                  : CircularProgressIndicator(color: color),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: ValueListenableBuilder(
                    valueListenable: Utility.loadingState,
                    builder: (context, value, child) => Text(
                      value,
                      style: TextStyle(color: color),
                    ),
                  ),
                ),
                if (Constants.appLogo.isNotEmpty)
                  LinearProgressIndicator(
                    color: color,
                    backgroundColor: Colors.transparent,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}
