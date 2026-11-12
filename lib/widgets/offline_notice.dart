import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Why something can't be reached and what still works, with "Retry" when
/// [onRetry] is given.
class OfflineNotice extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRetry;

  /// Behind the text; a translucent white when null.
  final Color? background;

  const OfflineNotice({
    super.key,
    required this.title,
    required this.description,
    this.onRetry,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);
    final text = InstanceTheme.of(context).text;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, onRetry != null ? 12 : 16, 12),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          width: 0.5,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      // "Retry" always at the right end of the box.
      child: Row(
        spacing: 14,
        children: [
          Icon(Icons.wifi_off_rounded, color: text.withValues(alpha: 0.75)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 2,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: text.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (onRetry != null)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l.retry,
                    style: TextStyle(
                      color: text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
