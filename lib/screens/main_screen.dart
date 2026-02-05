import 'package:bc_launcher/screens/tabs/home_screen.dart';
import 'package:bc_launcher/screens/tabs/map_screen.dart';
import 'package:bc_launcher/screens/tabs/settings_screen.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/bottom_bar.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/top_bar.dart';
import 'package:flutter/material.dart';

final ValueNotifier selectedTab = ValueNotifier<int>(0);

class MainScreen extends StatefulWidget {
  final Map<String, dynamic> server;

  const MainScreen({super.key, required this.server});

  @override
  State<MainScreen> createState() => _MainPageState();
}

class _MainPageState extends State<MainScreen> {
  late List<Widget> tabs;

  @override
  void initState() {
    super.initState();

    selectedTab.value = 0;
    tabs = [
      const HomeScreen(),
      MapScreen(mapUrl: widget.server['map']),
      const SettingsScreen(),
    ];
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
              child: tabs[index],
            ),
            TopBar(server: widget.server),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              bottom: index == 0 ? 0 : -200,
              child: BottomBar(
                serverId: widget.server['id'],
              ),
            ),
            ValueListenableBuilder(
              valueListenable: Utility.isLoading,
              builder: (context, value, child) =>
                  value ? const LoadingScreen() : Container(),
            ),
          ],
        ),
      ),
    );
  }
}
