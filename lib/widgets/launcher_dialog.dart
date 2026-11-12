import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter/material.dart';

/// What a dialog asks for, which colors its badge: an organization's
/// (its logo, in the main color), deleting or removing something (red), or a
/// notice or an error (neutral).
enum DialogTone { neutral, danger, brand }

/// The launcher's dialog: a 460 px card with a badge on top, a title, a
/// description, an optional working indicator ([busy]), its buttons (the
/// main one first) and an optional link under them.
class LauncherDialog extends StatelessWidget {
  /// The 80 px square on top; usually [LauncherDialog.iconBadge].
  final Widget badge;
  final String? title;
  final String? description;

  /// What it is doing while it works, beside a spinner.
  final String? busy;
  final List<Widget> buttons;
  final String? linkText;
  final VoidCallback? onLink;

  const LauncherDialog({
    super.key,
    required this.badge,
    this.title,
    this.description,
    this.busy,
    this.buttons = const [],
    this.linkText,
    this.onLink,
  });

  /// Shows [dialog] over a dimmed launcher; [dismissible] lets a click
  /// outside close it.
  static Future<T?> show<T>(
    BuildContext context,
    WidgetBuilder dialog, {
    bool dismissible = true,
  }) => showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: dialog,
  );

  /// The badge's square, holding [child], in [tone]'s color.
  static Widget badgeBox(Widget child, {DialogTone tone = DialogTone.neutral}) {
    return Container(
      width: 80,
      height: 80,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: switch (tone) {
          DialogTone.neutral => Colors.white.withValues(alpha: 0.06),
          DialogTone.danger => Constants.dangerColor.withValues(alpha: 0.22),
          DialogTone.brand => Constants.mainColor.withValues(alpha: 0.35),
        },
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  /// A badge with the image at [url] (an organization's logo, an
  /// instance's icon), or [fallback] when there is none or it can't be
  /// loaded.
  static Widget imageBadge(String? url, Widget fallback) {
    if (url == null) return fallback;
    return SizedBox.square(
      dimension: 80,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          width: 80,
          height: 80,
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => fallback,
        ),
      ),
    );
  }

  /// A badge with [icon] in [tone]'s colors.
  static Widget iconBadge(
    IconData icon, {
    DialogTone tone = DialogTone.neutral,
  }) {
    return badgeBox(
      Icon(
        icon,
        size: 36,
        color: switch (tone) {
          DialogTone.neutral => Colors.white.withValues(alpha: 0.75),
          DialogTone.danger => Constants.dangerTextColor,
          DialogTone.brand => Constants.textColor,
        },
      ),
      tone: tone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Colors.white.withValues(alpha: 0.8);
    final title = this.title;
    final description = this.description;
    final busy = this.busy;
    final linkText = this.linkText;

    return Center(
      child: Material(
        color: Constants.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            width: 0.5,
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Container(
          width: 460,
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              badge,
              if (title != null) ...[
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Constants.textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (description != null) ...[
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontSize: 14, height: 1.5),
                ),
              ],
              if (busy != null) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Constants.mainColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      busy,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ],
                ),
              ],
              if (buttons.isNotEmpty) ...[
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: buttons,
                ),
              ],
              if (linkText != null) ...[
                const SizedBox(height: 18),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onLink,
                    child: Text(
                      linkText,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
