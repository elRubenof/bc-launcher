import 'package:flutter/material.dart';
import 'package:launcher/widgets/last_news.dart';
import 'package:launcher/widgets/server_status.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _HomeScreenState();
  }
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Container(
      height: height - 130,
      padding: const EdgeInsets.symmetric(horizontal: 80),
      margin: const EdgeInsets.only(bottom: 65),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              ServerStatus(),
              LastNews(),
            ],
          )
        ],
      ),
    );
  }
}
