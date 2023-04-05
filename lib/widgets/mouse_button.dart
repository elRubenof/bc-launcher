import 'dart:developer';

import 'package:flutter/material.dart';

class MouseButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final GestureTapCallback onTap;
  final bool selected, selectedLine;

  const MouseButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
    this.selectedLine = false,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => _MouseButtonState();
}

class _MouseButtonState extends State<MouseButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      if (widget.selectedLine && widget.selected)
        Positioned.fill(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withAlpha(75),
                      blurRadius: 50.0,
                      spreadRadius: 50.0,
                      offset: const Offset(
                        0.0,
                        0.0,
                      ),
                    ),
                  ]),
              child: Container(
                margin: const EdgeInsets.only(top: 1),
                color: Theme.of(context).primaryColor,
                height: 1,
              ),
            ),
          ),
        ),
      Center(
        child: Opacity(
          opacity: (widget.selected || _hover) ? 1 : 0.7,
          child: InkWell(
            onTapDown: (d) => widget.onTap(),
            onHover: (value) => setState(() => _hover = value),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: Theme.of(context).primaryColor,
                  size: 25,
                ),
                const SizedBox(
                  width: 12,
                ),
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    ]);
  }
}
