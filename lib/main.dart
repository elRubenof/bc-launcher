import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/bottom_bar.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/top_bar.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final ValueNotifier selectedTab = ValueNotifier<int>(0);

void main() async {
  Utility.init();
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
    return MaterialApp(
      navigatorKey: Utility.key,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const MainPage(),
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
      body: ValueListenableBuilder(
        valueListenable: selectedTab,
        builder: (context, index, child) => Stack(
          children: [
            Image.asset("assets/img/background.png",
                height: height, width: width, fit: BoxFit.cover),
            Container(
              height: height,
              color: Constants.backgroundColor.withOpacity(0.85),
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: Constants.topBarHeight),
              child: Constants.pages[index],
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
      ),
    );
  }
}
