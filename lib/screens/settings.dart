import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:launcher/utils/data.dart';
import 'package:launcher/utils/utility.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  Color textColor = Colors.white.withOpacity(0.9);
  TextStyle titleStyle =
      TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 20);
  TextStyle textStyle = const TextStyle(color: Colors.white60, fontSize: 13);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 60, right: 60, top: 60),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          memory(),
          const SizedBox(height: 60),
          launcherChecks(),
          const SizedBox(height: 60),
          launcherInfo(),
        ],
      ),
    );
  }

  Widget memory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Memoria", style: titleStyle),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Divider(height: 0, color: textColor),
        ),
        Text(
          " RAM Asignada",
          style: TextStyle(color: textColor, fontSize: 16),
        ),
        Transform.translate(
          offset: const Offset(-19, 0),
          child: Row(
            children: [
              SizedBox(
                width: 300,
                child: Slider(
                  min: 0,
                  max: 16,
                  thumbColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.16),
                  value: Utility.allocatedRAM.toDouble(),
                  onChanged: (value) {
                    setState(() => Utility.allocatedRAM = value.truncate());
                  },
                  onChangeEnd: (value) async {
                    SharedPreferences pref =
                        await SharedPreferences.getInstance();
                    pref.setInt("allocatedRAM", value.truncate());
                  },
                ),
              ),
              Text("${Utility.allocatedRAM}GB", style: titleStyle)
            ],
          ),
        ),
        Text(" Es recomendable asignar al menos 8GB de RAM al juego.",
            style: textStyle),
      ],
    );
  }

  Widget launcherChecks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Comportamiento del launcher", style: titleStyle),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Divider(height: 0, color: Colors.white.withOpacity(0.9)),
        ),
        Row(
          children: [
            Checkbox(
              value: Utility.autoClose,
              fillColor: MaterialStateProperty.resolveWith(getColor),
              onChanged: (bool? value) async {
                SharedPreferences pre = await SharedPreferences.getInstance();
                pre.setBool("autoClose", value!);

                setState(() => Utility.autoClose = value);
              },
            ),
            const SizedBox(width: 4),
            Text(
              "Cerrar al iniciar el juego",
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            Checkbox(
              value: Utility.autoUpdate,
              fillColor: MaterialStateProperty.resolveWith(getColor),
              onChanged: (bool? value) async {
                SharedPreferences pre = await SharedPreferences.getInstance();
                pre.setBool("autoUpdate", value!);

                setState(() => Utility.autoUpdate = value);
              },
            ),
            const SizedBox(width: 4),
            Text(
              "Buscar actualizaciones al iniciar",
              style: TextStyle(color: textColor, fontSize: 16),
            ),
          ],
        ),
      ],
    );
  }

  Widget launcherInfo() {
    int modsCount = Directory("$minecraftPath/mods").listSync().length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Información de la aplicación", style: titleStyle),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Divider(height: 0, color: Colors.white.withOpacity(0.9)),
        ),
        Row(
          children: [
            Text(
              " Versión: ",
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            const Text(
              " $appVersion",
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: [
            Text(
              " Mods: ",
              style: TextStyle(color: textColor, fontSize: 16),
            ),
            Text(
              " $modsCount",
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          width: 210,
          child: CupertinoButton.filled(
            padding: EdgeInsets.zero,
            onPressed: () {},
            child: const Text("Buscar actualizaciones"),
          ),
        ),
      ],
    );
  }

  Color getColor(Set<MaterialState> states) {
    const Set<MaterialState> interactiveStates = <MaterialState>{
      MaterialState.selected,
      MaterialState.focused,
      MaterialState.pressed,
    };
    if (states.any(interactiveStates.contains)) {
      return Theme.of(context).primaryColor;
    }
    return textColor;
  }
}
