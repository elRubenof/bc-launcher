import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/instance_actions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// An instance in the list: a header in its own background color with its
/// icon, then its name, description, Minecraft version and loader, and
/// whether it is installed here. Installed ones have a menu to open their
/// folder or delete them.
class InstanceCard extends StatefulWidget {
  static const width = 300.0;

  final String organizationKey;
  final Instance instance;

  /// Installed here but no longer served by the organization: greyed out,
  /// with only its menu.
  final bool unavailable;
  final VoidCallback? onTap;

  const InstanceCard({
    super.key,
    required this.organizationKey,
    required this.instance,
    this.unavailable = false,
    this.onTap,
  });

  @override
  State<InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<InstanceCard> {
  bool _hovered = false;
  InstallStatus? _status;

  @override
  void initState() {
    super.initState();
    _loadStatus();
    InstanceManager.changes.addListener(_loadStatus);
  }

  @override
  void dispose() {
    InstanceManager.changes.removeListener(_loadStatus);
    super.dispose();
  }

  @override
  void didUpdateWidget(InstanceCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.instance != widget.instance) _loadStatus();
  }

  Future<void> _loadStatus() async {
    final status = await InstanceManager.status(
      widget.organizationKey,
      widget.instance,
    );
    if (mounted) setState(() => _status = status);
  }

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);
    final instance = widget.instance;
    final colors = instance.colors;
    final unavailable = widget.unavailable;
    final hovered = _hovered && !unavailable;
    final highlighted =
        hovered || (!unavailable && _status == InstallStatus.updateAvailable);
    final installed =
        unavailable ||
        (_status != null && _status != InstallStatus.notInstalled);
    final textAlpha = unavailable ? 0.6 : 1.0;

    return Semantics(
      button: !unavailable,
      label: instance.name,
      child: MouseRegion(
        cursor: unavailable ? MouseCursor.defer : SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: unavailable ? null : widget.onTap,
          child: Container(
            width: InstanceCard.width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: unavailable ? 0.02 : (hovered ? 0.06 : 0.03),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            // Painted over the card, so a thicker border doesn't resize it.
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: highlighted ? 1.5 : 0.5,
                color: highlighted
                    ? colors.primary
                    : Colors.white.withValues(alpha: unavailable ? 0.15 : 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: 150,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: unavailable
                            ? Colors.white.withValues(alpha: 0.03)
                            : colors.background,
                        border: Border(
                          bottom: BorderSide(
                            width: 0.5,
                            color: Colors.white.withValues(
                              alpha: unavailable ? 0.08 : 0.12,
                            ),
                          ),
                        ),
                      ),
                      child: unavailable
                          ? ColorFiltered(
                              colorFilter: const ColorFilter.matrix(_greyscale),
                              child: Opacity(opacity: 0.6, child: _icon()),
                            )
                          : _icon(),
                    ),
                    if (installed)
                      Positioned(top: 10, right: 10, child: _menu()),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        instance.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Constants.textColor.withValues(
                            alpha: textAlpha,
                          ),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        instance.description ?? l.noDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(
                            alpha: unavailable ? 0.6 : 0.7,
                          ),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _chip(_version(instance)),
                          if (unavailable)
                            _chip(l.unavailable)
                          else if (_status != null)
                            _statusChip(_status!),
                        ],
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

  /// Opens the folder of the installed instance or deletes it.
  Widget _menu() {
    final l = Utility.getLocalizations(context);
    final instance = widget.instance;
    final key = widget.organizationKey;

    return ValueListenableBuilder(
      valueListenable: Utility.isPlaying,
      // Without the ripple Material puts behind the button.
      builder: (context, playing, _) => Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: Colors.transparent,
        ),
        child: PopupMenuButton<VoidCallback>(
          tooltip: "",
          padding: EdgeInsets.zero,
          popUpAnimationStyle: const AnimationStyle(
            duration: Duration(milliseconds: 150),
          ),
          offset: const Offset(0, 34),
          color: const Color(0xFF2F2037),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              width: 0.5,
              color: Colors.white.withValues(alpha: 0.18),
            ),
          ),
          onSelected: (action) => action(),
          itemBuilder: (context) => [
            _menuItem(
              Icons.folder_outlined,
              InstanceActions.openFolderLabel(l),
              () => InstanceActions.openFolder(key, instance.id),
            ),
            _menuItem(
              CupertinoIcons.delete,
              l.deleteFromComputer,
              () => InstanceActions.delete(
                context,
                key,
                instance.id,
                instance.name,
              ),
              color: Constants.dangerTextColor,
              enabled: !playing,
            ),
          ],
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.35),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.more_horiz,
                size: 18,
                color: Constants.textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  PopupMenuItem<VoidCallback> _menuItem(
    IconData icon,
    String text,
    VoidCallback action, {
    Color color = Constants.textColor,
    bool enabled = true,
  }) {
    final shown = enabled ? color : color.withValues(alpha: 0.4);
    return PopupMenuItem(
      value: action,
      enabled: enabled,
      height: 40,
      mouseCursor: SystemMouseCursors.click,
      child: Row(
        children: [
          Icon(icon, size: 16, color: shown),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(color: shown, fontSize: 13)),
        ],
      ),
    );
  }

  /// Leaves only the light of the colors.
  static const _greyscale = <double>[
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 1, 0,
  ];

  Widget _icon() {
    final instance = widget.instance;
    final initials = Container(
      width: 64,
      height: 64,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: instance.colors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        instance.name
            .split(RegExp(r'\s+'))
            .where((word) => word.isNotEmpty)
            .take(2)
            .map((word) => word[0].toUpperCase())
            .join(),
        style: const TextStyle(
          color: Constants.textColor,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    final iconUrl = instance.iconUrl;
    if (iconUrl == null) return initials;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        iconUrl,
        width: 64,
        height: 64,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => initials,
      ),
    );
  }

  static String _version(Instance instance) =>
      "${instance.minecraftVersion} · ${instance.loaderType.displayName}";

  Widget _statusChip(InstallStatus status) {
    final l = Utility.getLocalizations(context);
    return switch (status) {
      InstallStatus.notInstalled => _chip(l.notInstalled),
      InstallStatus.upToDate => _chip(l.installed),
      InstallStatus.updateAvailable => _chip(
        l.updateAvailable,
        color: widget.instance.colors.primary,
      ),
    };
  }

  /// A small label; [color] fills it to stand out.
  Widget _chip(String text, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color == null
              ? Colors.white.withValues(alpha: 0.8)
              : Constants.textColor,
          fontSize: 11,
          fontWeight: color == null ? FontWeight.normal : FontWeight.w600,
        ),
      ),
    );
  }
}
