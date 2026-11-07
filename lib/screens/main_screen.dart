import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/models/web_tab.dart';
import 'package:bc_launcher/screens/tabs/home_screen.dart';
import 'package:bc_launcher/screens/tabs/settings_screen.dart';
import 'package:bc_launcher/screens/tabs/web_tab_screen.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/instance_settings_store.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/bottom_bar.dart';
import 'package:bc_launcher/widgets/offline_notice.dart';
import 'package:bc_launcher/widgets/top_bar.dart';
import 'package:flutter/material.dart';

final ValueNotifier selectedTab = ValueNotifier<int>(homeTab);

const homeTab = 0;
const settingsTab = 1;

/// The tab of the instance's web tab at [index] that opens in the launcher.
int webTabIndex(int index) => 2 + index;

/// An installed instance: its tabs and Play.
class MainScreen extends StatefulWidget {
  final Organization organization;
  final Instance instance;
  final Directory folder;

  const MainScreen({
    super.key,
    required this.organization,
    required this.instance,
    required this.folder,
  });

  @override
  State<MainScreen> createState() => _MainPageState();

  /// [tab]'s URL for the signed-in player, or null if no one is.
  static Uri? resolveUrl(WebTab tab) {
    final profile = Minecraft.profile.value;
    if (profile == null) return null;
    return tab.resolveUrl(uuid: profile.uuid, name: profile.name);
  }
}

class _MainPageState extends State<MainScreen> {
  /// By [selectedTab].
  late Map<int, Widget> tabs;
  late final settings = InstanceSettingsStore(widget.folder)..load();

  @override
  void initState() {
    super.initState();

    selectedTab.value = homeTab;
    tabs = {
      homeTab: HomeScreen(
        organization: widget.organization,
        instance: widget.instance,
      ),
      for (final (i, tab) in widget.instance.tabs.indexed)
        if (tab.openIn == WebTabOpenIn.launcher)
          if (MainScreen.resolveUrl(tab) case final url?)
            webTabIndex(i): WebTabScreen(key: ValueKey(i), url: url),
      settingsTab: SettingsScreen(
        organizationKey: widget.organization.key,
        instance: widget.instance,
        folder: widget.folder,
        settings: settings,
      ),
    };
  }

  @override
  void dispose() {
    settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = InstanceTheme.fromColors(widget.instance.colors);

    return Theme(
      data: theme.apply(Theme.of(context)),
      child: Scaffold(
        backgroundColor: theme.background,
        body: ValueListenableBuilder(
          valueListenable: selectedTab,
          builder: (context, index, child) => Stack(
            children: [
              Positioned.fill(child: background()),
              Positioned.fill(
                child: ColoredBox(
                  color: theme.background.withValues(alpha: 0.85),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  top: Constants.topBarHeight,
                  bottom: index == homeTab ? Constants.topBarHeight : 0,
                ),
                child: tabs[index] ?? const SizedBox.shrink(),
              ),
              TopBar(
                organization: widget.organization,
                instance: widget.instance,
              ),
              if (index == homeTab) offlineNotice(theme),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 250),
                bottom: index == homeTab ? 0 : -200,
                child: BottomBar(
                  organization: widget.organization,
                  instance: widget.instance,
                  folder: widget.folder,
                  settings: settings,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Over the bottom bar while the organization doesn't answer: what is
  /// installed is played as it is.
  Widget offlineNotice(InstanceTheme theme) {
    final l = Utility.getLocalizations(context);
    final organization = widget.organization;

    return Positioned(
      left: 20,
      bottom: Constants.topBarHeight + 16,
      child: ValueListenableBuilder(
        valueListenable: InstanceCatalog.organizations,
        builder: (context, _, _) {
          final status = InstanceCatalog.viewOf(organization.key).status;
          if (status != OrganizationStatus.offline) {
            return const SizedBox.shrink();
          }
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 470),
            child: OfflineNotice(
              title: l.organizationNotResponding(organization.name),
              description: l.playingInstalledDesc,
              background: theme.background.withValues(alpha: 0.92),
              onRetry: () => InstanceCatalog.refresh(organization),
            ),
          );
        },
      ),
    );
  }

  /// The instance's background, or the launcher's when it has none or it
  /// can't be loaded.
  Widget background() {
    const fallback = Image(
      image: AssetImage("assets/img/background.png"),
      fit: BoxFit.cover,
    );
    final url = widget.instance.backgroundUrl;
    if (url.isEmpty) return fallback;

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => fallback,
    );
  }
}
