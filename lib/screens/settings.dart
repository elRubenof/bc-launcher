import 'package:flutter/material.dart';
import 'package:launcher/utils/microsoft.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<StatefulWidget> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(Object context) {
    return const Center(child: Text("Settings"));
  }
}
