import 'package:bc_launcher/models/instance_colors.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter/material.dart';

/// The colors of the instance on screen. [MainScreen] puts it on the theme;
/// anywhere else [of] gives the launcher's own look.
class InstanceTheme extends ThemeExtension<InstanceTheme> {
  /// The active tab, Play, switches and sliders.
  final Color primary;

  /// Play's sides.
  final Color primaryDark;

  /// The bars and the veil over the background.
  final Color background;
  final Color text;

  const InstanceTheme({
    required this.primary,
    required this.primaryDark,
    required this.background,
    required this.text,
  });

  static const launcher = InstanceTheme(
    primary: Constants.mainColor,
    primaryDark: Constants.mainColorDarked,
    background: Constants.backgroundColor,
    text: Constants.textColor,
  );

  factory InstanceTheme.fromColors(InstanceColors colors) {
    return InstanceTheme(
      primary: colors.primary,
      primaryDark: colors.primaryDark,
      background: colors.background,
      text: colors.text,
    );
  }

  static InstanceTheme of(BuildContext context) {
    return Theme.of(context).extension<InstanceTheme>() ?? launcher;
  }

  /// [base] with these colors, its primary included so switches and sliders
  /// take it.
  ThemeData apply(ThemeData base) {
    return base.copyWith(
      colorScheme: base.colorScheme.copyWith(primary: primary),
      extensions: [this],
    );
  }

  @override
  InstanceTheme copyWith({
    Color? primary,
    Color? primaryDark,
    Color? background,
    Color? text,
  }) {
    return InstanceTheme(
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      background: background ?? this.background,
      text: text ?? this.text,
    );
  }

  @override
  InstanceTheme lerp(InstanceTheme? other, double t) {
    if (other == null) return this;
    return InstanceTheme(
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      background: Color.lerp(background, other.background, t)!,
      text: Color.lerp(text, other.text, t)!,
    );
  }
}
