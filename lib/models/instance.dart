import 'package:bc_launcher/models/instance_colors.dart';
import 'package:bc_launcher/models/web_tab.dart';

enum LoaderType { vanilla, fabric, quilt, forge, neoforge }

/// An instance the player can play (`GET /api/v1/instances`).
class Instance {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String backgroundUrl;
  final InstanceColors colors;
  final List<WebTab> tabs;
  final String? discordUrl;
  final String? webUrl;
  final String minecraftVersion;
  final LoaderType loaderType;
  final String? loaderVersion;
  final String? serverAddress;
  final int? recommendedRamMb;
  final int contentVersion;

  const Instance({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    required this.backgroundUrl,
    required this.colors,
    required this.tabs,
    this.discordUrl,
    this.webUrl,
    required this.minecraftVersion,
    required this.loaderType,
    this.loaderVersion,
    this.serverAddress,
    this.recommendedRamMb,
    required this.contentVersion,
  });

  factory Instance.fromJson(Map<String, dynamic> json) {
    return Instance(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      iconUrl: json['iconUrl'],
      backgroundUrl: json['backgroundUrl'],
      colors: InstanceColors.fromJson(json['colors']),
      tabs: [for (final tab in json['tabs']) WebTab.fromJson(tab)],
      discordUrl: json['discordUrl'],
      webUrl: json['webUrl'],
      minecraftVersion: json['minecraft']['version'],
      loaderType: LoaderType.values.byName(json['loader']['type']),
      loaderVersion: json['loader']['version'],
      serverAddress: json['serverAddress'],
      recommendedRamMb: json['recommendedRamMb'],
      contentVersion: json['contentVersion'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'iconUrl': iconUrl,
    'backgroundUrl': backgroundUrl,
    'colors': colors.toJson(),
    'tabs': [for (final tab in tabs) tab.toJson()],
    'discordUrl': discordUrl,
    'webUrl': webUrl,
    'minecraft': {'version': minecraftVersion},
    'loader': {'type': loaderType.name, 'version': loaderVersion},
    'serverAddress': serverAddress,
    'recommendedRamMb': recommendedRamMb,
    'contentVersion': contentVersion,
  };
}
