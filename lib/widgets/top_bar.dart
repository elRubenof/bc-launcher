import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/tab_button.dart';
import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class TopBar extends StatefulWidget {
  const TopBar({super.key});

  @override
  State<TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  final tabsNumber = Constants.mapUrl.isNotEmpty ? 3 : 2;

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
                account(),
                const WindowButtons(),
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
      width: MediaQuery.of(context).size.width * 0.067 * tabsNumber,
      constraints: BoxConstraints(minWidth: 120.0 * tabsNumber),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TabButton(
            label: l.home,
            icon: Icons.home,
            tab: 0,
          ),
          if (Constants.mapUrl.isNotEmpty)
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

Widget account() {
  return ValueListenableBuilder(
    valueListenable: Minecraft.profile,
    builder: (context, value, child) {
      if (value == null) return Container();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        width: 215,
        height: double.infinity,
        color: Colors.white.withOpacity(0.06),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 25,
                  margin: const EdgeInsets.only(right: 14),
                  child: Image.network(
                      "https://mc-heads.net/avatar/${value.name}"),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 84),
                  child: Text(
                    value.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                )
              ],
            ),
            Container(
              color: Colors.white.withOpacity(0.15),
              margin: const EdgeInsets.only(left: 7),
              width: 1.5,
              height: 25,
            ),
            MouseIconButton(
              icon: Icons.logout_rounded,
              color: Colors.white.withOpacity(0.2),
              hoverColor: Colors.red[700],
              size: 18.0,
              onTap: Minecraft.logout,
            ),
          ],
        ),
      );
    },
  );
}
