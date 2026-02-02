import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  bool show = true;

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
                InAppWebView(
                  initialUrlRequest: URLRequest(
                    url: WebUri(
                      Constants.mapUrl,
                    ),
                  ),
                  onReceivedError: (controller, request, error) {
                    setState(() => show = false);
                  },
                ),
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
