import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/screens/organizations_screen.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/screens/login_screen.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/tab_button.dart';
import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class TopBar extends StatefulWidget {
  final Organization organization;
  final Instance instance;

  const TopBar({super.key, required this.organization, required this.instance});

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
          // Not const: `flutter run` fails to compile a const DragToMoveArea.
          // ignore: prefer_const_constructors
          DragToMoveArea(child: SizedBox.expand()),
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
                account(widget.organization),
                const WindowButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The instance's icon, or the organization's logo when it has none.
  Widget logo() {
    final url = widget.instance.iconUrl ?? widget.organization.logoUrl;
    return Container(
      height: Constants.topBarHeight,
      width: 100,
      alignment: Alignment.center,
      child: url == null
          ? null
          : Image.network(
              url,
              height: Constants.topBarHeight * 0.75,
              errorBuilder: (context, error, stackTrace) => Container(),
            ),
    );
  }

  Widget tabs() {
    final l = Utility.getLocalizations(context);
    const tabsNumber = 2;

    return Container(
      width: MediaQuery.of(context).size.width * 0.067 * tabsNumber,
      constraints: const BoxConstraints(minWidth: 120.0 * tabsNumber),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TabButton(label: l.home, icon: Icons.home, tab: 0),
          TabButton(label: l.settings, icon: Icons.settings, tab: 2),
        ],
      ),
    );
  }
}

Widget account(Organization organization) {
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
                    "https://crafthead.net/avatar/${value.uuid}",
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
                await OrganizationStore.clearLastInstance(organization.key);

                Utility.pushReplacement(context, const OrganizationsScreen());
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
