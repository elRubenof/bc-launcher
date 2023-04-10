import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:launcher/utils/data.dart';
import 'package:launcher/utils/utility.dart';
import 'package:launcher/widgets/mouse_icon_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<StatefulWidget> createState() {
    return _BottomBarState();
  }
}

class _BottomBarState extends State<BottomBar> {
  ValueNotifier<bool> isLaunching = ValueNotifier(false);

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

    return Column(
      children: [
        ValueListenableBuilder(
          valueListenable: isLaunching,
          builder: (context, bool value, _) {
            return value ? const LinearProgressIndicator() : Container();
          },
        ),
        Container(
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
                          Text("NOT AFFILIATED WITH MOJANG. AB.",
                              style: brandStyle)
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
                          toolTip: "Recargar",
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
                          color:
                              Colors.white.withOpacity(0.12).withOpacity(0.06),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              "Auto-Conectarse",
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
                                    value: Utility.autoConnect,
                                    activeColor: const Color(0xff7a4aee),
                                    onChanged: (val) async {
                                      (await SharedPreferences.getInstance())
                                          .setBool('autoConnect', val);

                                      setState(() => Utility.autoConnect = val);
                                    },
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
                      onPressed: () => launch(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  void launch() async {
    if (isLaunching.value) return;

    String uuid = Utility.selectedAccount.uuid;
    String username = Utility.selectedAccount.username;
    String bearer = Utility.selectedAccount.bearer;
    String version = "1.19.4";

    isLaunching.value = true;

    await Process.start('java', [
      '-Xmx${Utility.allocatedRAM}G',
      '-XstartOnFirstThread',
      '-Djava.library.path=$minecraftPath/versions/1.19.4/natives',
      '-Dminecraft.launcher.brand=minecraft-launcher-lib',
      '-Dminecraft.launcher.version=5.3',
      '-cp',
      '$minecraftPath/libraries/ca/weblite/java-objc-bridge/1.1/java-objc-bridge-1.1.jar:$minecraftPath/libraries/com/github/oshi/oshi-core/6.2.2/oshi-core-6.2.2.jar:$minecraftPath/libraries/com/google/code/gson/gson/2.10/gson-2.10.jar:$minecraftPath/libraries/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar:$minecraftPath/libraries/com/google/guava/guava/31.1-jre/guava-31.1-jre.jar:$minecraftPath/libraries/com/ibm/icu/icu4j/71.1/icu4j-71.1.jar:$minecraftPath/libraries/com/mojang/authlib/3.18.38/authlib-3.18.38.jar:$minecraftPath/libraries/com/mojang/blocklist/1.0.10/blocklist-1.0.10.jar:$minecraftPath/libraries/com/mojang/brigadier/1.0.18/brigadier-1.0.18.jar:$minecraftPath/libraries/com/mojang/datafixerupper/6.0.6/datafixerupper-6.0.6.jar:$minecraftPath/libraries/com/mojang/logging/1.1.1/logging-1.1.1.jar:$minecraftPath/libraries/com/mojang/patchy/2.2.10/patchy-2.2.10.jar:$minecraftPath/libraries/com/mojang/text2speech/1.13.9/text2speech-1.13.9.jar:$minecraftPath/libraries/commons-codec/commons-codec/1.15/commons-codec-1.15.jar:$minecraftPath/libraries/commons-io/commons-io/2.11.0/commons-io-2.11.0.jar:$minecraftPath/libraries/commons-logging/commons-logging/1.2/commons-logging-1.2.jar:$minecraftPath/libraries/io/netty/netty-buffer/4.1.82.Final/netty-buffer-4.1.82.Final.jar:$minecraftPath/libraries/io/netty/netty-codec/4.1.82.Final/netty-codec-4.1.82.Final.jar:$minecraftPath/libraries/io/netty/netty-common/4.1.82.Final/netty-common-4.1.82.Final.jar:$minecraftPath/libraries/io/netty/netty-handler/4.1.82.Final/netty-handler-4.1.82.Final.jar:$minecraftPath/libraries/io/netty/netty-resolver/4.1.82.Final/netty-resolver-4.1.82.Final.jar:$minecraftPath/libraries/io/netty/netty-transport-classes-epoll/4.1.82.Final/netty-transport-classes-epoll-4.1.82.Final.jar:$minecraftPath/libraries/io/netty/netty-transport-native-unix-common/4.1.82.Final/netty-transport-native-unix-common-4.1.82.Final.jar:$minecraftPath/libraries/io/netty/netty-transport/4.1.82.Final/netty-transport-4.1.82.Final.jar:$minecraftPath/libraries/it/unimi/dsi/fastutil/8.5.9/fastutil-8.5.9.jar:$minecraftPath/libraries/net/java/dev/jna/jna-platform/5.12.1/jna-platform-5.12.1.jar:$minecraftPath/libraries/net/java/dev/jna/jna/5.12.1/jna-5.12.1.jar:$minecraftPath/libraries/net/sf/jopt-simple/jopt-simple/5.0.4/jopt-simple-5.0.4.jar:$minecraftPath/libraries/org/apache/commons/commons-compress/1.21/commons-compress-1.21.jar:$minecraftPath/libraries/org/apache/commons/commons-lang3/3.12.0/commons-lang3-3.12.0.jar:$minecraftPath/libraries/org/apache/httpcomponents/httpclient/4.5.13/httpclient-4.5.13.jar:$minecraftPath/libraries/org/apache/httpcomponents/httpcore/4.4.15/httpcore-4.4.15.jar:$minecraftPath/libraries/org/apache/logging/log4j/log4j-api/2.19.0/log4j-api-2.19.0.jar:$minecraftPath/libraries/org/apache/logging/log4j/log4j-core/2.19.0/log4j-core-2.19.0.jar:$minecraftPath/libraries/org/apache/logging/log4j/log4j-slf4j2-impl/2.19.0/log4j-slf4j2-impl-2.19.0.jar:$minecraftPath/libraries/org/joml/joml/1.10.5/joml-1.10.5.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-glfw/3.3.1/lwjgl-glfw-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-glfw/3.3.1/lwjgl-glfw-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-glfw/3.3.1/lwjgl-glfw-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-jemalloc/3.3.1/lwjgl-jemalloc-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-jemalloc/3.3.1/lwjgl-jemalloc-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-jemalloc/3.3.1/lwjgl-jemalloc-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-openal/3.3.1/lwjgl-openal-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-openal/3.3.1/lwjgl-openal-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-openal/3.3.1/lwjgl-openal-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-opengl/3.3.1/lwjgl-opengl-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-opengl/3.3.1/lwjgl-opengl-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-opengl/3.3.1/lwjgl-opengl-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-stb/3.3.1/lwjgl-stb-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-stb/3.3.1/lwjgl-stb-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-stb/3.3.1/lwjgl-stb-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-tinyfd/3.3.1/lwjgl-tinyfd-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-tinyfd/3.3.1/lwjgl-tinyfd-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-tinyfd/3.3.1/lwjgl-tinyfd-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl/3.3.1/lwjgl-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl/3.3.1/lwjgl-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl/3.3.1/lwjgl-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/slf4j/slf4j-api/2.0.1/slf4j-api-2.0.1.jar:$minecraftPath/versions/1.19.4/1.19.4.jar',
      'net.minecraft.client.main.Main',
      '--username',
      username,
      '--version',
      version,
      '--gameDir',
      minecraftPath,
      '--assetsDir',
      '$minecraftPath/assets',
      '--assetIndex',
      '3',
      '--uuid',
      uuid,
      '--accessToken',
      bearer,
      '--clientId',
      '\${clientid}',
      '--xuid',
      '\${auth_xuid}',
      '--userType',
      'mojang',
      '--versionType',
      'release',
      if (Utility.autoConnect) '--server',
      if (Utility.autoConnect) 'play.cubecraft.net'
    ]);

    if (Utility.autoClose) {
      Future.delayed(const Duration(seconds: 3)).then((value) => exit(0));
    }
  }
}
