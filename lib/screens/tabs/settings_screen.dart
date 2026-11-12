import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/screens/organizations_screen.dart';
import 'package:bc_launcher/models/instance_settings.dart';
import 'package:bc_launcher/services/game_process.dart';
import 'package:bc_launcher/services/instance_settings_store.dart';
import 'package:bc_launcher/services/log_export.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:bc_launcher/utils/global_settings.dart';
import 'package:bc_launcher/utils/system_memory.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/custom_button.dart';
import 'package:bc_launcher/widgets/launcher_dialog.dart';
import 'package:bc_launcher/widgets/instance_actions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final String organizationKey;
  final Instance instance;

  /// The instance's folder.
  final Directory folder;

  /// The instance's game settings.
  final InstanceSettingsStore settings;

  const SettingsScreen({
    super.key,
    required this.organizationKey,
    required this.instance,
    required this.folder,
    required this.settings,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  /// The widest the settings get; wider windows center them.
  static const maxWidth = 1200.0;

  final resolutionWith = TextEditingController();
  final resoulutionHeight = TextEditingController();

  Color get textColor => InstanceTheme.of(context).text;
  Color get greyColor => textColor.withValues(alpha: 0.55);
  Color get borderColor => textColor.withValues(alpha: 0.09);

  /// The RAM slider's maximum: the computer's.
  int maxRam = SystemMemory.fallbackGb;

  InstanceSettings get settings => widget.settings.value;

  @override
  void initState() {
    super.initState();
    widget.settings.addListener(_changed);
    SystemMemory.totalGb().then((gb) {
      if (mounted) setState(() => maxRam = gb);
    });
  }

  @override
  void dispose() {
    widget.settings.removeListener(_changed);
    super.dispose();
  }

  void _changed() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);

    // As tall as the tab (MainScreen's Stack takes its size), scrolling only
    // when the window is too small to show it all.
    return SizedBox.expand(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          Constants.horizontalPadding,
          36,
          Constants.horizontalPadding,
          36,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                header(),
                const SizedBox(height: 26),
                // Both columns as tall as the taller one, so their bottoms line up.
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: instanceGroup()),
                      const SizedBox(width: 28),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            group(l.settingsAllInstancesGroup, [
                              row(
                                l.openLastInstance,
                                l.openLastInstanceDesc,
                                switchControl(
                                  GlobalSettings.openLastInstance,
                                  GlobalSettings.setOpenLastInstance,
                                ),
                              ),
                              row(
                                l.keepLauncherOpen,
                                l.keepLauncherOpenDesc,
                                switchControl(
                                  GlobalSettings.keepLauncherOpen,
                                  GlobalSettings.setKeepLauncherOpen,
                                ),
                              ),
                            ]),
                            const SizedBox(height: 26),
                            group(l.settingsSupportGroup, [
                              row(l.gameLogs, l.gameLogsDesc, gameLogs()),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The title, and resetting or deleting the instance.
  Widget header() {
    final l = Utility.getLocalizations(context);

    return Row(
      children: [
        Expanded(
          child: Text(
            l.gameSettings,
            style: TextStyle(color: textColor, fontSize: 20.5),
          ),
        ),
        resetButton(),
        const SizedBox(width: 10),
        deleteButton(),
      ],
    );
  }

  Widget instanceGroup() {
    final l = Utility.getLocalizations(context);

    return group(l.settingsInstanceGroup, [
      row(
        l.fullscreen,
        l.fullscreenDesc,
        switchControl(
          settings.isFullscreen,
          (value) => widget.settings.save(settings.copyWith(fullscreen: value)),
        ),
      ),
      row(l.resolution, l.resolutionDesc, resolutionInput()),
      memoryRow(),
      row(
        l.directory,
        widget.folder.path,
        smallButton(
          l.open,
          onPressed: () => launchUrl(Uri.file(widget.folder.path)),
        ),
        oneLine: true,
      ),
    ]);
  }

  /// [rows] in one card, under their [label].
  Widget group(String label, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(label, style: TextStyle(color: greyColor, fontSize: 12)),
        ),
        Container(
          decoration: BoxDecoration(
            color: textColor.withValues(alpha: 0.035),
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, thickness: 1, color: borderColor),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// A setting: its title and description, and its [control] on the right.
  Widget row(
    String title,
    String description,
    Widget control, {
    bool oneLine = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: textColor, fontSize: 14.5)),
                const SizedBox(height: 3),
                Text(
                  description,
                  maxLines: oneLine ? 1 : null,
                  overflow: oneLine ? TextOverflow.ellipsis : null,
                  style: TextStyle(color: greyColor, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          control,
        ],
      ),
    );
  }

  /// A switch; [save] sets and saves its value.
  Widget switchControl(bool value, Future<void> Function(bool value) save) {
    return SizedBox(
      height: 22,
      child: FittedBox(
        child: Switch(
          value: value,
          onChanged: (value) {
            save(value);
            setState(() {});
          },
        ),
      ),
    );
  }

  /// One side of the resolution.
  Widget input({
    required TextEditingController controller,
    required bool isWidth,
  }) {
    return Container(
      height: 32,
      width: 64,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.5,
          color: textColor.withValues(alpha: 0.14),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        style: TextStyle(color: textColor, fontSize: 12),
        cursorColor: Colors.transparent,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.only(bottom: 14),
          hintStyle: TextStyle(color: textColor),
          hintText: isWidth ? "${settings.width}" : "${settings.height}",
        ),
        onTapOutside: (value) {
          saveResolution(true);
          saveResolution(false);
        },
      ),
    );
  }

  void saveResolution(bool isWidth) {
    final controller = isWidth ? resolutionWith : resoulutionHeight;

    final value = int.tryParse(controller.text);
    if (value == null) {
      controller.text = "${isWidth ? settings.width : settings.height}";
      return;
    }

    controller.clear();
    widget.settings.save(
      isWidth
          ? settings.copyWith(gameWidth: value)
          : settings.copyWith(gameHeight: value),
    );
  }

  /// Only used in a window.
  Widget resolutionInput() {
    return IgnorePointer(
      ignoring: settings.isFullscreen,
      child: Opacity(
        opacity: settings.isFullscreen ? 0.4 : 1,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            input(controller: resolutionWith, isWidth: true),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                "×",
                style: TextStyle(color: greyColor, fontSize: 12),
              ),
            ),
            input(controller: resoulutionHeight, isWidth: false),
          ],
        ),
      ),
    );
  }

  /// The RAM: its title and the instance's recommendation, and the slider
  /// under them, as wide as the card.
  Widget memoryRow() {
    final l = Utility.getLocalizations(context);
    final ram = settings.ram(widget.instance, maxRam);
    final recommended = widget.instance.recommendedRamMb;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l.memoryAllocation,
                  style: TextStyle(color: textColor, fontSize: 14.5),
                ),
              ),
              if (recommended != null)
                Text(
                  l.memoryRecommended((recommended / 1024).ceil()),
                  style: TextStyle(color: greyColor, fontSize: 11.5),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: SliderTheme(
                  data: const SliderThemeData(
                    thumbShape: _RectSliderThumbShape(),
                    overlayShape: RoundSliderOverlayShape(overlayRadius: 15),
                    overlayColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(horizontal: 9),
                  ),
                  child: Slider(
                    value: ram.toDouble(),
                    min: 1,
                    max: maxRam < 2 ? 2 : maxRam.toDouble(),
                    onChanged: (value) {
                      final gb = value.round();
                      if (gb != ram) {
                        widget.settings.save(settings.copyWith(ramGb: gb));
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 56,
                height: 32,
                alignment: Alignment.center,
                margin: const EdgeInsets.only(right: 7),
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1.5,
                    color: textColor.withValues(alpha: 0.14),
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  "$ram",
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              ),
              Text("GB", style: TextStyle(color: greyColor, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget gameLogs() {
    final l = Utility.getLocalizations(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        smallButton(
          l.openFolder,
          outlined: true,
          onPressed: () async {
            final logs = GameProcess.logsFolder(widget.folder);
            await logs.create(recursive: true);
            launchUrl(Uri.file(logs.path));
          },
        ),
        const SizedBox(width: 8),
        smallButton(l.export, onPressed: exportLogs),
      ],
    );
  }

  Future<void> exportLogs() async {
    final l = Utility.getLocalizations(context);
    final instance = widget.instance;
    final exported = await LogExport.export(
      instance,
      widget.folder,
      (date) => l.logsFileName(instance.id, date),
    );
    if (exported || !mounted) return;

    LauncherDialog.show<void>(
      context,
      (context) => LauncherDialog(
        badge: LauncherDialog.iconBadge(Icons.description_outlined),
        title: l.noLogsTitle,
        description: l.noLogsDesc,
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

  /// Filled white, or outlined: in [color] when given, else grey.
  Widget smallButton(
    String text, {
    bool outlined = false,
    Color? color,
    required VoidCallback? onPressed,
  }) {
    outlined = outlined || color != null;

    return MouseRegion(
      cursor: onPressed == null ? MouseCursor.defer : SystemMouseCursors.click,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : Colors.white,
            border: outlined
                ? Border.all(color: color ?? textColor.withValues(alpha: 0.45))
                : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              color: outlined ? color ?? textColor : Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  /// Back to the instance's default game settings; the launcher's own stay.
  Widget resetButton() {
    final l = Utility.getLocalizations(context);

    return smallButton(
      l.resetSettings,
      outlined: true,
      onPressed: () async {
        await widget.settings.reset();
        if (!mounted) return;

        setState(() {
          resolutionWith.clear();
          resoulutionHeight.clear();
        });
      },
    );
  }

  /// Deletes the instance from this computer and goes back to the list.
  Widget deleteButton() {
    final l = Utility.getLocalizations(context);

    return ValueListenableBuilder(
      valueListenable: Utility.isPlaying,
      builder: (context, playing, _) => Opacity(
        opacity: playing ? 0.4 : 1,
        child: smallButton(
          l.deleteInstance,
          color: Constants.dangerTextColor.withValues(alpha: 0.9),
          onPressed: playing
              ? null
              : () async {
                  final instance = widget.instance;
                  final deleted = await InstanceActions.delete(
                    context,
                    widget.organizationKey,
                    instance.id,
                    instance.name,
                    iconUrl: instance.iconUrl,
                  );
                  if (deleted && mounted) {
                    Utility.pushReplacement(
                      context,
                      const OrganizationsScreen(),
                    );
                  }
                },
        ),
      ),
    );
  }
}

class _RectSliderThumbShape extends SliderComponentShape {
  const _RectSliderThumbShape();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return const Size(10, 0);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    assert(sliderTheme.thumbColor != null);
    final thumbColor = sliderTheme.thumbColor!;

    final outterRect = Rect.fromCenter(center: center, width: 18, height: 18);

    final innerRect = Rect.fromCenter(center: center, width: 15, height: 15);

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(outterRect, const Radius.circular(2)),
      Paint()..color = thumbColor,
    );

    context.canvas.drawRRect(
      RRect.fromRectAndRadius(innerRect, const Radius.circular(2)),
      Paint()
        ..color = Color.fromARGB(
          thumbColor.a.toInt(),
          thumbColor.r.toInt() - 40,
          thumbColor.g.toInt() - 40,
          thumbColor.b.toInt() - 40,
        ),
    );
  }
}
