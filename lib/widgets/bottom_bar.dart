import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:launcher/utils/data.dart';
import 'package:launcher/utils/minecraft.dart';
import 'package:launcher/widgets/mouse_icon_button.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<StatefulWidget> createState() {
    return _BottomBarState();
  }
}

class _BottomBarState extends State<BottomBar> {
  int rotation = 0;
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    Color textColor = Colors.white.withOpacity(0.2);
    TextStyle brandStyle = TextStyle(
      color: textColor,
      fontSize: 10,
      fontWeight: FontWeight.bold,
    );

    return Container(
      height: 65,
      color: const Color(0xff23162A),
      padding: EdgeInsets.symmetric(horizontal: width * 0.06),
      child: Stack(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (++taps % 5 == 0) {
                        setState(() => rotation -= 1);
                      }
                    },
                    child: Container(
                      width: 40,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      margin: const EdgeInsets.only(right: 10),
                      child: AnimatedRotation(
                          turns: rotation.toDouble(),
                          duration: const Duration(milliseconds: 280),
                          child: SvgPicture.asset("assets/amper.svg",
                              color: textColor)),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("BOLUDO´S COMPANY ®", style: brandStyle),
                      Text("NOT AFFILIATED WITH MOJANG. AB.", style: brandStyle)
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  MouseIconButton(
                    icon: Icons.image,
                    size: 17.0,
                    toolTip: "Screenshots",
                    color: textColor,
                    hoverColor: Colors.white.withOpacity(0.5),
                    backgroundSize: 35.0,
                    backgroundColor: Colors.white.withOpacity(0.12),
                    onTap: () async {
                      Directory screenshots =
                          Directory("$minecraftPath/screenshots");

                      await screenshots.create();
                      launchUrlString("file://${screenshots.path}");
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                    child: MouseIconButton(
                      icon: Icons.autorenew,
                      size: 17.0,
                      toolTip: "Sincronizar",
                      color: textColor,
                      hoverColor: Colors.white.withOpacity(0.5),
                      backgroundSize: 35.0,
                      backgroundColor: Colors.white.withOpacity(0.12),
                      onTap: () => print("reload"),
                    ),
                  ),
                  Container(
                    height: 35,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: Colors.white.withOpacity(0.12).withOpacity(0.06),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          "Fullscreen",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          width: 25,
                          margin: const EdgeInsets.only(left: 8),
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: Transform.scale(
                              scale: 0.5,
                              child: CupertinoSwitch(
                                value: Minecraft.fullscreen,
                                activeColor: const Color(0xff7a4aee),
                                onChanged: (val) =>
                                    setState(() => Minecraft.fullscreen = val),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
          Center(
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Container(
                height: double.infinity,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withAlpha(75),
                        blurRadius: 50.0,
                        spreadRadius: 50.0,
                        offset: const Offset(
                          0.0,
                          20.0,
                        ),
                      ),
                    ]),
                child: CupertinoButton.filled(
                  borderRadius: BorderRadius.zero,
                  child: const Text(
                    "PLAY",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => Minecraft.test(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
