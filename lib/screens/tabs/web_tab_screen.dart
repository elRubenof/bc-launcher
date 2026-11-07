import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:webview_all/webview_all.dart';

/// A web tab that opens in the launcher.
class WebTabScreen extends StatefulWidget {
  final Uri url;

  const WebTabScreen({super.key, required this.url});

  @override
  State<WebTabScreen> createState() => _WebTabScreenState();
}

class _WebTabScreenState extends State<WebTabScreen> {
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
      ..loadRequest(widget.url);
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
                l.webTabError,
                style: TextStyle(color: InstanceTheme.of(context).text),
              ),
            ),
    );
  }
}
