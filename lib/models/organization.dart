enum OrganizationVisibility { public, private }

enum AuthType { mojangSession, unverified }

/// An organization added by the player, built from its discovery document
/// (`GET /.well-known/bc-launcher`). [url] and [apiVersion] are the
/// launcher's own: the address the player added and the negotiated version.
class Organization {
  final String url;
  final int apiVersion;
  final String name;
  final String? description;
  final String? logoUrl;
  final String? discordUrl;
  final String? webUrl;
  final OrganizationVisibility visibility;
  final List<int> apiVersions;
  final String? minLauncherVersion;
  final List<String> capabilities;
  final AuthType authType;

  const Organization({
    required this.url,
    required this.apiVersion,
    required this.name,
    this.description,
    this.logoUrl,
    this.discordUrl,
    this.webUrl,
    required this.visibility,
    required this.apiVersions,
    this.minLauncherVersion,
    required this.capabilities,
    required this.authType,
  });

  factory Organization.fromDiscovery(
    Map<String, dynamic> json, {
    required String url,
    required int apiVersion,
  }) {
    final links = json['links'] as Map<String, dynamic>;
    return Organization(
      url: url,
      apiVersion: apiVersion,
      name: json['name'],
      description: json['description'],
      logoUrl: json['logoUrl'],
      discordUrl: links['discord'],
      webUrl: links['web'],
      visibility: OrganizationVisibility.values.byName(json['visibility']),
      apiVersions: List<int>.from(json['apiVersions']),
      minLauncherVersion: json['minLauncherVersion'],
      capabilities: List<String>.from(json['capabilities']),
      authType: _authType(json['auth']['type']),
    );
  }

  /// Reads an organization saved with [toJson].
  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      url: json['url'],
      apiVersion: json['apiVersion'],
      name: json['name'],
      description: json['description'],
      logoUrl: json['logoUrl'],
      discordUrl: json['discordUrl'],
      webUrl: json['webUrl'],
      visibility: OrganizationVisibility.values.byName(json['visibility']),
      apiVersions: List<int>.from(json['apiVersions']),
      minLauncherVersion: json['minLauncherVersion'],
      capabilities: List<String>.from(json['capabilities']),
      authType: AuthType.values.byName(json['authType']),
    );
  }

  Map<String, dynamic> toJson() => {
    'url': url,
    'apiVersion': apiVersion,
    'name': name,
    'description': description,
    'logoUrl': logoUrl,
    'discordUrl': discordUrl,
    'webUrl': webUrl,
    'visibility': visibility.name,
    'apiVersions': apiVersions,
    'minLauncherVersion': minLauncherVersion,
    'capabilities': capabilities,
    'authType': authType.name,
  };

  bool hasCapability(String capability) => capabilities.contains(capability);

  static AuthType _authType(String value) => switch (value) {
    'mojang-session' => AuthType.mojangSession,
    'unverified' => AuthType.unverified,
    _ => throw FormatException("Unknown auth type: $value"),
  };
}
