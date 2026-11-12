import 'package:bc_launcher/services/update_service.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A new launcher version: on Windows, downloaded and ready to install with
/// "Restart" (not while the game runs); on macOS and Linux, to download. The
/// X hides it until the next start. Nothing when there is none.
class UpdateNotice extends StatelessWidget {
  /// Behind the text; a translucent white when null.
  final Color? background;

  const UpdateNotice({super.key, this.background});

  @override
  Widget build(BuildContext context) {
    final service = UpdateService.current;
    if (service == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: Listenable.merge([
        service.update,
        service.dismissed,
        Utility.isPlaying,
      ]),
      builder: (context, _) {
        final update = service.update.value;
        final ready = update.status == UpdateStatus.ready;
        if (service.dismissed.value ||
            (!ready && update.status != UpdateStatus.toDownload)) {
          return const SizedBox.shrink();
        }
        return _notice(context, service, update, ready);
      },
    );
  }

  Widget _notice(
    BuildContext context,
    UpdateService service,
    LauncherUpdate update,
    bool ready,
  ) {
    final l = Utility.getLocalizations(context);
    final text = InstanceTheme.of(context).text;
    final version = update.version ?? "";
    final playing = Utility.isPlaying.value;

    final title = ready
        ? l.updateReadyTitle(version)
        : l.updateAvailableTitle(version);
    final description = !ready
        ? l.updateAvailableDesc
        : playing
        ? l.updateCloseGameDesc
        : l.updateReadyDesc;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: 0.06),
        border: Border.all(
          width: 0.5,
          color: Colors.white.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 12,
        children: [
          Icon(Icons.download_rounded, color: text.withValues(alpha: 0.75)),
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
          if (update.notesUrl != null)
            _button(
              onPressed: () => launchUrl(update.notesUrl!),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Text(
                  l.whatsNew,
                  style: TextStyle(
                    color: text.withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          _button(
            onPressed: ready
                ? (playing ? null : service.restart)
                : service.download,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: ready && playing
                    ? Colors.white.withValues(alpha: 0.12)
                    : InstanceTheme.of(context).primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ready ? l.restart : l.download,
                style: TextStyle(
                  color: ready && playing
                      ? Colors.white.withValues(alpha: 0.5)
                      : Constants.textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Semantics(
            label: l.hideNotice,
            button: true,
            child: _button(
              onPressed: service.dismiss,
              child: SizedBox(
                width: 28,
                height: 28,
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: text.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _button({required VoidCallback? onPressed, required Widget child}) {
    return MouseRegion(
      cursor: onPressed == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
