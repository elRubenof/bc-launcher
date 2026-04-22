import 'dart:io';
import 'dart:ui';

import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/custom_dialog.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class UpdateScreen extends StatelessWidget {
  final String url;

  const UpdateScreen({super.key, required this.url});

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
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.0),
                ),
              ),
            ),
          ),
          Container(
            height: height,
            color: Constants.backgroundColor.withValues(alpha: 0.85),
          ),
          CustomDialog(
            title: url.isEmpty ? l.updatedNeeded : l.availableUpdate,
            description: url.isNotEmpty ? l.updateQuestion : null,
            backgroundColor: Constants.mainColor.withValues(alpha: 0.1),
            mainButtonText: url.isNotEmpty ? l.yes : l.close,
            secondaryButtonText: url.isNotEmpty ? l.no : null,
            mainButtonOnPressed: () async {
              if (url.isEmpty) exit(0);

              Utility.isLoading.value = true;
              if (await Utility.update(url, l.downloading)) exit(0);
              Utility.isLoading.value = false;
            },
            secondaryButtonOnPressed: () => exit(0),
          ),
          ValueListenableBuilder(
            valueListenable: Utility.isLoading,
            builder:
                (context, value, child) =>
                    value
                        ? Container(
                          width: width,
                          height: height,
                          color: Constants.backgroundColor,
                          child: const LoadingScreen(),
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
