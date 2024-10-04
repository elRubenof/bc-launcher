import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/tab_button.dart';
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

    return Container(
      width: width,
      height: Constants.topBarHeight,
      color: Constants.backgroundColor,
      child: Stack(
        children: [
          MoveWindow(),
          Container(
            height: Constants.topBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: Constants.horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  height: Constants.topBarHeight,
                  width: 100,
                  color: Constants.mainColor,
                  alignment: Alignment.center,
                  child: const Text("X",
                      style: TextStyle(color: Colors.white)), //LOGO PLACEHOLDER
                ),
                tabs(),
                windowButtons(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget tabs() {
    final l = Utility.getLocalizations(context);

    return Container(
      width: MediaQuery.of(context).size.width * 0.2,
      constraints: const BoxConstraints(minWidth: 360),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TabButton(
            label: l.home,
            icon: Icons.home,
            tab: 0,
          ),
          TabButton(
            label: l.map,
            icon: Icons.map,
            tab: 1,
          ),
          TabButton(
            label: l.settings,
            icon: Icons.settings,
            tab: 2,
          ),
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
