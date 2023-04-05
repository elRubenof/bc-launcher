import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:launcher/screens/map.dart';
import 'package:launcher/utils/git.dart';
import 'package:launcher/utils/palette.dart';
import 'package:launcher/widgets/bottom_bar.dart';
import 'package:launcher/widgets/nav_bar.dart';

void main() {
  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(1400, 800);
    appWindow.minSize = const Size(1150, 0);
    //appWindow.maxSize = initialSize;
    appWindow.size = initialSize;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Palette.kPurple,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff1b0a20),
      body: FutureBuilder(
        future: Git.init(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.data as String != "Success") {
            Scaffold.of(context)
                .showBottomSheet((context) => Text(snapshot.data as String));

            return Container();
          }

          return const MainScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MainScreenState();
  }
}

class _MainScreenState extends State<MainScreen> {
  int currentIndex = 0;
  final List<Widget> pages = [
    const Text(
      "INICIO",
      style: const TextStyle(color: Colors.white),
    ),
    ExampleBrowser(),
    const Text(
      "SETTINGS",
      style: const TextStyle(color: Colors.white),
    )
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        NavBar(
          currentIndex: currentIndex,
          changeIndex: [
            () => setState(() => currentIndex = 0),
            () => setState(() => currentIndex = 1),
            () => setState(() => currentIndex = 2),
          ],
        ),
        Expanded(
          child: pages[currentIndex],
        ),
        const BottomBar(),
      ],
    );
  }
}
