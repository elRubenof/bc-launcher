import 'dart:io';

import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/settings.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/button_3d.dart';
import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher_string.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int taps = 0, turns = 0;

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Column(
          children: [
            ValueListenableBuilder(
              valueListenable: Utility.isLaunching,
              builder: (context, value, child) => SizedBox(
                height: value ? 5 : 0,
                width: MediaQuery.of(context).size.width,
                child: LinearProgressIndicator(
                  color: Constants.backgroundColor,
                  backgroundColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Container(
              height: Constants.topBarHeight,
              width: MediaQuery.of(context).size.width,
              color: Constants.backgroundColor,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.horizontalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    devInfo(),
                    launcherOptions(),
                  ],
                ),
              ),
            ),
          ],
        ),
        Button3D(
          title: l.play,
          width: 210,
          color: Constants.mainColor,
          secondaryColor: Constants.mainColorDarked,
          onPressed: () async {
            if (Utility.isLaunching.value) return;
            Utility.isLaunching.value = true;

            await Utility.sincFiles();
            await Minecraft.launch();

            await Future.delayed(const Duration(seconds: 1));
            appWindow.minimize();

            Utility.isLaunching.value = false;
          },
        ),
      ],
    );
  }

  Widget devInfo() {
    return Row(
      children: [
        if (Constants.devLogo.isNotEmpty)
          GestureDetector(
            onTap: () {
              if (++taps % 5 == 0) setState(() => turns += 1);
            },
            child: AnimatedRotation(
              turns: turns.toDouble(),
              duration: const Duration(milliseconds: 280),
              child: SvgPicture.asset(
                Constants.devLogo,
                colorFilter: ColorFilter.mode(
                  Colors.white.withValues(alpha: 0.2),
                  BlendMode.srcIn,
                ),
                height: Constants.topBarHeight * 0.65,
              ),
            ),
          ),
        if (Constants.devName.isNotEmpty)
          Padding(
            padding:
                EdgeInsets.only(left: Constants.devLogo.isNotEmpty ? 10 : 0),
            child: Text(
              Constants.devName.toUpperCase(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: Constants.topBarHeight * 0.155,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget launcherOptions() {
    final l = Utility.getLocalizations(context);

    return Row(
      children: [
        MouseIconButton(
          icon: Icons.image,
          size: 17.0,
          toolTip: l.screenshots,
          color: Constants.textColor,
          hoverColor: Colors.white.withValues(alpha: 0.5),
          backgroundSize: 35.0,
          backgroundColor: Colors.white.withValues(alpha: 0.12),
          onTap: () async {
            Directory screenshotsDir = Directory(
              "${Settings.minecraftDirectory.path}/screenshots",
            );

            await screenshotsDir.create();
            launchUrlString("file://${screenshotsDir.path}");
          },
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 15),
          child: MouseIconButton(
            icon: Icons.autorenew,
            size: 17.0,
            toolTip: l.synchronize,
            color: Constants.textColor,
            hoverColor: Colors.white.withValues(alpha: 0.5),
            backgroundSize: 35.0,
            backgroundColor: Colors.white.withValues(alpha: 0.12),
            onTap: () async {
              Utility.isLoading.value = true;

              await Settings.minecraftDirectory.delete(recursive: true);
              await Utility.checkInstallation();
              await Utility.sincFiles(force: true);

              Utility.isLoading.value = false;
            },
          ),
        ),
        Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: Colors.white.withValues(alpha: 0.12).withValues(alpha: 0.06),
          ),
          child: Row(
            children: [
              Text(
                l.autoConnect,
                style: const TextStyle(
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
                      value: Settings.autoConnect,
                      activeTrackColor: const Color(0xff7a4aee),
                      onChanged: (value) async {
                        await Utility.setAutoConnect(value);

                        setState(() {});
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
