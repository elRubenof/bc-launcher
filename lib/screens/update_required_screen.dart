import 'dart:io';

import 'package:bc_launcher/l10n/app_localizations.dart';
import 'package:bc_launcher/services/update_service.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/custom_button.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

/// A required launcher update, over everything else: on Windows it downloads
/// on the loading screen and restarts by itself; on macOS and Linux the
/// player downloads the installer and replaces the launcher.
class UpdateRequiredScreen extends StatelessWidget {
  final UpdateService service;
  final LauncherUpdate update;

  const UpdateRequiredScreen({
    super.key,
    required this.service,
    required this.update,
  });

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);
    final version = update.version ?? l.newVersion;

    if (update.failed) {
      return _message(
        context,
        icon: Icons.sync_problem_rounded,
        title: l.launcherUpdateFailedTitle,
        description: l.launcherUpdateFailedDesc,
        buttons: [CustomButton(l.retry, onPressed: service.retry)],
      );
    }

    if (service.installs) {
      final progress = update.progress;
      return LoadingScreen(
        status: progress == null
            ? l.updating
            : l.updatingPercent((progress * 100).floor().toString()),
        detail: update.unsupported
            ? l.updateUnsupportedDownloadingDesc(version)
            : l.updateDownloadingDesc(version),
        progress: progress,
      );
    }

    return _message(
      context,
      icon: Icons.download_rounded,
      title: l.updateRequiredTitle,
      description: l.updateRequiredDesc(version),
      steps: _steps(l),
      buttons: [
        CustomButton(l.download, onPressed: service.download),
        if (update.notesUrl != null)
          CustomButton(
            l.whatsNew,
            filled: false,
            onPressed: () => launchUrl(update.notesUrl!),
          ),
      ],
    );
  }

  List<String> _steps(AppLocalizations l) => Platform.isMacOS
      ? [l.updateStepClose, l.updateStepReplaceMac, l.updateStepOpenMac]
      : [l.updateStepClose, l.updateStepReplaceLinux, l.updateStepOpenLinux];

  Widget _message(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    List<String> steps = const [],
    required List<Widget> buttons,
  }) {
    final textColor = Colors.white.withValues(alpha: 0.8);

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      icon,
                      size: 36,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Constants.textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 500),
                    child: Text(
                      description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  if (steps.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 4,
                        children: [
                          for (final (i, step) in steps.indexed)
                            Text(
                              "${i + 1}. $step",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.75),
                                fontSize: 13,
                                height: 1.6,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: buttons,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: Constants.topBarHeight,
            // Not const: `flutter run` fails to compile a const DragToMoveArea.
            // ignore: prefer_const_constructors
            child: DragToMoveArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.horizontalPadding,
                ),
                alignment: Alignment.centerRight,
                child: const WindowButtons(
                  enableSettings: false,
                  darkMode: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
