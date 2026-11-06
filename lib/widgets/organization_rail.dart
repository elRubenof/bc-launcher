import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/launcher_menu.dart';
import 'package:bc_launcher/widgets/organization_logo.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// The column of added organizations on the left, shown only with two or
/// more. Greyed-out ones carry a lock (no access) or a warning
/// (incompatible). A right click on one offers to remove it.
class OrganizationRail extends StatelessWidget {
  static const width = 84.0;

  /// Asks before removing an organization.
  final void Function(Organization organization) onRemove;

  const OrganizationRail({super.key, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        OrganizationStore.organizations,
        OrganizationStore.selected,
        InstanceCatalog.organizations,
      ]),
      builder: (context, _) => Container(
        width: width,
        color: Colors.black.withValues(alpha: 0.22),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          children: [
            for (final organization in OrganizationStore.organizations.value)
              _item(context, organization),
          ],
        ),
      ),
    );
  }

  Widget _item(BuildContext context, Organization organization) {
    final selected = OrganizationStore.selected.value == organization.key;
    final view = InstanceCatalog.viewOf(organization.key);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: SizedBox(
        height: 48,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (selected)
              Positioned(
                left: 0,
                child: Container(
                  width: 4,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            Tooltip(
              message: organization.name,
              child: Semantics(
                button: true,
                selected: selected,
                label: organization.name,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  // The menu takes the theme without Material's ripple.
                  child: LauncherMenu.withoutRipple(
                    context,
                    Builder(
                      builder: (context) => GestureDetector(
                        onTap: () => OrganizationStore.select(organization.key),
                        onSecondaryTapUp: (details) => LauncherMenu.showAt(
                          context,
                          details.globalPosition,
                          [
                            LauncherMenu.item(
                              CupertinoIcons.delete,
                              Utility.getLocalizations(context)
                                  .removeOrganization,
                              () => onRemove(organization),
                              color: Constants.dangerTextColor,
                              // It deletes the instances' folders, the game's too.
                              enabled: !Utility.isPlaying.value,
                            ),
                          ],
                        ),
                        child: OrganizationLogo(
                          organization: organization,
                          size: 44,
                          greyedOut: view.greyedOut,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (view.greyedOut)
              Positioned(
                left: 52,
                bottom: -2,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                    color: Color(0xFF23162A),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    view.status == OrganizationStatus.noAccess
                        ? Icons.lock_outline_rounded
                        : Icons.warning_amber_rounded,
                    size: 12,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
