import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import 'package:webview_windows/webview_windows.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreen();
}

class _MapScreen extends State<MapScreen> {
  final _controller = WebviewController();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) initPlatformState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();
      _controller.url.listen((url) {
        _textController.text = url;
      });

      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl("https://map.massivecraft.com/?nogui=true");

      if (!mounted) return;
      setState(() {});
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Error'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Code: ${e.code}'),
                  Text('Message: ${e.message}'),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Continue'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ],
            ),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Platform.isWindows) {
      return const Expanded(
        child: Center(
          child: Text(
            "Para utilizar esta función debes utilizar Windows",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return FutureBuilder(
      future: outdatedVersion(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();

        if (snapshot.data as bool) {
          return const Center(
            child: Text(
              "Actualiza windows para usar esta función",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        if (!_controller.value.isInitialized) {
          return Container();
        } else {
          return Webview(
            _controller,
            permissionRequested: _onPermissionRequested,
          );
        }
      },
    );
  }

  Future<bool> outdatedVersion() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

    WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;

    return windowsInfo.buildNumber < 1809;
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    return WebviewPermissionDecision.allow;
  }
}
