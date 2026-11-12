import 'package:bc_launcher/screens/main_screen.dart';
import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:flutter/material.dart';

class TabButton extends StatefulWidget {
  final String label;
  final IconData icon;

  /// The tab it shows, or null when it opens outside the launcher.
  final int? tab;

  /// Instead of showing [tab]; marked as opening in the browser.
  final VoidCallback? onTap;

  const TabButton({
    super.key,
    required this.label,
    required this.icon,
    this.tab,
    this.onTap,
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
        final theme = InstanceTheme.of(context);

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
                          color: theme.primary.withValues(alpha: 0.5),
                          blurRadius: 50.0,
                          spreadRadius: 40.0,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.only(top: 1),
                      color: theme.primary,
                      height: 1,
                    ),
                  ),
                ),
              ),
            Center(
              child: Opacity(
                opacity: (selected || _hover) ? 1 : 0.7,
                child: InkWell(
                  mouseCursor: SystemMouseCursors.click,
                  onTapDown: (d) => widget.tab != null
                      ? selectedTab.value = widget.tab
                      : widget.onTap?.call(),
                  onHover: (value) => setState(() => _hover = value),
                  child: Row(
                    children: [
                      Icon(widget.icon, color: theme.primary, size: 25),
                      const SizedBox(width: 12),
                      Text(
                        widget.label.toUpperCase(),
                        style: TextStyle(
                          color: theme.text,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      if (widget.onTap != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.north_east,
                            color: theme.text,
                            size: 11,
                          ),
                        ),
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
