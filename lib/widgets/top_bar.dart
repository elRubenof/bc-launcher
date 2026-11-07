import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/models/web_tab.dart';
import 'package:bc_launcher/screens/main_screen.dart';
import 'package:bc_launcher/screens/organizations_screen.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/screens/login_screen.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/instance_initials.dart';
import 'package:bc_launcher/widgets/tab_button.dart';
import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
      color: InstanceTheme.of(context).background,
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
                const WindowButtons(enableSettings: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// The instance's icon, or the organization's logo when it has none;
  /// its initials, like in its card, when neither can be shown.
  Widget logo() {
    const size = Constants.topBarHeight * 0.75;
    final initials = InstanceInitials(instance: widget.instance, size: size);
    final url = widget.instance.iconUrl ?? widget.organization.logoUrl;
    return Container(
      height: Constants.topBarHeight,
      width: 100,
      alignment: Alignment.center,
      child: url == null
          ? initials
          : Image.network(
              url,
              height: size,
              errorBuilder: (context, error, stackTrace) => initials,
            ),
    );
  }

  /// Home, the instance's web tabs and Settings.
  Widget tabs() {
    final l = Utility.getLocalizations(context);
    final webTabs = widget.instance.tabs;
    final tabsNumber = 2 + webTabs.length;

    return Flexible(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.067 * tabsNumber,
        constraints: BoxConstraints(minWidth: 120.0 * tabsNumber),
        // Spread like before when they fit; smaller when they don't.
        child: LayoutBuilder(
          builder: (context, box) => FittedBox(
            fit: BoxFit.scaleDown,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: box.maxWidth,
                minHeight: box.maxHeight,
                maxHeight: box.maxHeight,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: 28,
                children: [
                  TabButton(label: l.home, icon: Icons.home, tab: homeTab),
                  for (final (i, tab) in webTabs.indexed)
                    TabButton(
                      label: tab.label,
                      icon: webTabIcon(tab.icon),
                      tab: tab.openIn == WebTabOpenIn.launcher
                          ? webTabIndex(i)
                          : null,
                      onTap: tab.openIn == WebTabOpenIn.browser
                          ? () => openInBrowser(tab)
                          : null,
                    ),
                  TabButton(
                    label: l.settings,
                    icon: Icons.settings,
                    tab: settingsTab,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens [tab] in the system browser; the launcher stays where it is.
  void openInBrowser(WebTab tab) {
    final url = MainScreen.resolveUrl(tab);
    if (url != null) launchUrl(url, mode: LaunchMode.externalApplication);
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
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      size: 25,
                      color: InstanceTheme.of(context).text,
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(maxWidth: 84),
                  child: Text(
                    value.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: InstanceTheme.of(context).text,
                      fontSize: 12,
                    ),
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

/// The icon of each of the contract's web tab icons.
IconData webTabIcon(WebTabIcon icon) {
  return switch (icon) {
    WebTabIcon.map => Icons.map,
    WebTabIcon.trophy => Icons.emoji_events,
    WebTabIcon.calendar => Icons.calendar_month,
    WebTabIcon.book => Icons.menu_book,
    WebTabIcon.chart => Icons.bar_chart,
    WebTabIcon.live => Icons.live_tv,
    WebTabIcon.users => Icons.group,
    WebTabIcon.list => Icons.list,
    WebTabIcon.form => Icons.assignment,
    WebTabIcon.globe => Icons.public,
  };
}
