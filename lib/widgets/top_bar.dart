import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const topBarHeight = 60.0;

    return Container(
      width: width,
      height: topBarHeight,
      color: Constants.backgroundColor,
      child: Stack(
        children: [
          MoveWindow(),
          Container(
            height: topBarHeight,
            padding: const EdgeInsets.only(left: 117, right: 65),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: topBarHeight,
                  width: 100,
                  color: Constants.mainColor,
                  alignment: Alignment.center,
                  child: const Text("X", style: TextStyle(color: Colors.white)), //LOGO PLACEHOLDER
                ),
                windowButtons(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget windowButtons() {
    return SizedBox(
      width: 100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MouseIconButton(
            icon: Icons.settings,
            size: 14.0,
            backgroundColor: Colors.white.withOpacity(0.12),
            onTap: () => appWindow.minimize(),
          ),
          MouseIconButton(
            icon: Icons.minimize,
            size: 14.0,
            backgroundColor: Colors.white.withOpacity(0.12),
            onTap: () => appWindow.minimize(),
          ),
          MouseIconButton(
            icon: Icons.close,
            size: 14.0,
            backgroundColor: Colors.white.withOpacity(0.12),
            onTap: () => appWindow.close(),
          ),
        ],
      ),
    );
  }
}