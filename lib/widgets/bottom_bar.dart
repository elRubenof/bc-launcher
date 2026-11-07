import 'dart:developer';
import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/forge_installer.dart';
import 'package:bc_launcher/services/game_process.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/instance_installer.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/instance_settings_store.dart';
import 'package:bc_launcher/services/log_export.dart';
import 'package:bc_launcher/services/organization_auth.dart';
import 'package:bc_launcher/services/sync_engine.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/global_settings.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/button_3d.dart';
import 'package:bc_launcher/widgets/custom_dialog.dart';
import 'package:bc_launcher/widgets/mouse_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:path/path.dart' show join;
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';

class BottomBar extends StatefulWidget {
  final Organization organization;
  final Instance instance;
  final Directory folder;
  final InstanceSettingsStore settings;

  const BottomBar({
    super.key,
    required this.organization,
    required this.instance,
    required this.folder,
    required this.settings,
  });

  @override
  State<BottomBar> createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  int taps = 0, turns = 0;

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);
    final theme = InstanceTheme.of(context);

    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Column(
          children: [
            ValueListenableBuilder(
              valueListenable: Utility.isLaunching,
              builder: (context, value, child) => SizedBox(
                height: value ? 5 : 0,
                width: MediaQuery.of(context).size.width,
                child: LinearProgressIndicator(
                  color: theme.background,
                  backgroundColor: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            Container(
              height: Constants.topBarHeight,
              width: MediaQuery.of(context).size.width,
              color: theme.background,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Constants.horizontalPadding,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [devInfo(), launcherOptions()],
                ),
              ),
            ),
          ],
        ),
        ValueListenableBuilder(
          valueListenable: Utility.isPlaying,
          builder: (context, playing, child) => Button3D(
            title: playing ? l.playing : l.play,
            width: 210,
            color: theme.primary,
            secondaryColor: theme.primaryDark,
            onPressed: play,
          ),
        ),
      ],
    );
  }

  Widget devInfo() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {
            if (++taps % 5 == 0) setState(() => turns += 1);
          },
          child: AnimatedRotation(
            turns: turns.toDouble(),
            duration: const Duration(milliseconds: 280),
            child: SvgPicture.asset(
              "assets/img/logo.svg",
              colorFilter: ColorFilter.mode(
                Colors.white.withValues(alpha: 0.2),
                BlendMode.srcIn,
              ),
              height: Constants.topBarHeight * 0.65,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10),
          child: Text(
            "BOLUDO´S COMPANY ®\nNOT AFFILIATED WITH MOJANG",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: Constants.topBarHeight * 0.155,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget launcherOptions() {
    final l = Utility.getLocalizations(context);
    final theme = InstanceTheme.of(context);
    final screenshotsPath = join(widget.folder.path, "screenshots");

    return Row(
      children: [
        if (widget.instance.webUrl case final url?) ...[
          linkButton(Icons.public, l.website, url),
          const SizedBox(width: 15),
        ],
        if (widget.instance.discordUrl case final url?) ...[
          linkButton(Icons.discord, l.discord, url),
          const SizedBox(width: 15),
        ],
        linkButton(Icons.image, l.screenshots, "file://$screenshotsPath"),
        const SizedBox(width: 15),
        if (widget.instance.serverAddress != null)
          Container(
            height: 35,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.white
                  .withValues(alpha: 0.12)
                  .withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                Text(
                  l.autoConnect,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  width: 25,
                  margin: const EdgeInsets.only(left: 8),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Transform.scale(
                      scale: 0.5,
                      child: ValueListenableBuilder(
                        valueListenable: widget.settings,
                        builder: (context, settings, _) => CupertinoSwitch(
                          value: settings.connects,
                          activeTrackColor: theme.primary,
                          onChanged: (value) => widget.settings.save(
                            settings.copyWith(autoConnect: value),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Opens the instance's [url] (its own or its organization's) in the
  /// browser, like the screenshots button.
  Widget linkButton(IconData icon, String toolTip, String url) {
    return MouseIconButton(
      icon: icon,
      size: 17.0,
      toolTip: toolTip,
      color: InstanceTheme.of(context).text,
      hoverColor: Colors.white.withValues(alpha: 0.5),
      backgroundSize: 35.0,
      backgroundColor: Colors.white.withValues(alpha: 0.12),
      onTap: () async {
        if (url.startsWith("file://")) {
          await Directory(url.substring(7)).create();
          launchUrlString(url);
        }

        final uri = Uri.tryParse(url);
        if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
      },
    );
  }

  /// Repairs and updates the instance, checks its game files and starts
  /// the game, while the bar above shows it is working. Then waits for the
  /// game to close.
  Future<void> play() async {
    if (Utility.isLaunching.value || Utility.isPlaying.value) return;
    Utility.isLaunching.value = true;

    final organization = widget.organization;
    final instance = widget.instance;
    try {
      final versionId = await InstanceInstaller.play(
        OrganizationAuth.clientFor(organization),
        organization.key,
        instance,
      );
      final game = await Minecraft.launch(
        instance,
        widget.folder,
        versionId,
        await InstanceManager.sharedFolder(),
        widget.settings.value,
        onStarted: onGameStarted,
      );
      onGameClosed(game);
    } catch (e) {
      log("Launch of ${instance.id} failed: $e");
      onLaunchFailed(e);
    }
  }

  /// Play says the game is running, and the launcher hides unless it stays
  /// open.
  void onGameStarted() {
    Utility.isLaunching.value = false;
    Utility.isPlaying.value = true;
    if (!GlobalSettings.keepLauncherOpen) {
      WindowManager.instance.getCurrent()?.hide();
    }
  }

  /// A game that ended well closes the launcher unless it stays open; one
  /// that crashed brings it back to say so.
  void onGameClosed(GameExit game) {
    if (!game.started) return onLaunchFailed(null);

    Utility.isPlaying.value = false;
    if (!game.crashed) {
      if (!GlobalSettings.keepLauncherOpen) exit(0);
      return;
    }

    showWindow();
    if (!mounted) return;

    final l = Utility.getLocalizations(context);
    final logs = GameProcess.logsFolder(widget.folder);
    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: l.gameCrashedTitle,
          description: l.gameCrashedDesc(widget.instance.name),
          mainButtonText: l.exportLog,
          mainButtonOnPressed: exportLog,
          secondaryButtonText: l.close,
          linkText: l.openLogsFolder,
          linkOnPressed: () => launchUrl(Uri.file(logs.path)),
        );
      },
    );
  }

  /// Saves the last game's logs where the player chooses.
  Future<void> exportLog() async {
    final l = Utility.getLocalizations(context);
    final instance = widget.instance;
    await LogExport.export(
      instance,
      widget.folder,
      (date) => l.logsFileName(instance.id, date),
    );
  }

  void showWindow() {
    final window = WindowManager.instance.getCurrent();
    window?.show();
    window?.focus();
  }

  /// Re-enables Play and tells the user why the game couldn't be started.
  void onLaunchFailed(Object? error) {
    Utility.isLaunching.value = false;
    Utility.isPlaying.value = false;
    showWindow();
    if (!mounted) return;

    final l = Utility.getLocalizations(context);
    final name = widget.instance.name;
    final cause = error is GameFilesError ? error.cause : error;
    if (error is ApiError && !InstanceInstaller.isOffline(error)) {
      InstanceCatalog.refresh(widget.organization);
    }

    final (title, description) = switch (error) {
      null => (l.launchError, l.launchErrorDesc),
      NotEnoughSpaceError(:final needed, :final available) => (
        l.notEnoughSpaceTitle,
        l.notEnoughSpaceDesc(
          name,
          (needed / (1024 * 1024)).ceil(),
          (available / (1024 * 1024)).floor(),
        ),
      ),
      ApiError(type: ApiErrorType.notFound) => (
        l.instanceGoneTitle(name),
        l.instanceGoneDesc,
      ),
      GameFilesError(
        cause: UnsupportedLoaderError(:final loader, :final minecraft),
      ) =>
        (
          l.launchError,
          l.loaderNotSupportedDesc(name, loader.displayName, minecraft),
        ),
      _ when cause != null && InstanceInstaller.isOffline(cause) => (
        l.organizationUnreachableTitle(widget.organization.name),
        l.organizationUnreachableDesc,
      ),
      _ => (l.launchError, l.launchErrorDesc),
    };

    showDialog(
      context: context,
      builder: (context) {
        return CustomDialog(
          title: title,
          description: description,
          mainButtonText: l.close,
          mainButtonOnPressed: () => Navigator.pop(context),
        );
      },
    );
  }
}
