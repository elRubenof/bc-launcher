import 'package:bc_launcher/screens/instances_screen.dart';
import 'package:bc_launcher/screens/login_screen.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/tab_button.dart';
import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TopBar extends StatefulWidget {
  final Map<String, dynamic> server;

  const TopBar({super.key, required this.server});

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
              children: [logo(), tabs(), account(), const WindowButtons()],
            ),
          ),
        ],
      ),
    );
  }

  Widget logo() {
    return Container(
      height: Constants.topBarHeight,
      width: 100,
      alignment: Alignment.center,
      child: Image.network(
        "${Constants.api}/server/logo?id=${widget.server['id']}",
        height: Constants.topBarHeight * 0.75,
        errorBuilder: (context, error, stackTrace) => Container(),
      ),
    );
  }

  Widget tabs() {
    final l = Utility.getLocalizations(context);
    final tabsNumber = widget.server['map'] != null ? 3 : 2;

    return Container(
      width: MediaQuery.of(context).size.width * 0.067 * tabsNumber,
      constraints: BoxConstraints(minWidth: 120.0 * tabsNumber),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TabButton(label: l.home, icon: Icons.home, tab: 0),
          if (widget.server['map'] != null)
            TabButton(label: l.map, icon: Icons.map, tab: 1),
          TabButton(label: l.settings, icon: Icons.settings, tab: 2),
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

      final l = Utility.getLocalizations(context);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        width: 235,
        height: double.infinity,
        color: Colors.white.withValues(alpha: 0.06),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 25,
                  margin: const EdgeInsets.only(right: 14),
                  child: Image.network(
                    "https://mc-heads.net/avatar/${value.name}",
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 84),
                  child: Text(
                    value.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            Container(
              color: Colors.white.withValues(alpha: 0.15),
              margin: const EdgeInsets.only(left: 7),
              width: 1.5,
              height: 25,
            ),
            MouseIconButton(
              icon: Icons.density_medium,
              toolTip: l.switchInstances,
              color: Colors.white.withValues(alpha: 0.2),
              hoverColor: Colors.white.withValues(alpha: 0.7),
              size: 18.0,
              onTap: () async {
                final preferences = await SharedPreferences.getInstance();
                await preferences.remove('savedInstance');

                Utility.pushReplacement(context, const InstancesScreen());
              },
            ),
            MouseIconButton(
              icon: Icons.logout_rounded,
              toolTip: l.logout,
              color: Colors.white.withValues(alpha: 0.2),
              hoverColor: Colors.red[700],
              size: 18.0,
              onTap: () async {
                await Minecraft.logout();

                Utility.pushReplacement(context, const LoginScreen());
              },
            ),
          ],
        ),
      );
    },
  );
}
