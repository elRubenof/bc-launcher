import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter/material.dart';

/// The launcher's dropdown menus: dark and rounded, without Material's
/// ripple, with the option under the pointer highlighted.
class LauncherMenu {
  static const color = Color(0xFF2F2037);
  static const animation = AnimationStyle(
    duration: Duration(milliseconds: 150),
  );
  static final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(width: 0.5, color: Colors.white.withValues(alpha: 0.18)),
  );

  /// Wraps what opens a menu, so neither it nor the menu shows Material's
  /// ripple.
  static Widget withoutRipple(BuildContext context, Widget child) => Theme(
    data: Theme.of(context).copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
    ),
    child: child,
  );

  /// An option that runs [action] when chosen.
  static PopupMenuItem<VoidCallback> item(
    IconData icon,
    String text,
    VoidCallback action, {
    Color color = Constants.textColor,
    bool enabled = true,
  }) {
    return PopupMenuItem(
      value: action,
      enabled: enabled,
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: _Option(icon: icon, text: text, color: color, enabled: enabled),
    );
  }

  /// Opens a menu of [items] where the pointer is (a right click).
  static Future<void> showAt(
    BuildContext context,
    Offset position,
    List<PopupMenuEntry<VoidCallback>> items,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final action = await showMenu<VoidCallback>(
      context: context,
      position: RelativeRect.fromRect(
        position & Size.zero,
        Offset.zero & overlay.size,
      ),
      items: items,
      color: color,
      shape: shape,
      popUpAnimationStyle: animation,
    );
    action?.call();
  }
}

/// An option's row, tinted with its color while the pointer is over it.
class _Option extends StatefulWidget {
  final IconData icon;
  final String text;
  final Color color;
  final bool enabled;

  const _Option({
    required this.icon,
    required this.text,
    required this.color,
    required this.enabled,
  });

  @override
  State<_Option> createState() => _OptionState();
}

class _OptionState extends State<_Option> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled
        ? widget.color
        : widget.color.withValues(alpha: 0.4);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      // As wide as the menu, so the highlight keeps the same margin on every
      // side.
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered && widget.enabled
              ? widget.color.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 16, color: color),
            const SizedBox(width: 10),
            Text(widget.text, style: TextStyle(color: color, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
