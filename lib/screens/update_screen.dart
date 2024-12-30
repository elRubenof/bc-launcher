import 'dart:io';

import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/top_bar.dart';
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
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l.availableUpdate,
                  style: TextStyle(
                    color: Constants.textColor,
                    fontSize: MediaQuery.of(context).size.height * 0.03,
                  ),
                ),
                const SizedBox(height: 30),
                CupertinoButton.filled(
                  child: Text(l.update),
                  onPressed: () async {
                    Utility.isLoading.value = true;

                    if (await Utility.update()) exit(0);

                    Utility.isLoading.value = false;
                  },
                )
              ],
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
                child: windowButtons(enableSettings: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
