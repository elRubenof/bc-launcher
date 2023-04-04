import 'package:flutter/material.dart';

class MouseIconButton extends StatefulWidget {
  final IconData icon;
  final GestureTapCallback onTap;
  final color, size, hoverColor, backgroundColor;

  const MouseIconButton(
      {Key? key,
      required this.icon,
      required this.onTap,
      this.color,
      this.size,
      this.hoverColor,
      this.backgroundColor})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _MouseIconButtonState();
}

class _MouseIconButtonState extends State<MouseIconButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return InkWell(
        onTap: () => widget.onTap(),
        onHover: (value) => setState(() => hover = value),
        child: Container(
          width: width * 0.02,
          height: width * 0.02,
          decoration: widget.backgroundColor != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color:
                      widget.backgroundColor.withOpacity(hover ? 0.12 : 0.06),
                )
              : null,
          child: Icon(
            widget.icon,
            color: hover
                ? widget.hoverColor ?? widget.color ?? Colors.white
                : widget.color ?? Colors.white,
            size: widget.size ?? IconTheme.of(context).size,
          ),
        ));
  }
}
