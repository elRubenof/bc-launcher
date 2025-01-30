import 'package:flutter/material.dart';

class MouseIconButton extends StatefulWidget {
  final IconData icon;
  final GestureTapCallback onTap;
  final Color? color,  hoverColor, backgroundColor; 
  final double? size, backgroundSize;
  final String? toolTip;

  const MouseIconButton(
      {super.key,
      required this.icon,
      required this.onTap,
      this.color,
      this.size,
      this.backgroundSize,
      this.hoverColor,
      this.backgroundColor,
      this.toolTip});

  @override
  State<StatefulWidget> createState() => _MouseIconButtonState();
}

class _MouseIconButtonState extends State<MouseIconButton> {
  bool hover = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      waitDuration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      message: widget.toolTip ?? "",
      child: InkWell(
        onTap: () => widget.onTap(),
        onHover: (value) => setState(() => hover = value),
        child: Container(
          width: widget.backgroundSize ?? 28,
          height: widget.backgroundSize ?? 28,
          decoration: widget.backgroundColor != null
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color:
                      widget.backgroundColor!.withValues(alpha: hover ? 0.12 : 0.06),
                )
              : null,
          child: Icon(
            widget.icon,
            color: hover
                ? widget.hoverColor ?? widget.color ?? Colors.white
                : widget.color ?? Colors.white,
            size: widget.size,
          ),
        ),
      ),
    );
  }
}