import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/widgets/top_bar.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final ValueNotifier selectedTab = ValueNotifier<int>(0);

void main() {
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

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Image.asset("assets/background.png",
              height: height, width: width, fit: BoxFit.cover),
          Container(
            height: height,
            color: Constants.backgroundColor.withOpacity(0.85),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Constants.topBarHeight),
            child: ValueListenableBuilder(
              valueListenable: selectedTab,
              builder: (context, value, child) => Constants.pages[value],
            ),
          ),
          const TopBar(),
        ],
      ),
    );
  }
}
