import 'dart:developer';
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:launcher/widgets/mouse_button.dart';
import 'package:launcher/widgets/mouse_icon_button.dart';

class NavBar extends StatefulWidget {
  int currentIndex;
  final List<Function> changeIndex;

  NavBar({
    Key? key,
    required this.currentIndex,
    required this.changeIndex,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  List<String> accounts = ['XxFLOYxX', 'elRubenof_YT', 'Añadir Cuenta'];
  String dropdownValue = 'XxFLOYxX';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    double horizontalPadding = width * 0.065;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      color: const Color(0xff23162A),
      height: 65,
      child: Stack(
        children: [
          MoveWindow(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              logo(),
              pages(),
              account(),
              windowButtons(),
            ],
          ),
        ],
      ),
    );
  }

  Widget logo() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      width: 105,
      color: Theme.of(context).primaryColor,
      child: SvgPicture.asset(
        "assets/spartaland.svg",
        color: Colors.white,
      ),
    );
  }

  Widget pages() {
    return SizedBox(
      width: 390,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MouseButton(
            label: "INICIO",
            icon: Icons.home,
            onTap: () => setState(() => widget.changeIndex[0]()),
            selected: widget.currentIndex == 0,
            selectedLine: true,
          ),
          MouseButton(
            label: "MAPA",
            icon: Icons.map_sharp,
            onTap: () => Platform.isWindows
                ? setState(() => widget.changeIndex[1]())
                : null,
            selected: widget.currentIndex == 1,
            selectedLine: true,
          ),
          MouseButton(
            label: "AJUSTES",
            icon: Icons.settings,
            onTap: () => setState(() => widget.changeIndex[2]()),
            selected: widget.currentIndex == 2,
            selectedLine: true,
          ),
        ],
      ),
    );
  }

  Widget account() {
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        width: 280,
        height: double.infinity,
        color: Colors.white.withOpacity(0.06),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            accountSelector(),
            Container(
              color: Colors.white.withOpacity(0.2),
              width: 1,
              height: 25,
            ),
            Row(
              children: [
                MouseIconButton(
                  icon: Icons.logout_rounded,
                  color: Colors.white.withOpacity(0.2),
                  hoverColor: Colors.red[700],
                  size: 18.0,
                  onTap: () => log("LOGOUT"),
                ),
                MouseIconButton(
                  icon: Icons.notifications,
                  color: Colors.white.withOpacity(0.2),
                  hoverColor: Colors.white,
                  size: 18.0,
                  onTap: () => log("NOTIFICATIONS"),
                ),
              ],
            )
          ],
        ));
  }

  Widget accountSelector() {
    return DropdownButton<String>(
      value: dropdownValue,
      underline: Container(),
      dropdownColor: const Color(0xff23162A),
      onChanged: (String? newValue) {
        if (newValue != "Añadir Cuenta") {
          accounts.remove(newValue);
          accounts.insert(0, newValue ?? "Error");
          setState(() {
            dropdownValue = newValue!;
          });
        } else {
          log("Añadir Cuenta");
        }
      },
      items: accounts.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
            value: value,
            child: Row(children: [
              Container(
                  width: 25,
                  margin: const EdgeInsets.symmetric(horizontal: 14),
                  child: value != "Añadir Cuenta"
                      ? Image.network("https://mc-heads.net/avatar/$value")
                      : Image.asset("assets/plus.png")),
              Container(
                  constraints: const BoxConstraints(maxWidth: 84),
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ))
            ]));
      }).toList(),
    );
  }

  Widget windowButtons() {
    return SizedBox(
      width: 105,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MouseIconButton(
            icon: Icons.settings,
            size: 14.0,
            backgroundColor: Colors.white.withOpacity(0.12),
            onTap: () => widget.changeIndex[2](),
          ),
          MouseIconButton(
            icon: Icons.minimize,
            size: 14.0,
            backgroundColor: Colors.white.withOpacity(0.12),
            onTap: () => appWindow.minimize(),
          ),
          MouseIconButton(
            icon: Icons.close,
            size: 14.0,
            backgroundColor: Colors.white.withOpacity(0.12),
            onTap: () => appWindow.close(),
          ),
        ],
      ),
    );
  }
}
