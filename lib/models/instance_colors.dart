import 'dart:ui';

/// The colors an instance paints the launcher with.
class InstanceColors {
  final Color primary;
  final Color primaryDark;
  final Color background;
  final Color text;

  const InstanceColors({
    required this.primary,
    required this.primaryDark,
    required this.background,
    required this.text,
  });

  factory InstanceColors.fromJson(Map<String, dynamic> json) {
    return InstanceColors(
      primary: _parse(json['primary']),
      primaryDark: _parse(json['primaryDark']),
      background: _parse(json['background']),
      text: _parse(json['text']),
    );
  }

  Map<String, dynamic> toJson() => {
    'primary': _format(primary),
    'primaryDark': _format(primaryDark),
    'background': _format(background),
    'text': _format(text),
  };

  /// `#RRGGBB` → opaque [Color].
  static Color _parse(String hex) {
    return Color(0xFF000000 | int.parse(hex.substring(1), radix: 16));
  }

  static String _format(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return "#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}";
  }
}
