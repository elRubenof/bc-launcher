import 'package:bc_launcher/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
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
          ),
        ],
      ),
    );
  }
}
