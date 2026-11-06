import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:flutter/material.dart';

/// An instance in the list: a header in its own background color with its
/// icon, then its name, description and Minecraft version and loader.
class InstanceCard extends StatefulWidget {
  static const width = 300.0;

  final Instance instance;
  final VoidCallback onTap;

  const InstanceCard({super.key, required this.instance, required this.onTap});

  @override
  State<InstanceCard> createState() => _InstanceCardState();
}

class _InstanceCardState extends State<InstanceCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);
    final instance = widget.instance;
    final colors = instance.colors;

    return Semantics(
      button: true,
      label: instance.name,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: InstanceCard.width,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _hovered ? 0.06 : 0.03),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                width: _hovered ? 1.5 : 0.5,
                color: _hovered
                    ? colors.primary
                    : Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.background,
                    border: Border(
                      bottom: BorderSide(
                        width: 0.5,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  child: _icon(),
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
                        style: const TextStyle(
                          color: Constants.textColor,
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
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _chip(_version(instance)),
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

  static String _version(Instance instance) {
    final loader = switch (instance.loaderType) {
      LoaderType.vanilla => "Vanilla",
      LoaderType.fabric => "Fabric",
      LoaderType.quilt => "Quilt",
      LoaderType.forge => "Forge",
      LoaderType.neoforge => "NeoForge",
    };
    return "${instance.minecraftVersion} · $loader";
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: 11,
        ),
      ),
    );
  }
}
