import 'dart:io';

import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/services/game_process.dart';
import 'package:bc_launcher/services/log_export.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/settings.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/custom_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final Instance instance;

  /// The instance's folder.
  final Directory folder;

  const SettingsScreen({
    super.key,
    required this.instance,
    required this.folder,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final resolutionWith = TextEditingController();
  final resoulutionHeight = TextEditingController();

  final greyColor = Constants.textColor.withValues(alpha: 0.45);

  double allocatedRAM = Settings.allocatedRAM.toDouble();

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
                      Settings.openLastInstance,
                      (value) {
                        Settings.openLastInstance = value;
                        return "openLastInstance";
                      },
                    ),
                    const SizedBox(height: 30),
                    toggle(
                      l.keepLauncherOpen,
                      l.keepLauncherOpenDesc,
                      Settings.keepLauncherOpen,
                      (value) {
                        Settings.keepLauncherOpen = value;
                        return "keepLauncherOpen";
                      },
                    ),
                    const SizedBox(height: 30),
                    gameLogs(),
                  ],
                ),
              ),
            ],
          ),
          resetButton(),
        ],
      ),
    );
  }

  Widget title(String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 33),
      child: Text(
        text,
        style: const TextStyle(color: Constants.textColor, fontSize: 20.5),
      ),
    );
  }

  Widget section(String title, [String? description]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(bottom: description != null ? 3 : 18),
          child: Text(
            title,
            style: const TextStyle(color: Constants.textColor, fontSize: 17),
          ),
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
                      color: Constants.textColor.withValues(alpha: 0.75),
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
                style: const TextStyle(
                  color: Constants.textColor,
                  fontSize: 11,
                ),
                cursorColor: Colors.transparent,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(bottom: 8),
                  hintStyle: const TextStyle(color: Constants.textColor),
                  hintText: isWidth!
                      ? "${Settings.gameWidth}"
                      : "${Settings.gameHeight}",
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
      controller.text = "${isWidth ? Settings.gameWidth : Settings.gameHeight}";
      return;
    }

    if (isWidth) {
      Settings.gameWidth = value;
    } else {
      Settings.gameHeight = value;
    }

    controller.clear();
    setState(() {});

    SharedPreferences.getInstance().then((pref) {
      pref.setInt("gameWidth", Settings.gameWidth);
      pref.setInt("gameHeight", Settings.gameHeight);
    });
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
            ignoring: Settings.fullscreen,
            child: Opacity(
              opacity: Settings.fullscreen ? 0.4 : 1,
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
                value: Settings.fullscreen,
                onChanged: (value) {
                  setState(() {
                    Settings.fullscreen = value;

                    SharedPreferences.getInstance().then((pref) {
                      pref.setBool("fullscreen", value);
                    });
                  });
                },
              ),
            ),
          ),
          Text(l.fullscreen, style: TextStyle(color: greyColor)),
        ],
      ),
    );
  }

  /// A setting with its switch; [save] sets it and gives its preference key.
  Widget toggle(
    String title,
    String description,
    bool value,
    String Function(bool value) save,
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
              setState(() {
                final key = save(value);
                SharedPreferences.getInstance().then((pref) {
                  pref.setBool(key, value);
                });
              });
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
              color: outlined ? Constants.textColor : Colors.black,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget memoryBar() {
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
                  value: allocatedRAM,
                  min: 1,
                  max: 16,
                  onChanged: (value) {
                    setState(() {
                      allocatedRAM = value;
                      Settings.allocatedRAM = value.toInt();
                    });

                    SharedPreferences.getInstance().then((pref) {
                      pref.setInt("allocatedRAM", value.toInt());
                    });
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
                "${Settings.allocatedRAM}",
                style: const TextStyle(
                  color: Constants.textColor,
                  fontSize: 12,
                ),
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
          await Utility.resetSettings();

          setState(() {
            resolutionWith.clear();
            resoulutionHeight.clear();
            allocatedRAM = Settings.allocatedRAM.toDouble();
          });
        },
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
