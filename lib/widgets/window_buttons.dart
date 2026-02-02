import 'package:bc_launcher/screens/main_screen.dart';
import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

class WindowButtons extends StatelessWidget {
  final bool enableSettings, darkMode;

  const WindowButtons({
    super.key,
    this.enableSettings = true,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: enableSettings ? 100 : 66,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (enableSettings)
            MouseIconButton(
              icon: Icons.settings,
              size: 14.0,
              backgroundColor: darkMode ? Colors.black : Colors.white,
              onTap: () => selectedTab.value = 2,
            ),
          MouseIconButton(
            icon: Icons.minimize,
            size: 14.0,
            backgroundColor: darkMode ? Colors.black : Colors.white,
            onTap: () => appWindow.minimize(),
          ),
          MouseIconButton(
            icon: Icons.close,
            size: 14.0,
            backgroundColor: darkMode ? Colors.black : Colors.white,
            onTap: () => appWindow.close(),
          ),
        ],
      ),
    );
  }
}
