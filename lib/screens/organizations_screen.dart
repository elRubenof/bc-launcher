import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/screens/instance_loading_screen.dart';
import 'package:bc_launcher/screens/main_screen.dart';
import 'package:bc_launcher/services/instance_catalog.dart';
import 'package:bc_launcher/services/instance_manager.dart';
import 'package:bc_launcher/services/organization_store.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/settings.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/instance_actions.dart';
import 'package:bc_launcher/widgets/instance_card.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/custom_button.dart';
import 'package:bc_launcher/widgets/organization_logo.dart';
import 'package:bc_launcher/widgets/organization_rail.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

class OrganizationsScreen extends StatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  State<OrganizationsScreen> createState() => _OrganizationsScreenState();
}

class _OrganizationsScreenState extends State<OrganizationsScreen> {
  /// Coming back to the launcher refreshes the instances, at most this often.
  static const _refreshInterval = Duration(seconds: 30);

  /// The last used instance is entered by itself only once per run.
  static bool _autoEntered = false;

  late final AppLifecycleListener _lifecycle;
  DateTime _lastRefresh = DateTime.now();
  bool _entering = false;

  /// While it may still enter the last instance by itself, the loading
  /// screen stays instead of the list, so the list doesn't flash.
  bool _waitingToEnter = !_autoEntered && Settings.openLastInstance;

  /// The instances installed here, by organization, to show the ones it no
  /// longer serves.
  final _installed = <String, Map<String, InstanceState>>{};

  @override
  void initState() {
    super.initState();
    InstanceCatalog.refreshAll();
    _lifecycle = AppLifecycleListener(onResume: _refreshOnReturn);
    InstanceCatalog.organizations.addListener(_autoEnter);
    OrganizationStore.selected.addListener(_loadInstalled);
    InstanceManager.changes.addListener(_loadInstalled);
    _loadInstalled();

    if (_waitingToEnter) {
      final key = OrganizationStore.selected.value ?? "";
      OrganizationStore.lastInstance(key).then((last) {
        if (last == null) _showList();
      });
    }
  }

  @override
  void dispose() {
    InstanceCatalog.organizations.removeListener(_autoEnter);
    OrganizationStore.selected.removeListener(_loadInstalled);
    InstanceManager.changes.removeListener(_loadInstalled);
    _lifecycle.dispose();
    super.dispose();
  }

  /// Enters the last instance used in the selected organization, once its
  /// list is loaded, if it is still there.
  Future<void> _autoEnter() async {
    if (_autoEntered) return;
    if (!Settings.openLastInstance) return _showList();
    final organization = OrganizationStore.byKey(
      OrganizationStore.selected.value ?? "",
    );
    if (organization == null) return _showList();

    final view = InstanceCatalog.viewOf(organization.key);
    if (view.status == OrganizationStatus.loading) return;
    _autoEntered = true;

    final last = await OrganizationStore.lastInstance(organization.key);
    final instance = view.status == OrganizationStatus.ready
        ? view.instances.where((instance) => instance.id == last).firstOrNull
        : null;
    if (instance == null || !await _enter(organization, instance)) {
      _showList();
    }
  }

  void _showList() {
    _autoEntered = true;
    if (mounted && _waitingToEnter) setState(() => _waitingToEnter = false);
  }

  Future<bool> _enter(Organization organization, Instance instance) async {
    if (_entering || !mounted) return false;
    _entering = true;
    try {
      final ready = await Navigator.push<bool>(
        context,
        PageRouteBuilder(
          pageBuilder: (_, _, _) => InstanceLoadingScreen(
            organization: organization,
            instance: instance,
          ),
          transitionDuration: Duration.zero,
        ),
      );
      if (ready != true) return false;

      final folder = await InstanceManager.instanceFolder(
        organization.key,
        instance.id,
      );
      if (!mounted) return false;
      Utility.pushReplacement(
        context,
        MainScreen(
          organization: organization,
          instance: instance,
          folder: folder,
        ),
      );
      return true;
    } finally {
      _entering = false;
    }
  }

  Future<void> _loadInstalled() async {
    final key = OrganizationStore.selected.value;
    if (key == null) return;

    final installed = await InstanceManager.installed(key);
    if (mounted) setState(() => _installed[key] = installed);
  }

  /// The installed instances [organization] no longer serves, newest
  /// installation first.
  List<Instance> _unavailable(
    Organization organization,
    List<Instance> served,
  ) {
    final ids = {for (final instance in served) instance.id};
    final entries =
        (_installed[organization.key] ?? {}).entries
            .where((entry) => !ids.contains(entry.key))
            .toList()
          ..sort((a, b) {
            final epoch = DateTime.fromMillisecondsSinceEpoch(0);
            return (b.value.installedAt ?? epoch).compareTo(
              a.value.installedAt ?? epoch,
            );
          });
    return [
      for (final entry in entries)
        InstanceManager.savedInstance(entry.key, entry.value),
    ];
  }

