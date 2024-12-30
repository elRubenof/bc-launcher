import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/tab_button.dart';
import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
            padding: const EdgeInsets.symmetric(
              horizontal: Constants.horizontalPadding,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                logo(),
                tabs(),
                windowButtons(),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget logo() {
    if (Constants.appLogo.isEmpty) {
      return const SizedBox();
    }

    return Container(
      height: Constants.topBarHeight,
      width: 100,
      color: Constants.mainColor,
      alignment: Alignment.center,
      child: SvgPicture.asset(
        Constants.appLogo,
        height: Constants.topBarHeight * 0.75,
        colorFilter: const ColorFilter.mode(
          Constants.textColor,
          BlendMode.srcIn,
        ),
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
}

Widget windowButtons({bool enableSettings = true}) {
  return SizedBox(
    width: enableSettings ? 100 : 66,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (enableSettings)
          MouseIconButton(
            icon: Icons.settings,
            size: 14.0,
            backgroundColor: Colors.white,
            onTap: () => appWindow.minimize(),
          ),
        MouseIconButton(
          icon: Icons.minimize,
          size: 14.0,
          backgroundColor: Colors.white,
          onTap: () => appWindow.minimize(),
        ),
        MouseIconButton(
          icon: Icons.close,
          size: 14.0,
          backgroundColor: Colors.white,
          onTap: () => appWindow.close(),
        ),
      ],
    ),
  );
}
