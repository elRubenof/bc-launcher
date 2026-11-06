import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter/material.dart';

/// The launcher's text button: filled with [color] (the main color by
/// default) or outlined.
class CustomButton extends StatelessWidget {
  final String text;
  final bool filled;
  final Color? color;
  final VoidCallback onPressed;

  const CustomButton(
    this.text, {
    super.key,
    this.filled = true,
    this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    const padding = EdgeInsets.symmetric(horizontal: 22, vertical: 16);
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color ?? Constants.mainColor,
          foregroundColor: Constants.textColor,
          shape: shape,
          padding: padding,
          textStyle: textStyle,
        ),
        child: Text(text),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Constants.textColor,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        shape: shape,
        padding: padding,
        textStyle: textStyle,
      ),
      child: Text(text),
    );
  }
}
