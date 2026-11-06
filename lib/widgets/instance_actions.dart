import 'dart:developer';
import 'dart:io';

import 'package:bc_launcher/l10n/app_localizations.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// What can be done with an installed instance from its card's menu or its
/// settings: open its folder and delete it from this computer.
class InstanceActions {
  /// "Show in Finder", "Open in Explorer" or "Open folder", by system.
  static String openFolderLabel(AppLocalizations l) => Platform.isMacOS
      ? l.showInFinder
      : Platform.isWindows
      ? l.openInExplorer
      : l.openFolder;

  static Future<void> openFolder(
    String organizationKey,
    String instanceId,
  ) async {
    final folder = await InstanceManager.instanceFolder(
      organizationKey,
      instanceId,
    );
    await launchUrl(Uri.file(folder.path));
  }

  /// Asks before deleting the instance from this computer, then deletes it
  /// while saying so. Returns whether it was deleted.
  static Future<bool> delete(
    BuildContext context,
    String organizationKey,
    String instanceId,
    String name,
  ) async {
    if (Utility.isPlaying.value) return false;

    final l = Utility.getLocalizations(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => CustomDialog(
        title: l.deleteInstanceQuestion(name),
        description: l.deleteInstanceDesc,
        mainButtonText: l.delete,
        mainButtonColor: Constants.dangerColor,
        mainButtonOnPressed: () => Navigator.pop(context, true),
        secondaryButtonText: l.cancel,
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final navigator = Navigator.of(context);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => PopScope(
        canPop: false,
        child: _Deleting(title: l.deletingInstance(name)),
      ),
    );

    Object? error;
    try {
      await InstanceManager.deleteInstance(organizationKey, instanceId);
      if (await OrganizationStore.lastInstance(organizationKey) == instanceId) {
        await OrganizationStore.clearLastInstance(organizationKey);
      }
    } catch (e) {
      log("Could not delete $instanceId: $e");
      error = e;
    }
    navigator.pop();
    if (error == null) return true;

    if (context.mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => CustomDialog(
          title: l.deleteFailedTitle(name),
          description: l.deleteFailedDesc,
          mainButtonText: l.close,
          mainButtonOnPressed: () => Navigator.pop(context),
        ),
      );
    }
    return false;
  }
}

/// The dialog while an instance is being deleted.
class _Deleting extends StatelessWidget {
  final String title;

  const _Deleting({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Constants.backgroundColor,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: 520,
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Constants.textColor,
                  fontSize: MediaQuery.of(context).size.height * 0.03,
                ),
              ),
              const SizedBox(height: 26),
              LinearProgressIndicator(
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
                color: Colors.white.withValues(alpha: 0.8),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
