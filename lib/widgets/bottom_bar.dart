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
                            setState(() => rotation += 1);
                          }
                        },
                        child: Container(
                          width: 40,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          margin: const EdgeInsets.only(right: 10),
                          child: AnimatedRotation(
                              turns: rotation.toDouble(),
                              duration: const Duration(milliseconds: 280),
                              child: SvgPicture.asset("assets/mallavia.svg",
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

    isLaunching.value = true;

    await Process.start('$minecraftPath/runtime/java-runtime-beta/windows-x64/java-runtime-beta/bin/java.exe', [   
      '-Xmx${Utility.allocatedRAM}G',      
      '-XX:HeapDumpPath=MojangTricksIntelDriversForPerformance_javaw.exe_minecraft.exe.heapdump',
      '-Dos.name=Windows 10',
      '-Dos.version=10.0',
      '-Djava.library.path=$minecraftPath/versions/1.18.2-forge-40.2.9/natives',
      '-Dminecraft.launcher.brand=minecraft-launcher-lib',
      '-Dminecraft.launcher.version=6.1',
      '-cp',
      '$minecraftPath/libraries/cpw/mods/securejarhandler/1.0.8/securejarhandler-1.0.8.jar;$minecraftPath/libraries/org/ow2/asm/asm/9.5/asm-9.5.jar;$minecraftPath/libraries/org/ow2/asm/asm-commons/9.5/asm-commons-9.5.jar;$minecraftPath/libraries/org/ow2/asm/asm-tree/9.5/asm-tree-9.5.jar;$minecraftPath/libraries/org/ow2/asm/asm-util/9.5/asm-util-9.5.jar;$minecraftPath/libraries/org/ow2/asm/asm-analysis/9.5/asm-analysis-9.5.jar;$minecraftPath/libraries/net/minecraftforge/accesstransformers/8.0.4/accesstransformers-8.0.4.jar;$minecraftPath/libraries/org/antlr/antlr4-runtime/4.9.1/antlr4-runtime-4.9.1.jar;$minecraftPath/libraries/net/minecraftforge/eventbus/5.0.3/eventbus-5.0.3.jar;$minecraftPath/libraries/net/minecraftforge/forgespi/4.0.15-4.x/forgespi-4.0.15-4.x.jar;$minecraftPath/libraries/net/minecraftforge/coremods/5.0.1/coremods-5.0.1.jar;$minecraftPath/libraries/cpw/mods/modlauncher/9.1.3/modlauncher-9.1.3.jar;$minecraftPath/libraries/net/minecraftforge/unsafe/0.2.0/unsafe-0.2.0.jar;$minecraftPath/libraries/com/electronwill/night-config/core/3.6.4/core-3.6.4.jar;$minecraftPath/libraries/com/electronwill/night-config/toml/3.6.4/toml-3.6.4.jar;$minecraftPath/libraries/org/apache/maven/maven-artifact/3.6.3/maven-artifact-3.6.3.jar;$minecraftPath/libraries/net/jodah/typetools/0.8.3/typetools-0.8.3.jar;$minecraftPath/libraries/net/minecrell/terminalconsoleappender/1.2.0/terminalconsoleappender-1.2.0.jar;$minecraftPath/libraries/org/jline/jline-reader/3.12.1/jline-reader-3.12.1.jar;$minecraftPath/libraries/org/jline/jline-terminal/3.12.1/jline-terminal-3.12.1.jar;$minecraftPath/libraries/org/spongepowered/mixin/0.8.5/mixin-0.8.5.jar;$minecraftPath/libraries/org/openjdk/nashorn/nashorn-core/15.3/nashorn-core-15.3.jar;$minecraftPath/libraries/net/minecraftforge/JarJarSelector/0.3.19/JarJarSelector-0.3.19.jar;$minecraftPath/libraries/net/minecraftforge/JarJarMetadata/0.3.19/JarJarMetadata-0.3.19.jar;$minecraftPath/libraries/cpw/mods/bootstraplauncher/1.0.0/bootstraplauncher-1.0.0.jar;$minecraftPath/libraries/net/minecraftforge/JarJarFileSystems/0.3.19/JarJarFileSystems-0.3.19.jar;$minecraftPath/libraries/net/minecraftforge/fmlloader/1.18.2-40.2.9/fmlloader-1.18.2-40.2.9.jar;$minecraftPath/libraries/com/mojang/logging/1.0.0/logging-1.0.0.jar;$minecraftPath/libraries/com/mojang/blocklist/1.0.10/blocklist-1.0.10.jar;$minecraftPath/libraries/com/mojang/patchy/2.2.10/patchy-2.2.10.jar;$minecraftPath/libraries/com/github/oshi/oshi-core/5.8.5/oshi-core-5.8.5.jar;$minecraftPath/libraries/net/java/dev/jna/jna/5.10.0/jna-5.10.0.jar;$minecraftPath/libraries/net/java/dev/jna/jna-platform/5.10.0/jna-platform-5.10.0.jar;$minecraftPath/libraries/org/slf4j/slf4j-api/1.8.0-beta4/slf4j-api-1.8.0-beta4.jar;$minecraftPath/libraries/org/apache/logging/log4j/log4j-slf4j18-impl/2.17.0/log4j-slf4j18-impl-2.17.0.jar;$minecraftPath/libraries/com/ibm/icu/icu4j/70.1/icu4j-70.1.jar;$minecraftPath/libraries/com/mojang/javabridge/1.2.24/javabridge-1.2.24.jar;$minecraftPath/libraries/net/sf/jopt-simple/jopt-simple/5.0.4/jopt-simple-5.0.4.jar;$minecraftPath/libraries/io/netty/netty-all/4.1.68.Final/netty-all-4.1.68.Final.jar;$minecraftPath/libraries/com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar;$minecraftPath/libraries/com/google/guava/guava/31.0.1-jre/guava-31.0.1-jre.jar;$minecraftPath/libraries/org/apache/commons/commons-lang3/3.12.0/commons-lang3-3.12.0.jar;$minecraftPath/libraries/commons-io/commons-io/2.11.0/commons-io-2.11.0.jar;$minecraftPath/libraries/commons-codec/commons-codec/1.15/commons-codec-1.15.jar;$minecraftPath/libraries/com/mojang/brigadier/1.0.18/brigadier-1.0.18.jar;$minecraftPath/libraries/com/mojang/datafixerupper/4.1.27/datafixerupper-4.1.27.jar;$minecraftPath/libraries/com/google/code/gson/gson/2.8.9/gson-2.8.9.jar;$minecraftPath/libraries/com/mojang/authlib/3.3.39/authlib-3.3.39.jar;$minecraftPath/libraries/org/apache/commons/commons-compress/1.21/commons-compress-1.21.jar;$minecraftPath/libraries/org/apache/httpcomponents/httpclient/4.5.13/httpclient-4.5.13.jar;$minecraftPath/libraries/commons-logging/commons-logging/1.2/commons-logging-1.2.jar;$minecraftPath/libraries/org/apache/httpcomponents/httpcore/4.4.14/httpcore-4.4.14.jar;$minecraftPath/libraries/it/unimi/dsi/fastutil/8.5.6/fastutil-8.5.6.jar;$minecraftPath/libraries/org/apache/logging/log4j/log4j-api/2.17.0/log4j-api-2.17.0.jar;$minecraftPath/libraries/org/apache/logging/log4j/log4j-core/2.17.0/log4j-core-2.17.0.jar;$minecraftPath/libraries/org/lwjgl/lwjgl/3.2.2/lwjgl-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-jemalloc/3.2.2/lwjgl-jemalloc-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-openal/3.2.2/lwjgl-openal-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-opengl/3.2.2/lwjgl-opengl-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-glfw/3.2.2/lwjgl-glfw-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-stb/3.2.2/lwjgl-stb-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-tinyfd/3.2.2/lwjgl-tinyfd-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl/3.2.2/lwjgl-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl/3.2.2/lwjgl-3.2.2-natives-windows.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-jemalloc/3.2.2/lwjgl-jemalloc-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-jemalloc/3.2.2/lwjgl-jemalloc-3.2.2-natives-windows.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-openal/3.2.2/lwjgl-openal-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-openal/3.2.2/lwjgl-openal-3.2.2-natives-windows.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-opengl/3.2.2/lwjgl-opengl-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-opengl/3.2.2/lwjgl-opengl-3.2.2-natives-windows.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-glfw/3.2.2/lwjgl-glfw-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-glfw/3.2.2/lwjgl-glfw-3.2.2-natives-windows.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-tinyfd/3.2.2/lwjgl-tinyfd-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-tinyfd/3.2.2/lwjgl-tinyfd-3.2.2-natives-windows.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-stb/3.2.2/lwjgl-stb-3.2.2.jar;$minecraftPath/libraries/org/lwjgl/lwjgl-stb/3.2.2/lwjgl-stb-3.2.2-natives-windows.jar;$minecraftPath/libraries/com/mojang/text2speech/1.12.4/text2speech-1.12.4.jar;$minecraftPath/libraries/com/mojang/text2speech/1.12.4/text2speech-1.12.4.jar;$minecraftPath/libraries/com/mojang/text2speech/1.12.4/text2speech-1.12.4-natives-windows.jar;$minecraftPath/versions/1.18.2-forge-40.2.9/1.18.2-forge-40.2.9.jar',
      '-Djava.net.preferIPv6Addresses=system',
      '-DignoreList=bootstraplauncher,securejarhandler,asm-commons,asm-util,asm-analysis,asm-tree,asm,JarJarFileSystems,client-extra,fmlcore,javafmllanguage,lowcodelanguage,mclanguage,forge-,1.18.2-forge-40.2.9.jar',
      '-DmergeModules=jna-5.10.0.jar,jna-platform-5.10.0.jar,java-objc-bridge-1.0.0.jar',
      '-DlibraryDirectory=$minecraftPath/libraries',
      '-p',
      '$minecraftPath/libraries/cpw/mods/bootstraplauncher/1.0.0/bootstraplauncher-1.0.0.jar;$minecraftPath/libraries/cpw/mods/securejarhandler/1.0.8/securejarhandler-1.0.8.jar;$minecraftPath/libraries/org/ow2/asm/asm-commons/9.5/asm-commons-9.5.jar;$minecraftPath/libraries/org/ow2/asm/asm-util/9.5/asm-util-9.5.jar;$minecraftPath/libraries/org/ow2/asm/asm-analysis/9.5/asm-analysis-9.5.jar;$minecraftPath/libraries/org/ow2/asm/asm-tree/9.5/asm-tree-9.5.jar;$minecraftPath/libraries/org/ow2/asm/asm/9.5/asm-9.5.jar;$minecraftPath/libraries/net/minecraftforge/JarJarFileSystems/0.3.19/JarJarFileSystems-0.3.19.jar',
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
      '1.18.2-forge-40.2.9',
      '--gameDir',
      minecraftPath,
      '--assetsDir',
      '$minecraftPath/assets',
      '--assetIndex',
      '1.18',
      '--uuid',
      uuid,
      '--accessToken',
      bearer,
      '--clientId',
      '\${clientid}',
      '--xuid',
      '\${auth_xuid}',
      '--userType',
      'msa',
      '--versionType',
      'release',
      '--launchTarget',
      'forgeclient',
      '--fml.forgeVersion',
      '40.2.9',
      '--fml.mcVersion',
      '1.18.2',
      '--fml.forgeGroup',
      'net.minecraftforge',
      '--fml.mcpVersion',
      '20220404.173914',
      if (Utility.autoConnect) '--server',
      if (Utility.autoConnect) 'server.spartaland.es'
    ]);

    await Future.delayed(const Duration(seconds: 5));

    if (Utility.autoClose) exit(0);
    isLaunching.value = false;
  }
}
