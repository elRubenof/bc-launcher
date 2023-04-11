import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:launcher/utils/data.dart';
import 'package:launcher/utils/git.dart';
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
                          toolTip: "Sincronizar",
                          color: textColor,
                          hoverColor: Colors.white.withOpacity(0.5),
                          backgroundSize: 35.0,
                          backgroundColor: Colors.white.withOpacity(0.12),
                          onTap: () async {
                            Utility.isLoading.value = true;

                            await Git.init();

                            Utility.isLoading.value = false;
                          },
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
    String version = "1.19.2-forge-43.1.1";

    isLaunching.value = true;

    await Process.start('java', [
      '-Xmx${Utility.allocatedRAM}G',
      '-XstartOnFirstThread',
      '-Djava.library.path=$minecraftPath/versions/$version/natives',
      '-Dminecraft.launcher.brand=minecraft-launcher-lib',
      '-Dminecraft.launcher.version=5.3',
      '-cp',
      '$minecraftPath/libraries/cpw/mods/securejarhandler/2.1.4/securejarhandler-2.1.4.jar:$minecraftPath/libraries/org/ow2/asm/asm/9.3/asm-9.3.jar:$minecraftPath/libraries/org/ow2/asm/asm-commons/9.3/asm-commons-9.3.jar:$minecraftPath/libraries/org/ow2/asm/asm-tree/9.3/asm-tree-9.3.jar:$minecraftPath/libraries/org/ow2/asm/asm-util/9.3/asm-util-9.3.jar:$minecraftPath/libraries/org/ow2/asm/asm-analysis/9.3/asm-analysis-9.3.jar:$minecraftPath/libraries/net/minecraftforge/accesstransformers/8.0.4/accesstransformers-8.0.4.jar:$minecraftPath/libraries/org/antlr/antlr4-runtime/4.9.1/antlr4-runtime-4.9.1.jar:$minecraftPath/libraries/net/minecraftforge/eventbus/6.0.3/eventbus-6.0.3.jar:$minecraftPath/libraries/net/minecraftforge/forgespi/6.0.0/forgespi-6.0.0.jar:$minecraftPath/libraries/net/minecraftforge/coremods/5.0.1/coremods-5.0.1.jar:$minecraftPath/libraries/cpw/mods/modlauncher/10.0.8/modlauncher-10.0.8.jar:$minecraftPath/libraries/net/minecraftforge/unsafe/0.2.0/unsafe-0.2.0.jar:$minecraftPath/libraries/com/electronwill/night-config/core/3.6.4/core-3.6.4.jar:$minecraftPath/libraries/com/electronwill/night-config/toml/3.6.4/toml-3.6.4.jar:$minecraftPath/libraries/org/apache/maven/maven-artifact/3.8.5/maven-artifact-3.8.5.jar:$minecraftPath/libraries/net/jodah/typetools/0.8.3/typetools-0.8.3.jar:$minecraftPath/libraries/net/minecrell/terminalconsoleappender/1.2.0/terminalconsoleappender-1.2.0.jar:$minecraftPath/libraries/org/jline/jline-reader/3.12.1/jline-reader-3.12.1.jar:$minecraftPath/libraries/org/jline/jline-terminal/3.12.1/jline-terminal-3.12.1.jar:$minecraftPath/libraries/org/spongepowered/mixin/0.8.5/mixin-0.8.5.jar:$minecraftPath/libraries/org/openjdk/nashorn/nashorn-core/15.3/nashorn-core-15.3.jar:$minecraftPath/libraries/net/minecraftforge/JarJarSelector/0.3.16/JarJarSelector-0.3.16.jar:$minecraftPath/libraries/net/minecraftforge/JarJarMetadata/0.3.16/JarJarMetadata-0.3.16.jar:$minecraftPath/libraries/cpw/mods/bootstraplauncher/1.1.2/bootstraplauncher-1.1.2.jar:$minecraftPath/libraries/net/minecraftforge/JarJarFileSystems/0.3.16/JarJarFileSystems-0.3.16.jar:$minecraftPath/libraries/net/minecraftforge/fmlloader/1.19.2-43.1.1/fmlloader-1.19.2-43.1.1.jar:$minecraftPath/libraries/com/mojang/logging/1.0.0/logging-1.0.0.jar:$minecraftPath/libraries/com/mojang/blocklist/1.0.10/blocklist-1.0.10.jar:$minecraftPath/libraries/com/mojang/patchy/2.2.10/patchy-2.2.10.jar:$minecraftPath/libraries/com/github/oshi/oshi-core/5.8.5/oshi-core-5.8.5.jar:$minecraftPath/libraries/net/java/dev/jna/jna/5.10.0/jna-5.10.0.jar:$minecraftPath/libraries/net/java/dev/jna/jna-platform/5.10.0/jna-platform-5.10.0.jar:$minecraftPath/libraries/org/slf4j/slf4j-api/1.8.0-beta4/slf4j-api-1.8.0-beta4.jar:$minecraftPath/libraries/org/apache/logging/log4j/log4j-slf4j18-impl/2.17.0/log4j-slf4j18-impl-2.17.0.jar:$minecraftPath/libraries/com/ibm/icu/icu4j/70.1/icu4j-70.1.jar:$minecraftPath/libraries/com/mojang/javabridge/1.2.24/javabridge-1.2.24.jar:$minecraftPath/libraries/net/sf/jopt-simple/jopt-simple/5.0.4/jopt-simple-5.0.4.jar:$minecraftPath/libraries/io/netty/netty-common/4.1.77.Final/netty-common-4.1.77.Final.jar:$minecraftPath/libraries/io/netty/netty-buffer/4.1.77.Final/netty-buffer-4.1.77.Final.jar:$minecraftPath/libraries/io/netty/netty-codec/4.1.77.Final/netty-codec-4.1.77.Final.jar:$minecraftPath/libraries/io/netty/netty-handler/4.1.77.Final/netty-handler-4.1.77.Final.jar:$minecraftPath/libraries/io/netty/netty-resolver/4.1.77.Final/netty-resolver-4.1.77.Final.jar:$minecraftPath/libraries/io/netty/netty-transport/4.1.77.Final/netty-transport-4.1.77.Final.jar:$minecraftPath/libraries/io/netty/netty-transport-native-unix-common/4.1.77.Final/netty-transport-native-unix-common-4.1.77.Final.jar:$minecraftPath/libraries/io/netty/netty-transport-classes-epoll/4.1.77.Final/netty-transport-classes-epoll-4.1.77.Final.jar:$minecraftPath/libraries/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar:$minecraftPath/libraries/com/google/guava/guava/31.0.1-jre/guava-31.0.1-jre.jar:$minecraftPath/libraries/org/apache/commons/commons-lang3/3.12.0/commons-lang3-3.12.0.jar:$minecraftPath/libraries/commons-io/commons-io/2.11.0/commons-io-2.11.0.jar:$minecraftPath/libraries/commons-codec/commons-codec/1.15/commons-codec-1.15.jar:$minecraftPath/libraries/com/mojang/brigadier/1.0.18/brigadier-1.0.18.jar:$minecraftPath/libraries/com/mojang/datafixerupper/5.0.28/datafixerupper-5.0.28.jar:$minecraftPath/libraries/com/google/code/gson/gson/2.8.9/gson-2.8.9.jar:$minecraftPath/libraries/com/mojang/authlib/3.11.49/authlib-3.11.49.jar:$minecraftPath/libraries/org/apache/commons/commons-compress/1.21/commons-compress-1.21.jar:$minecraftPath/libraries/org/apache/httpcomponents/httpclient/4.5.13/httpclient-4.5.13.jar:$minecraftPath/libraries/commons-logging/commons-logging/1.2/commons-logging-1.2.jar:$minecraftPath/libraries/org/apache/httpcomponents/httpcore/4.4.14/httpcore-4.4.14.jar:$minecraftPath/libraries/it/unimi/dsi/fastutil/8.5.6/fastutil-8.5.6.jar:$minecraftPath/libraries/org/apache/logging/log4j/log4j-api/2.17.0/log4j-api-2.17.0.jar:$minecraftPath/libraries/org/apache/logging/log4j/log4j-core/2.17.0/log4j-core-2.17.0.jar:$minecraftPath/libraries/org/lwjgl/lwjgl/3.3.1/lwjgl-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl/3.3.1/lwjgl-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl/3.3.1/lwjgl-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-jemalloc/3.3.1/lwjgl-jemalloc-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-jemalloc/3.3.1/lwjgl-jemalloc-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-jemalloc/3.3.1/lwjgl-jemalloc-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-openal/3.3.1/lwjgl-openal-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-openal/3.3.1/lwjgl-openal-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-openal/3.3.1/lwjgl-openal-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-opengl/3.3.1/lwjgl-opengl-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-opengl/3.3.1/lwjgl-opengl-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-opengl/3.3.1/lwjgl-opengl-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-glfw/3.3.1/lwjgl-glfw-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-glfw/3.3.1/lwjgl-glfw-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-glfw/3.3.1/lwjgl-glfw-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-stb/3.3.1/lwjgl-stb-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-stb/3.3.1/lwjgl-stb-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-stb/3.3.1/lwjgl-stb-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-tinyfd/3.3.1/lwjgl-tinyfd-3.3.1.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-tinyfd/3.3.1/lwjgl-tinyfd-3.3.1-natives-macos.jar:$minecraftPath/libraries/org/lwjgl/lwjgl-tinyfd/3.3.1/lwjgl-tinyfd-3.3.1-natives-macos-arm64.jar:$minecraftPath/libraries/com/mojang/text2speech/1.13.9/text2speech-1.13.9.jar:$minecraftPath/libraries/ca/weblite/java-objc-bridge/1.1/java-objc-bridge-1.1.jar:$minecraftPath/versions/$version/$version.jar',
      '-Djava.net.preferIPv6Addresses=system',
      '-DignoreList=bootstraplauncher,securejarhandler,asm-commons,asm-util,asm-analysis,asm-tree,asm,JarJarFileSystems,client-extra,fmlcore,javafmllanguage,lowcodelanguage,mclanguage,forge-,$version.jar',
      '-DmergeModules=jna-5.10.0.jar,jna-platform-5.10.0.jar',
      '-DlibraryDirectory=$minecraftPath/libraries',
      '-p',
      '$minecraftPath/libraries/cpw/mods/bootstraplauncher/1.1.2/bootstraplauncher-1.1.2.jar:$minecraftPath/libraries/cpw/mods/securejarhandler/2.1.4/securejarhandler-2.1.4.jar:$minecraftPath/libraries/org/ow2/asm/asm-commons/9.3/asm-commons-9.3.jar:$minecraftPath/libraries/org/ow2/asm/asm-util/9.3/asm-util-9.3.jar:$minecraftPath/libraries/org/ow2/asm/asm-analysis/9.3/asm-analysis-9.3.jar:$minecraftPath/libraries/org/ow2/asm/asm-tree/9.3/asm-tree-9.3.jar:$minecraftPath/libraries/org/ow2/asm/asm/9.3/asm-9.3.jar:$minecraftPath/libraries/net/minecraftforge/JarJarFileSystems/0.3.16/JarJarFileSystems-0.3.16.jar',
      '--add-modules',
      'ALL-MODULE-PATH',
      '--add-opens',
      'java.base/java.util.jar=cpw.mods.securejarhandler',
      '--add-opens',
      'java.base/java.lang.invoke=cpw.mods.securejarhandler',
      '--add-exports',
      'java.base/sun.security.util=cpw.mods.securejarhandler',
      '--add-exports',
      'jdk.naming.dns/com.sun.jndi.dns=java.naming',
      'cpw.mods.bootstraplauncher.BootstrapLauncher',
      '--username',
      username,
      '--version',
      '1.19.2-forge-43.1.1',
      '--gameDir',
      minecraftPath,
      '--assetsDir',
      '$minecraftPath/assets',
      '--assetIndex',
      '1.19',
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
      '--launchTarget',
      'forgeclient',
      '--fml.forgeVersion',
      '43.1.1',
      '--fml.mcVersion',
      '1.19.2',
      '--fml.forgeGroup',
      'net.minecraftforge',
      '--fml.mcpVersion',
      '20220805.130853',
      if (Utility.autoConnect) '--server',
      if (Utility.autoConnect) 'play.cubecraft.net'
    ]);

    await Future.delayed(const Duration(seconds: 5));

    if (Utility.autoClose) exit(0);
    isLaunching.value = false;
  }
}
