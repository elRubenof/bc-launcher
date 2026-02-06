import 'package:bc_launcher/screens/main_screen.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/minecraft.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/loading_widget.dart';
import 'package:bc_launcher/widgets/window_buttons.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InstancesScreen extends StatefulWidget {
  const InstancesScreen({super.key});

  @override
  State<InstancesScreen> createState() => _InstancesScreenState();
}

class _InstancesScreenState extends State<InstancesScreen> {
  late Future<Map<String, dynamic>> _authFuture;

  int selectedIndex = -1;
  bool showLoading = false;

  @override
  void initState() {
    super.initState();

    _authFuture = Utility.getAuth(Minecraft.profile.value!.uuid).then((value) {
      autoSelectInstance(value);
      return value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Constants.backgroundColor,
      body: Stack(
        children: [
          FutureBuilder(
            future: _authFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const LoadingScreen();
              }

              final data = snapshot.data!;
              if (data['error'] != null) {
                final l = Utility.getLocalizations(context);

                return Stack(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          border: Border.all(
                            width: 0.5,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          data['statusCode'] == 401
                              ? l.userNotAuthorized.toUpperCase()
                              : l.serverNotResponding.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: Constants.topBarHeight,
                      child: MoveWindow(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: Constants.horizontalPadding,
                          ),
                          alignment: Alignment.centerRight,
                          child: const WindowButtons(
                            enableSettings: false,
                            darkMode: true,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              final servers = data['servers'];
              servers.sort((a, b) {
                if (a['isActive'] == b['isActive']) return 0;
                return a['isActive'] == true ? -1 : 1;
              });

              return Stack(
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 70),
                      constraints: const BoxConstraints(
                        minWidth: 300,
                        minHeight: 350,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        border: Border.all(
                          width: 0.5,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(servers.length, (index) {
                          final isActive = servers[index]['isActive'] as bool;

                          return GestureDetector(
                            child: MouseRegion(
                              cursor:
                                  isActive
                                      ? SystemMouseCursors.click
                                      : SystemMouseCursors.basic,
                              onEnter:
                                  (event) =>
                                      setState(() => selectedIndex = index),
                              onExit:
                                  (event) => setState(() => selectedIndex = -1),
                              child: Container(
                                width: 150,
                                margin: const EdgeInsets.all(5),
                                alignment: Alignment.center,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5),
                                  color: Colors.white.withValues(
                                    alpha:
                                        isActive
                                            ? index == selectedIndex && isActive
                                                ? 0.06
                                                : 0.04
                                            : 0.03,
                                  ),
                                ),
                                child: Text(
                                  "${servers[index]['name']}",
                                  style: TextStyle(
                                    color: Colors.white.withValues(
                                      alpha: isActive ? 1 : 0.4,
                                    ),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            onTap: () => checkInstallAndTravel(servers[index]),
                          );
                        }),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: Constants.topBarHeight,
                    child: MoveWindow(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Constants.horizontalPadding,
                        ),
                        alignment: Alignment.centerRight,
                        child: const WindowButtons(
                          enableSettings: false,
                          darkMode: true,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          if (showLoading) const LoadingScreen(),
        ],
      ),
    );
  }

  void autoSelectInstance(Map<String, dynamic> data) async {
    final preferences = await SharedPreferences.getInstance();
    final savedInstance = preferences.getString('savedInstance');

    if (savedInstance == null || data['error'] != null) return;

    if (!(await Utility.getInstanceDir(savedInstance)).existsSync()) {
      await preferences.remove('savedInstance');
      return;
    }

    final server = data['servers'].where((e) => e['id'] == savedInstance);
    if (server.isNotEmpty) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation1, animation2) {
            return MainScreen(server: server.first);
          },
          transitionDuration: Duration.zero,
        ),
      );
    }
  }

  void checkInstallAndTravel(Map<String, dynamic> server) async {
    if (!server['isActive']) return;

    final installDir = await Utility.getInstanceDir(server['id']);
    if (!installDir.existsSync()) {
      setState(() => showLoading = true);
      await Utility.installInstance(server, installDir);
    }

    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('savedInstance', server['id']);

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) {
          return MainScreen(server: server);
        },
        transitionDuration: Duration.zero,
      ),
    );
  }
}
