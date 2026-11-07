import 'package:bc_launcher/models/instance.dart';
import 'package:bc_launcher/models/organization.dart';
import 'package:bc_launcher/services/news_catalog.dart';
import 'package:bc_launcher/services/organization_auth.dart';
import 'package:bc_launcher/utils/constants.dart';
import 'package:bc_launcher/widgets/news_carousel.dart';
import 'package:flutter/material.dart';

/// The instance's home: its news on the right.
class HomeScreen extends StatefulWidget {
  final Organization organization;
  final Instance instance;

  const HomeScreen({
    super.key,
    required this.organization,
    required this.instance,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  /// How far Play rises over the bottom bar, and the gap the news leave
  /// above it.
  static const _playOverBar = 12.0, _gapOverPlay = 30.0;
  static const _topGap = 34.0;

  late final NewsCatalog catalog = NewsCatalog.forInstance(
    OrganizationAuth.clientFor(widget.organization),
    widget.instance.id,
  )..load();

  @override
  void dispose() {
    catalog.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(
          top: _topGap,
          right: Constants.horizontalPadding,
          bottom: _playOverBar + _gapOverPlay,
        ),
        child: SizedBox(width: 500, child: NewsCarousel(catalog: catalog)),
      ),
    );
  }
}