  void _refreshOnReturn() {
    if (DateTime.now().difference(_lastRefresh) < _refreshInterval) return;
    _lastRefresh = DateTime.now();
    InstanceCatalog.refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    if (_waitingToEnter) return const LoadingScreen();

    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: ListenableBuilder(
        listenable: Listenable.merge([
          OrganizationStore.organizations,
          OrganizationStore.selected,
          InstanceCatalog.organizations,
        ]),
        builder: (context, _) {
          final organizations = OrganizationStore.organizations.value;
          final selected = OrganizationStore.byKey(
            OrganizationStore.selected.value ?? "",
          );
          if (selected == null) return const SizedBox.shrink();

          final showRail = organizations.length > 1;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showRail) OrganizationRail(onRemove: _confirmRemove),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(selected, showLogo: !showRail),
                    Expanded(child: _body(selected)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _header(Organization organization, {required bool showLogo}) {
    final greyedOut = InstanceCatalog.viewOf(organization.key).greyedOut;
    return SizedBox(
      height: Constants.topBarHeight,
      child: DragToMoveArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: showLogo ? Constants.horizontalPadding : 40,
            right: Constants.horizontalPadding,
          ),
          child: Row(
            children: [
              if (showLogo) ...[
                OrganizationLogo(organization: organization, size: 36),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  organization.name,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(
                      alpha: greyedOut ? 0.6 : 0.85,
                    ),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const WindowButtons(enableSettings: false, darkMode: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(Organization organization) {
    final l = Utility.getLocalizations(context);
    final view = InstanceCatalog.viewOf(organization.key);
    final name = organization.name;

    // While refreshing, the instances it had stay on screen.
    final unavailable = _unavailable(organization, view.instances);
    if ((view.instances.isNotEmpty &&
            view.status == OrganizationStatus.loading) ||
        (view.status == OrganizationStatus.ready &&
            (view.instances.isNotEmpty || unavailable.isNotEmpty))) {
      return _instances(organization, view.instances, unavailable);
    }

    return switch (view.status) {
      OrganizationStatus.loading => const Center(
        child: CircularProgressIndicator(color: Constants.mainColor),
      ),
      OrganizationStatus.ready => _message(
        image: true,
        title: l.noInstancesTitle,
        description: l.noInstancesDesc(name),
      ),
      OrganizationStatus.noAccess => _message(
        icon: Icons.lock_outline_rounded,
        title: l.lostAccessTitle(name),
        description: l.lostAccessDesc,
        buttons: [
          CustomButton(
            InstanceActions.openFolderLabel(l),
            filled: false,
            onPressed: () => _openFolder(organization),
          ),
          CustomButton(
            l.removeOrganization,
            filled: false,
            color: Constants.dangerTextColor,
            onPressed: () => _confirmRemove(organization),
          ),
        ],
      ),
      OrganizationStatus.incompatible => _message(
        icon: Icons.warning_amber_rounded,
        title: l.noLongerCompatibleTitle(name),
        description: l.organizationIncompatibleDesc,
        buttons: [
          CustomButton(
            l.downloadNewVersion,
            onPressed: () => launchUrl(Uri.parse(Constants.releasesUrl)),
          ),
          CustomButton(
            InstanceActions.openFolderLabel(l),
            filled: false,
            onPressed: () => _openFolder(organization),
          ),
          CustomButton(
            l.removeOrganization,
            filled: false,
            color: Constants.dangerTextColor,
            onPressed: () => _confirmRemove(organization),
          ),
        ],
      ),
      OrganizationStatus.offline => _message(
        icon: Icons.wifi_off_rounded,
        title: l.organizationUnreachableTitle(name),
        description: l.organizationUnreachableDesc,
        buttons: [
          CustomButton(
            l.retry,
            onPressed: () => InstanceCatalog.refresh(organization),
          ),
        ],
      ),
    };
  }

  /// The instances in a grid that fits as many columns as the window allows
  /// and scrolls only when they don't fit; the title stays on top.
  Widget _instances(
    Organization organization,
    List<Instance> instances,
    List<Instance> unavailable,
  ) {
    final l = Utility.getLocalizations(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(
            l.chooseInstance,
            style: const TextStyle(
              color: Constants.textColor,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => Scrollbar(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 40,
                  ),
                  child: Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 20,
                      runSpacing: 20,
                      children: [
                        for (final instance in instances)
                          InstanceCard(
                            organizationKey: organization.key,
                            instance: instance,
                            onTap: () => _enter(organization, instance),
                          ),
                        for (final instance in unavailable)
                          InstanceCard(
                            key: ValueKey("unavailable ${instance.id}"),
                            organizationKey: organization.key,
                            instance: instance,
                            unavailable: true,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _message({
    IconData? icon,
    bool image = false,
    required String title,
    required String description,
    List<Widget> buttons = const [],
  }) {
    final textColor = Colors.white.withValues(alpha: 0.8);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image)
              SvgPicture.asset(
                "assets/img/logo.svg",
                height: 140,
                colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
              ),
            if (icon != null)
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
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor, fontSize: 14, height: 1.5),
              ),
            ),
            if (buttons.isNotEmpty) ...[
              const SizedBox(height: 28),
              Wrap(spacing: 12, runSpacing: 12, children: buttons),
            ],
          ],
        ),
      ),
    );
  }

  /// Opens the folder with the organization's instances, so the player can
  /// keep their worlds before removing it.
  Future<void> _openFolder(Organization organization) async {
    final folder = await InstanceManager.organizationFolder(organization.key);
    await folder.create(recursive: true);
    await launchUrl(Uri.file(folder.path));
  }

  Future<void> _confirmRemove(Organization organization) async {
    final l = Utility.getLocalizations(context);
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => Center(
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
            width: 480,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                OrganizationLogo(
                  organization: organization,
                  size: 80,
                  greyedOut: true,
                ),
                const SizedBox(height: 24),
                Text(
                  l.removeOrganizationQuestion(organization.name),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Constants.textColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l.removeOrganizationDesc,
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
                  children: [
                    CustomButton(
                      l.remove,
                      color: const Color(0xFFB3261E),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                    CustomButton(
                      l.cancel,
                      filled: false,
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (confirmed != true) return;

    await OrganizationStore.remove(organization);
    InstanceCatalog.forget(organization.key);
    await InstanceManager.deleteOrganization(organization.key);
  }
}
