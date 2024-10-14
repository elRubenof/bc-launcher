import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/button_3d.dart';
import 'package:flutter/material.dart';

class BottomBar extends StatefulWidget {
  const BottomBar({super.key});

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: Constants.topBarHeight,
          width: MediaQuery.of(context).size.width,
          color: Constants.backgroundColor,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [],
          ),
        ),
        Button3D(
          title: l.play,
          width: 210,
          color: Constants.mainColor,
          secondaryColor: Constants.mainColorDarked,
          onPressed: () => print("play"),
        ),
      ],
    );
  }
}
