import 'dart:io';
import 'dart:ui';

import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    final l = Utility.getLocalizations(context);

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/img/loging-background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.0)),
              ),
            ),
          ),
          Container(
            height: height,
            color: Constants.backgroundColor.withOpacity(0.85),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
              decoration: BoxDecoration(
                color: Constants.mainColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l.availableUpdate,
                    style: TextStyle(
                      color: Constants.textColor,
                      fontSize: MediaQuery.of(context).size.height * 0.03,
                    ),
                  ),
                  Text(
                    l.updateQuestion,
                    style: TextStyle(
                      color: Constants.textColor.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CupertinoButton.filled(
                        child: Text(l.yes.toUpperCase()),
                        onPressed: () async {
                          Utility.isLoading.value = true;

                          if (await Utility.update()) exit(0);

                          Utility.isLoading.value = false;
                        },
                      ),
                      const SizedBox(width: 10),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: CupertinoButton(
                          color: Colors.white.withOpacity(0.1),
                          child: Text(l.no.toUpperCase()),
                          onPressed: () => exit(0),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
          SizedBox(
            height: Constants.topBarHeight,
            child: MoveWindow(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.horizontalPadding,
                ),
                alignment: Alignment.centerRight,
                child: const WindowButtons(enableSettings: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
