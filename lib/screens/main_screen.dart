import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/screens/tabs/home_screen.dart';
import 'package:bc_launcher/screens/tabs/settings_screen.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/widgets/bottom_bar.dart';
import 'package:bc_launcher/widgets/top_bar.dart';
import 'package:flutter/material.dart';

final ValueNotifier selectedTab = ValueNotifier<int>(0);

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
}

class _MainPageState extends State<MainScreen> {
  /// By [selectedTab]. The instance's news and web tabs come in phase 5.
  late Map<int, Widget> tabs;

  @override
  void initState() {
    super.initState();

    selectedTab.value = 0;
    tabs = {
      0: const HomeScreen(news: null),
      2: SettingsScreen(instance: widget.instance, folder: widget.folder),
    };
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: ValueListenableBuilder(
        valueListenable: selectedTab,
        builder: (context, index, child) => Stack(
          children: [
            Image.asset(
              "assets/img/background.png",
              height: height,
              width: width,
              fit: BoxFit.cover,
            ),
            Container(
              height: height,
              color: Constants.backgroundColor.withValues(alpha: 0.85),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: Constants.topBarHeight,
                bottom: index == 0 ? Constants.topBarHeight : 0,
              ),
              child: tabs[index] ?? const SizedBox.shrink(),
            ),
            TopBar(
              organization: widget.organization,
              instance: widget.instance,
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: index == 0 ? 0 : -200,
              child: BottomBar(
                organization: widget.organization,
                instance: widget.instance,
                folder: widget.folder,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
