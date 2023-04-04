import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:launcher/utils/git.dart';
import 'package:launcher/widgets/navbar.dart';

void main() {
  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(1400, 800);
    appWindow.minSize = Size(1150, 0);
    //appWindow.maxSize = initialSize;
    appWindow.size = initialSize;
    appWindow.show();
  });
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
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
      body: Column(
        children: [
          const NavBar(),
          CupertinoButton.filled(
            child: const Text("BUTTON"),
            onPressed: () {
              Git.test();
            },
          ),
        ],
      ),
    );
  }
}
