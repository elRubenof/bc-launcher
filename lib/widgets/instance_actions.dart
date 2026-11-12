import 'dart:developer';
import 'dart:io';

import 'package:bc_launcher/l10n/app_localizations.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/custom_button.dart';
import 'package:bc_launcher/widgets/launcher_dialog.dart';
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
  ///
  /// Its dialogs show the instance's icon ([iconUrl]), or an icon for each
  /// one when it has none or it can't be loaded.
  static Future<bool> delete(
    BuildContext context,
    String organizationKey,
    String instanceId,
    String name, {
    String? iconUrl,
  }) async {
    if (Utility.isPlaying.value) return false;

    final l = Utility.getLocalizations(context);
    final confirmed = await LauncherDialog.show<bool>(
      context,
      (context) => LauncherDialog(
        badge: LauncherDialog.imageBadge(
          iconUrl,
          LauncherDialog.iconBadge(
            Icons.delete_outline_rounded,
            tone: DialogTone.danger,
          ),
        ),
        title: l.deleteInstanceQuestion(name),
        description: l.deleteInstanceDesc,
        buttons: [
          CustomButton(
            l.delete,
            color: Constants.dangerColor,
            onPressed: () => Navigator.pop(context, true),
          ),
          CustomButton(
            l.cancel,
            filled: false,
            onPressed: () => Navigator.pop(context, false),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return false;

    final navigator = Navigator.of(context);
    LauncherDialog.show<void>(
      context,
      dismissible: false,
      (context) => PopScope(
        canPop: false,
        child: LauncherDialog(
          badge: LauncherDialog.imageBadge(
            iconUrl,
            LauncherDialog.iconBadge(
              Icons.delete_outline_rounded,
              tone: DialogTone.danger,
            ),
          ),
          title: l.deletingInstance(name),
          busy: l.deletingInstanceDesc,
        ),
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
      LauncherDialog.show<void>(
        context,
        (context) => LauncherDialog(
          badge: LauncherDialog.imageBadge(
            iconUrl,
            LauncherDialog.iconBadge(Icons.error_outline_rounded),
          ),
          title: l.deleteFailedTitle(name),
          description: l.deleteFailedDesc,
          buttons: [
            CustomButton(
              l.close,
              filled: false,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
    return false;
  }
}
