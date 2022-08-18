import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

void main() {
  runApp(const MyApp());

  doWhenWindowReady(() {
    const initialSize = Size(1400, 800);
    appWindow.minSize = initialSize;
    appWindow.maxSize = initialSize;
    appWindow.size = initialSize;
    appWindow.alignment = Alignment.center;
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
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xff1b0a20),
      body: Column(
        children: [
          Container(
            color: const Color(0xff23162A),
            height: height * 0.08,
            child: MoveWindow(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: EdgeInsets.only(left: width * 0.088),
                    padding: EdgeInsets.symmetric(vertical: height * 0.01),
                    width: width * 0.075,
                    height: height,
                    color: const Color(0xffA83CBB),
                    child: SvgPicture.asset(
                      "assets/logo.svg",
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(
                    width: width * 0.27,
                    height: height,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Stack(children: [
                          Positioned.fill(
                              child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xffA83CBB)
                                                .withAlpha(75),
                                            blurRadius: 45.0,
                                            spreadRadius: 45.0,
                                            offset: const Offset(
                                              0.0,
                                              -55.0,
                                            ),
                                          ),
                                        ]),
                                  ))),
                          Opacity(
                            opacity: 1,
                            child: Center(
                                child: Row(
                              children: const [
                                Icon(
                                  Icons.home,
                                  color: Color(0xffA83CBB),
                                  size: 25,
                                ),
                                SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  "INICIO",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                )
                              ],
                            )),
                          )
                        ]),
                        Opacity(
                          opacity: 0.7,
                          child: Row(
                            children: const [
                              Icon(
                                Icons.list,
                                color: Color(0xffA83CBB),
                                size: 25,
                              ),
                              SizedBox(
                                width: 12,
                              ),
                              Text(
                                "MODS",
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12),
                              )
                            ],
                          ),
                        ),
                        Opacity(
                            opacity: 0.7,
                            child: Row(
                              children: const [
                                Icon(
                                  Icons.settings,
                                  color: Color(0xffA83CBB),
                                  size: 25,
                                ),
                                SizedBox(
                                  width: 12,
                                ),
                                Text(
                                  "AJUSTES",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                )
                              ],
                            )),
                      ],
                    ),
                  ),
                  Container(
                      padding: EdgeInsets.symmetric(horizontal: width * 0.015),
                      width: width * 0.195,
                      height: height,
                      color: Colors.white.withOpacity(0.06),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                  width: width * 0.018,
                                  margin: EdgeInsets.symmetric(
                                      horizontal: width * 0.01),
                                  child: Image.network(
                                      "https://crafatar.com/avatars/4d17d85a-accc-49ae-9a4f-b6b5a965cf1e?size=100")),
                              Container(
                                  constraints:
                                      BoxConstraints(maxWidth: width * 0.06),
                                  child: const Text(
                                    "elRubenof_YT",
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 10.5),
                                  )),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                          Container(
                            color: Colors.white.withOpacity(0.2),
                            width: width * 0.0007,
                            height: height * 0.03,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.white.withOpacity(0.2),
                                size: width * 0.013,
                              ),
                              Icon(
                                Icons.notifications,
                                color: Colors.white,
                                size: width * 0.013,
                              ),
                            ],
                          )
                        ],
                      )),
                  Container(
                      margin: EdgeInsets.only(right: width * 0.05),
                      width: width * 0.075,
                      child: Platform.isMacOS
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () => print("SETTINGS"),
                                  child: Container(
                                    width: width * 0.02,
                                    height: width * 0.02,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                    child: const Icon(
                                      Icons.settings,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => appWindow.minimize(),
                                  child: Container(
                                    width: width * 0.02,
                                    height: width * 0.02,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                    child: const Icon(
                                      Icons.minimize,
                                      color: Colors.white,
                                      size: 15,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                    onTap: () => appWindow.close(),
                                    child: Container(
                                      width: width * 0.02,
                                      height: width * 0.02,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        color: Colors.white.withOpacity(0.06),
                                      ),
                                      child: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                    )),
                              ],
                            )
                          : null),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
