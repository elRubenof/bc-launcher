import 'package:flutter/material.dart';

class MouseIconButton extends StatefulWidget {
  final IconData icon;
  final GestureTapCallback onTap;
  final color, size, backgroundSize, hoverColor, backgroundColor;

  const MouseIconButton(
      {Key? key,
      required this.icon,
      required this.onTap,
      this.color,
      this.size,
      this.backgroundSize,
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
    return InkWell(
        onTap: () => widget.onTap(),
        onHover: (value) => setState(() => hover = value),
        child: Container(
          width: widget.backgroundSize ?? 28,
          height: widget.backgroundSize ?? 28,
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
            size: widget.size,
          ),
        ));
  }
}
