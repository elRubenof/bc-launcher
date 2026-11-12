import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter/material.dart';

/// An instance's initials on its primary color, in place of its icon when
/// it has none or it can't be loaded.
class InstanceInitials extends StatelessWidget {
  final Instance instance;
  final double size;

  const InstanceInitials({super.key, required this.instance, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: instance.colors.primary,
        borderRadius: BorderRadius.circular(size * 14 / 64),
      ),
      child: Text(
        instance.name
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .take(2)
            .map((word) => word[0].toUpperCase())
            .join(),
        style: TextStyle(
          color: Constants.textColor,
          fontSize: size * 22 / 64,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
