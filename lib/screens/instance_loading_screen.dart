import 'dart:developer';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/game_installer.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/instance_installer.dart';
import 'package:bc_launcher/services/organization_auth.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/services/sync_engine.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/custom_button.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:flutter/material.dart';

class InstanceLoadingScreen extends StatefulWidget {
  final Organization organization;
  final Instance instance;

  const InstanceLoadingScreen({
    super.key,
    required this.organization,
    required this.instance,
  });

  @override
  State<InstanceLoadingScreen> createState() => _InstanceLoadingScreenState();
}

class _InstanceLoadingScreenState extends State<InstanceLoadingScreen> {
  static const _megabyte = 1024 * 1024;

  EntryStep? _step;

  /// Whether checking found files to change.
  bool _changing = false;
  SyncProgress? _sync;
  double? _install;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    final organization = widget.organization;
    final instance = widget.instance;
    setState(() {
      _sync = null;
      _install = null;
      _changing = false;
    });

    try {
      await InstanceInstaller.enter(
        OrganizationAuth.clientFor(organization),
        organization.key,
        instance,
        onStep: (step) {
          if (mounted) setState(() => _step = step);
        },
        onSyncProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _sync = progress;
            _changing |= progress.totalFiles > 0;
          });
        },
        onInstallProgress: (progress) {
          if (!mounted) return;
          setState(() {
            _install = progress;
            _changing |= progress < 1;
          });
        },
      );
      await OrganizationStore.setLastInstance(organization.key, instance.id);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      log("Entering ${instance.id} failed: $e");
      if (mounted) _showError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (status, detail, progress) = _progress();
    return LoadingScreen(status: status, detail: detail, progress: progress);
  }

  /// The status line, the detail under it and the bar's value.
  (String?, String?, double?) _progress() {
    final l = Utility.getLocalizations(context);
    final name = widget.instance.name;
    final sync = _sync;
    final install = _install;

    if (_step == EntryStep.checking && !_changing) return (null, null, null);

    final preparing = _step == EntryStep.installing || install != null;
    final fraction = preparing ? (install ?? 0) : (sync?.fraction ?? 0);
    final percent = (fraction * 100).floor();

    final status = switch (_step) {
      EntryStep.installing => l.installingInstance(name, percent),
      EntryStep.updating ||
      EntryStep.checking => l.updatingInstance(name, percent),
      _ => l.downloadingInstance(name, percent),
    };

    String? detail;
    if (preparing) {
      final instance = widget.instance;
      detail = instance.loaderType == LoaderType.vanilla
          ? l.gameFiles(instance.minecraftVersion)
          : l.gameFilesWithLoader(
              instance.minecraftVersion,
              "${instance.loaderType.displayName} ${instance.loaderVersion ?? ""}"
                  .trim(),
            );
    } else if (sync != null && sync.totalFiles > 0) {
      detail = l.syncProgress(
        sync.files,
        sync.totalFiles,
        (sync.bytes / _megabyte).round(),
        (sync.totalBytes / _megabyte).round(),
      );
    }

    return (status, detail, fraction);
  }

  void _showError(Object error) {
    final l = Utility.getLocalizations(context);
    final name = widget.instance.name;
    final failedTitle = switch (_step) {
      EntryStep.installing => l.installFailedTitle(name),
      EntryStep.updating || EntryStep.checking => l.updateFailedTitle(name),
      _ => l.downloadFailedTitle(name),
    };

    if (error is ApiError && !InstanceInstaller.isOffline(error)) {
      // The organization's list may have changed (removed instance, lost
      // access, incompatible): the list shows it when going back.
      InstanceCatalog.refresh(widget.organization);
    }

    // A failure while installing the game files can also be the network.
    final cause = error is GameFilesError ? error.cause : error;
    final (icon, title, description, canRetry) = switch (error) {
      NotEnoughSpaceError(:final needed, :final available) => (
        Icons.storage_rounded,
        l.notEnoughSpaceTitle,
        l.notEnoughSpaceDesc(
          name,
          (needed / _megabyte).ceil(),
          (available / _megabyte).floor(),
        ),
        true,
      ),
      ApiError(type: ApiErrorType.notFound) => (
        Icons.error_outline_rounded,
        l.instanceGoneTitle(name),
        l.instanceGoneDesc,
        false,
      ),
      GameFilesError(cause: UnsupportedLoaderError(:final loader)) => (
        Icons.error_outline_rounded,
        failedTitle,
        l.loaderNotSupportedDesc(name, loader.displayName),
        false,
      ),
      _ when InstanceInstaller.isOffline(cause) => (
        Icons.wifi_off_rounded,
        failedTitle,
        l.downloadOfflineDesc,
        true,
      ),
      GameFilesError() => (
        Icons.error_outline_rounded,
        failedTitle,
        l.gameFilesFailedDesc,
        true,
      ),
      _ => (
        Icons.error_outline_rounded,
        failedTitle,
        l.downloadFailedDesc,
        true,
      ),
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (dialogContext) => Center(
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
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (canRetry)
                      CustomButton(
                        l.retry,
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _run();
                        },
                      ),
                    CustomButton(
                      l.backToInstances,
                      filled: !canRetry,
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        Navigator.pop(context, false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
