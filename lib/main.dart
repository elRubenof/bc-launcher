import 'package:bc_launcher/screens/home_screen.dart';
import 'package:bc_launcher/screens/login_screen.dart';
import 'package:bc_launcher/screens/map_screen.dart';
import 'package:bc_launcher/screens/settings_screen.dart';
import 'package:bc_launcher/screens/update_screen.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/bottom_bar.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/top_bar.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final ValueNotifier selectedTab = ValueNotifier<int>(0);
bool _updated = false;

void main() async {
  await Utility.loadSettings();
  _updated = await Utility.isUpdated();

  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(1280, 750);
    appWindow.minSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: Utility.key,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: _updated ? const MainPage() : const UpdateScreen(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final List<Widget> tabs = const [
    HomeScreen(),
    MapScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    Utility.init();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: ValueListenableBuilder(
        valueListenable: Utility.isLoging,
        builder: (context, isLoging, child) {
          if (isLoging) return const LoginScreen();

          return ValueListenableBuilder(
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
                const TopBar(),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  bottom: index == 0 ? 0 : -200,
                  child: const BottomBar(),
                ),
                ValueListenableBuilder(
                  valueListenable: Utility.isLoading,
                  builder: (context, value, child) => value
                      ? Container(
                          width: width,
                          height: height,
                          color: Constants.backgroundColor,
                          child: const LoadingWidget(),
                        )
                      : Container(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
