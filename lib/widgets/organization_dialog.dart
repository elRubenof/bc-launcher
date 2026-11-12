import 'dart:developer';

import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/deep_links.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/organization_auth.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/services/update_service.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/custom_button.dart';
import 'package:bc_launcher/widgets/launcher_dialog.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum _Step { connecting, confirm, signingIn, failed }

enum _Failure { offline, noAccess, incompatible, outdated, signIn, minecraft }

/// Adds the organization of a `bclauncher://add` link
class OrganizationDialog extends StatefulWidget {
  final String server;

  const OrganizationDialog({super.key, required this.server});

  static bool _open = false;

  static void listen() {
    DeepLinks.pendingAdd.addListener(_showPending);
    Minecraft.profile.addListener(_showPending);
  }

  static void _showPending() {
    final server = DeepLinks.pendingAdd.value;
    if (server == null || _open || Minecraft.profile.value == null) return;

    final context = Utility.key.currentContext;
    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showPending());
      return;
    }

    _open = true;
    DeepLinks.pendingAdd.value = null;
    LauncherDialog.show<void>(
      context,
      dismissible: false,
      (_) => OrganizationDialog(server: server),
    ).whenComplete(() {
      _open = false;
      _showPending();
    });
  }

  @override
  State<OrganizationDialog> createState() => _OrganizationDialogState();
}

class _OrganizationDialogState extends State<OrganizationDialog> {
  _Step _step = _Step.connecting;
  _Failure? _failure;
  Organization? _organization;

  @override
  void initState() {
    super.initState();
    _discover();
  }

  Future<void> _discover() async {
    setState(() => _step = _Step.connecting);
    try {
      final organization = await ApiClient.discovery(widget.server);
      final current = (await PackageInfo.fromPlatform()).version;
      if (!mounted) return;

      _organization = organization;
      if (organization.needsNewerLauncher(current)) {
        _fail(_Failure.outdated);
      } else {
        setState(() => _step = _Step.confirm);
      }
    } on ApiError catch (e) {
      _fail(switch (e.type) {
        ApiErrorType.incompatible ||
        ApiErrorType.upgradeRequired => _Failure.incompatible,
        _ => _Failure.offline,
      });
    } catch (e) {
      log("Adding an organization failed: $e");
      _fail(_Failure.offline);
    }
  }

  Future<void> _signIn() async {
    final organization = _organization!;
    setState(() => _step = _Step.signingIn);
    try {
      await OrganizationAuth.signIn(OrganizationAuth.clientFor(organization));
      if (!mounted) return;

      await OrganizationStore.save(organization);
      await OrganizationStore.select(organization.key);
      InstanceCatalog.refresh(organization);

      if (mounted) Navigator.pop(context);
    } on ApiError catch (e) {
      _fail(switch (e.type) {
        ApiErrorType.notMember => _Failure.noAccess,
        ApiErrorType.offline ||
        ApiErrorType.serverUnavailable => _Failure.offline,
        ApiErrorType.incompatible ||
        ApiErrorType.upgradeRequired => _Failure.incompatible,
        _ => _Failure.signIn,
      });
    } on MinecraftJoinError catch (e) {
      _fail(e.offline ? _Failure.offline : _Failure.minecraft);
    } catch (e) {
      log("Signing in to the organization failed: $e");
      _fail(_Failure.signIn);
    }
  }

  void _fail(_Failure failure) {
    if (!mounted) return;

    setState(() {
      _step = _Step.failed;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);
    final name = _organization?.name ?? "";
    final close = _button(
      l.close,
      filled: false,
      onPressed: () => Navigator.pop(context),
    );

    final (title, description, buttons) = switch (_step) {
      _Step.connecting => (
        null,
        null,
        [
          _button(
            l.cancel,
            filled: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      _Step.confirm => (
        l.addOrganizationQuestion(name),
        l.addOrganizationDesc,
        [
          _button(l.add, filled: true, onPressed: _signIn),
          _button(
            l.cancel,
            filled: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      _Step.signingIn => (
        name,
        null,
        [
          _button(
            l.cancel,
            filled: false,
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      _Step.failed => switch (_failure!) {
        _Failure.offline => (
          l.organizationOfflineTitle,
          l.organizationOfflineDesc,
          [
            _button(
              l.retry,
              filled: true,
              onPressed: _organization == null ? _discover : _signIn,
            ),
            close,
          ],
        ),
        _Failure.noAccess => (
          l.organizationNoAccessTitle(name),
          l.organizationNoAccessDesc,
          [close],
        ),
        _Failure.incompatible => (
          l.organizationIncompatibleTitle(name.isEmpty ? "BC Launcher" : name),
          l.organizationIncompatibleDesc,
          [close],
        ),
        _Failure.outdated => (
          l.launcherOutdatedTitle,
          l.launcherOutdatedDesc(name, _organization?.minLauncherVersion ?? ""),
          [
            _button(
              l.updateLauncher,
              filled: true,
              onPressed: () {
                Navigator.pop(context);
                UpdateService.updateLauncher();
              },
            ),
            close,
          ],
        ),
        _Failure.signIn => (
          l.organizationSignInErrorTitle,
          l.organizationSignInErrorDesc,
          [_button(l.retry, filled: true, onPressed: _signIn), close],
        ),
        _Failure.minecraft => (
          l.minecraftSessionRejectedTitle,
          l.minecraftSessionRejectedDesc,
          [close],
        ),
      },
    };

    return LauncherDialog(
      badge: _logo(),
      title: title,
      description: description,
      busy: switch (_step) {
        _Step.connecting => l.connecting,
        _Step.signingIn => l.signingIn,
        _ => null,
      },
      buttons: buttons,
    );
  }

  /// The organization's logo once it is known; otherwise, or when it has
  /// none or it can't be loaded, an icon for the step.
  Widget _logo() {
    final offline = _step == _Step.failed && _failure == _Failure.offline;
    return LauncherDialog.imageBadge(
      _organization?.logoUrl,
      LauncherDialog.iconBadge(
        offline ? Icons.wifi_off_rounded : Icons.public_rounded,
      ),
    );
  }

  Widget _button(
    String text, {
    required bool filled,
    required VoidCallback onPressed,
  }) => CustomButton(text, filled: filled, onPressed: onPressed);
}
