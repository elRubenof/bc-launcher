import 'package:bc_launcher/main.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter/material.dart';

class TabButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final int tab;

  const TabButton({
    super.key,
    required this.label,
    required this.icon,
    required this.tab,
  });

  @override
  State<StatefulWidget> createState() => _TabButtonState();
}

class _TabButtonState extends State<TabButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: selectedTab,
      builder: (context, value, child) {
        final selected = value == widget.tab;

        return Stack(
          children: [
            if (selected)
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                        BoxShadow(
                          color: Constants.mainColor.withOpacity(0.5),
                          blurRadius: 50.0,
                          spreadRadius: 40.0,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 1),
                      color: Constants.mainColor,
                      height: 1,
                    ),
                  ),
                ),
              ),
            Center(
              child: Opacity(
                opacity: (selected || _hover) ? 1 : 0.7,
                child: InkWell(
                  onTapDown: (d) => selectedTab.value = widget.tab,
                  onHover: (value) => setState(() => _hover = value),
                  child: Row(
                    children: [
                      Icon(
                        widget.icon,
                        color: Constants.mainColor,
                        size: 25,
                      ),
                      const SizedBox(
                        width: 12,
                      ),
                      Text(
                        widget.label.toUpperCase(),
                        style: const TextStyle(
                          color: Constants.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
