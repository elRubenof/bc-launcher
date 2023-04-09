import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:launcher/screens/home.dart';
import 'package:launcher/screens/map.dart';
import 'package:launcher/utils/git.dart';
import 'package:launcher/utils/palette.dart';
import 'package:launcher/utils/server.dart';
import 'package:launcher/widgets/bottom_bar.dart';
import 'package:launcher/widgets/nav_bar.dart';

void main() {
  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(1400, 800);
    appWindow.minSize = const Size(1150, 700);
    appWindow.maxSize = initialSize;
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
        future: initialize(),
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
  final List<Widget> pages = const [
    HomeScreen(),
    MapScreen(),
    Text(
      "SETTINGS",
      style: TextStyle(color: Colors.white),
    )
  ];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Stack(children: [
      Column(
        children: [
          NavBar(
            currentIndex: currentIndex,
            changeIndex: [
              () => setState(() => currentIndex = 0),
              () => setState(() => currentIndex = 1),
              () => setState(() => currentIndex = 2),
            ],
          ),
          pages[currentIndex],
        ],
      ),
      AnimatedPositioned(
        duration: const Duration(milliseconds: 230),
        bottom: currentIndex == 0 ? 0 : -130,
        child: SizedBox(
          width: width,
          child: const BottomBar(),
        ),
      ),
    ]);
  }
}

Future<String> initialize() async {
  await Server.init();
  return await Git.init();
}
