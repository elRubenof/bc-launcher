import 'dart:developer';

import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/deep_links.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/organization_auth.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => OrganizationDialog(server: server),
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
  String? _currentVersion;

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
      _currentVersion = current;
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
          l.launcherOutdatedDesc(
            name,
            _organization?.minLauncherVersion ?? "",
            _currentVersion ?? "",
          ),
          [
            _button(
              l.downloadNewVersion,
              filled: true,
              onPressed: () => launchUrl(Uri.parse(Constants.releasesUrl)),
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

    final busy = _step == _Step.connecting || _step == _Step.signingIn;
    final textColor = Colors.white.withValues(alpha: 0.8);

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
              _logo(),
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
              if (busy) ...[
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
                      _step == _Step.connecting ? l.connecting : l.signingIn,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              Wrap(spacing: 12, runSpacing: 12, children: buttons),
            ],
          ),
        ),
      ),
    );
  }

  /// The organization's logo
  Widget _logo() {
    final organization = _organization;
    final offline = _step == _Step.failed && _failure == _Failure.offline;

    Widget box(Widget child, {Color? color}) => Container(
      width: 80,
      height: 80,
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color ?? Constants.mainColor.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );

    if (organization == null || (offline && organization.logoUrl == null)) {
      return box(
        Icon(
          offline ? Icons.wifi_off_rounded : Icons.public_rounded,
          size: 36,
          color: Colors.white.withValues(alpha: 0.75),
        ),
        color: Colors.white.withValues(alpha: 0.06),
      );
    }

    final initials = box(
      Text(
        organization.name
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .take(2)
            .map((word) => word[0].toUpperCase())
            .join(),
        style: const TextStyle(
          color: Constants.textColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final logoUrl = organization.logoUrl;
    if (logoUrl == null) return initials;
    return box(
      Image.network(
        logoUrl,
        width: 80,
        height: 80,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => initials,
      ),
      color: Colors.transparent,
    );
  }

  Widget _button(
    String text, {
    required bool filled,
    required VoidCallback onPressed,
  }) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    const padding = EdgeInsets.symmetric(horizontal: 22, vertical: 16);
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    if (filled) {
      return FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Constants.mainColor,
          foregroundColor: Constants.textColor,
          shape: shape,
          padding: padding,
          textStyle: textStyle,
        ),
        child: Text(text),
      );
    }

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Constants.textColor,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
        shape: shape,
        padding: padding,
        textStyle: textStyle,
      ),
      child: Text(text),
    );
  }
}
