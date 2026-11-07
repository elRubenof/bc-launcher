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
import 'package:bc_launcher/widgets/custom_dialog.dart';
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
  final resolutionWith = TextEditingController();
  final resoulutionHeight = TextEditingController();

  Color get textColor => InstanceTheme.of(context).text;
  Color get greyColor => textColor.withValues(alpha: 0.45);

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

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Constants.horizontalPadding,
        vertical: 50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          title(l.gameSettings),
          section(l.directory, l.directoryDesc),
          input(text: widget.folder.path),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    section(l.resolution, l.resolutionDesc),
                    resolutionInput(),
                    section(l.memoryAllocation),
                    memoryBar(),
                  ],
                ),
              ),
              const SizedBox(width: 60),
              Expanded(
                child: Column(
                  children: [
                    toggle(
                      l.openLastInstance,
                      l.openLastInstanceDesc,
                      GlobalSettings.openLastInstance,
                      GlobalSettings.setOpenLastInstance,
                    ),
                    const SizedBox(height: 30),
                    toggle(
                      l.keepLauncherOpen,
                      l.keepLauncherOpenDesc,
                      GlobalSettings.keepLauncherOpen,
                      GlobalSettings.setKeepLauncherOpen,
                    ),
                    const SizedBox(height: 30),
                    gameLogs(),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              resetButton(),
              const SizedBox(width: 16),
              deleteButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget title(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 33),
      child: Text(text, style: TextStyle(color: textColor, fontSize: 20.5)),
    );
  }

  Widget section(String title, [String? description]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: description != null ? 3 : 18),
          child: Text(title, style: TextStyle(color: textColor, fontSize: 17)),
        ),
        if (description != null)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            child: Text(
              description,
              style: TextStyle(color: greyColor, fontSize: 11),
            ),
          ),
      ],
    );
  }

  Widget input({
    String? text,
    TextEditingController? controller,
    bool? isWidth,
  }) {
    final l = Utility.getLocalizations(context);

    return Container(
      height: 41,
      margin: EdgeInsets.only(bottom: text != null ? 50 : 0),
      decoration: BoxDecoration(
        border: Border.all(
          width: 1.5,
          color: greyColor.withValues(alpha: 0.15),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: text != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.75),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: smallButton(
                    l.open,
                    onPressed: () => launchUrl(Uri.file(text)),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: 70,
              child: TextField(
                controller: controller,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 11),
                cursorColor: Colors.transparent,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 8),
                  hintStyle: TextStyle(color: textColor),
                  hintText: isWidth!
                      ? "${settings.width}"
                      : "${settings.height}",
                ),
                onTapOutside: (value) {
                  saveResolution(true);
                  saveResolution(false);
                },
              ),
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

  Widget resolutionInput() {
    final l = Utility.getLocalizations(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 50),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Only used in a window.
          IgnorePointer(
            ignoring: settings.isFullscreen,
            child: Opacity(
              opacity: settings.isFullscreen ? 0.4 : 1,
              child: Row(
                children: [
                  input(controller: resolutionWith, isWidth: true),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      "X",
                      style: TextStyle(color: greyColor, fontSize: 12),
                    ),
                  ),
                  input(controller: resoulutionHeight, isWidth: false),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Transform.scale(
              scale: 0.6,
              child: Switch(
                value: settings.isFullscreen,
                onChanged: (value) =>
                    widget.settings.save(settings.copyWith(fullscreen: value)),
              ),
            ),
          ),
          Text(l.fullscreen, style: TextStyle(color: greyColor)),
        ],
      ),
    );
  }

  /// A setting with its switch; [save] sets and saves it.
  Widget toggle(
    String title,
    String description,
    bool value,
    Future<void> Function(bool value) save,
  ) {
    return Row(
      children: [
        Expanded(child: section(title, description)),
        const SizedBox(width: 16),
        Transform.scale(
          scale: 0.6,
          child: Switch(
            value: value,
            onChanged: (value) {
              save(value);
              setState(() {});
            },
          ),
        ),
      ],
    );
  }

  Widget gameLogs() {
    final l = Utility.getLocalizations(context);

    return Row(
      children: [
        Expanded(child: section(l.gameLogs, l.gameLogsDesc)),
        const SizedBox(width: 16),
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

    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: l.noLogsTitle,
        description: l.noLogsDesc,
        mainButtonText: l.close,
        mainButtonOnPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget smallButton(
    String text, {
    bool outlined = false,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: onPressed,
        child: Container(
          padding: const EdgeInsets.only(
            left: 15,
            right: 15,
            top: 3,
            bottom: 4,
          ),
          decoration: BoxDecoration(
            color: outlined ? Colors.transparent : Colors.white,
            border: outlined ? Border.all(color: greyColor) : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Text(
            text.toUpperCase(),
            style: TextStyle(
              color: outlined ? textColor : Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget memoryBar() {
    final ram = settings.ram(widget.instance, maxRam);

    return Container(
      margin: const EdgeInsets.only(bottom: 60),
      child: Transform.translate(
        offset: const Offset(-10, 0),
        child: Row(
          children: [
            SizedBox(
              width: 420,
              child: SliderTheme(
                data: const SliderThemeData(
                  thumbShape: _RectSliderThumbShape(),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 15),
                  overlayColor: Colors.transparent,
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
            Container(
              width: 60,
              height: 30,
              alignment: Alignment.center,
              margin: const EdgeInsets.only(right: 7),
              decoration: BoxDecoration(
                border: Border.all(
                  width: 1.5,
                  color: greyColor.withValues(alpha: 0.15),
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
      ),
    );
  }

  Widget resetButton() {
    final l = Utility.getLocalizations(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.only(
            left: 24,
            right: 28,
            top: 16,
            bottom: 16,
          ),
          decoration: BoxDecoration(
            //color: const Color(0xFF683D1D),
            border: Border.all(color: Theme.of(context).primaryColor),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.delete,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                l.resetSettings.toUpperCase(),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        onPressed: () async {
          // This instance's and the launcher's own.
          await GlobalSettings.reset();
          await widget.settings.reset();

          setState(() {
            resolutionWith.clear();
            resoulutionHeight.clear();
          });
        },
      ),
    );
  }

  /// Deletes the instance from this computer and goes back to the list.
  Widget deleteButton() {
    final l = Utility.getLocalizations(context);

    return ValueListenableBuilder(
      valueListenable: Utility.isPlaying,
      builder: (context, playing, _) => Opacity(
        opacity: playing ? 0.4 : 1,
        child: MouseRegion(
          cursor: playing ? MouseCursor.defer : SystemMouseCursors.click,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: playing
                ? null
                : () async {
                    final instance = widget.instance;
                    final deleted = await InstanceActions.delete(
                      context,
                      widget.organizationKey,
                      instance.id,
                      instance.name,
                    );
                    if (deleted && mounted) {
                      Utility.pushReplacement(
                        context,
                        const OrganizationsScreen(),
                      );
                    }
                  },
            child: Container(
              padding: const EdgeInsets.only(
                left: 24,
                right: 28,
                top: 16,
                bottom: 16,
              ),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Constants.dangerTextColor.withValues(alpha: 0.55),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    CupertinoIcons.delete,
                    color: Constants.dangerTextColor.withValues(alpha: 0.9),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    l.deleteInstance.toUpperCase(),
                    style: TextStyle(
                      color: Constants.dangerTextColor.withValues(alpha: 0.9),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
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
