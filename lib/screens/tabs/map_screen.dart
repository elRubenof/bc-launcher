import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';

class MapScreen extends StatefulWidget {
  final String? mapUrl;

  const MapScreen({super.key, required this.mapUrl});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final WebViewController _controller;
  bool show = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) setState(() => show = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.mapUrl!));
  }

  @override
  Widget build(BuildContext context) {
    final l = Utility.getLocalizations(context);

    return Container(
      color: Colors.black,
      child: show
          ? Stack(
              children: [
                const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
                WebViewWidget(controller: _controller),
              ],
            )
          : Center(
              child: Text(
                l.mapError,
                style: const TextStyle(color: Constants.textColor),
              ),
            ),
    );
  }
}
