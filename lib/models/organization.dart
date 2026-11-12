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

  /// Reads an organization saved with [toJson]. Only [url] is required: the
  /// rest is a cache that the next discovery refreshes, so a field missing
  /// (saved by an older launcher) or unknown falls back to a default.
  factory Organization.fromJson(Map<String, dynamic> json) {
    final apiVersion = json['apiVersion'] is int ? json['apiVersion'] : 1;
    return Organization(
      url: json['url'] as String,
      apiVersion: apiVersion,
      name: json['name'] is String ? json['name'] : Uri.parse(json['url']).host,
      description: _string(json['description']),
      logoUrl: _string(json['logoUrl']),
      discordUrl: _string(json['discordUrl']),
      webUrl: _string(json['webUrl']),
      visibility:
          OrganizationVisibility.values.asNameMap()[json['visibility']] ??
          OrganizationVisibility.public,
      apiVersions: json['apiVersions'] is List
          ? List<int>.from(json['apiVersions'])
          : [apiVersion],
      minLauncherVersion: _string(json['minLauncherVersion']),
      capabilities: json['capabilities'] is List
          ? List<String>.from(json['capabilities'])
          : const [],
      authType:
          AuthType.values.asNameMap()[json['authType']] ??
          AuthType.mojangSession,
    );
  }

  /// Identifies the organization in the launcher (its token, its folder).
  String get key => keyOf(url);

  /// The key of the organization at [url]: its host, its port unless it is
  /// the scheme's default (`Uri` leaves those out), and its path, so two
  /// organizations on the same host under different paths stay apart. The
  /// scheme doesn't count: http and https are the same organization. `:` and
  /// `/` become `_` so it is a valid folder name everywhere.
  static String keyOf(String url) {
    final uri = Uri.parse(url.contains("://") ? url : "https://$url");
    final port = uri.hasPort ? "_${uri.port}" : "";
    final path = uri.pathSegments.where((s) => s.isNotEmpty).join("_");
    return "${uri.host}$port${path.isEmpty ? "" : "_$path"}";
  }

  static String? _string(Object? value) => value is String ? value : null;

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

  /// Whether [launcherVersion] is older than [minLauncherVersion].
  bool needsNewerLauncher(String launcherVersion) {
    final minimum = minLauncherVersion;
    return minimum != null && _isOlder(launcherVersion, minimum);
  }

  /// Whether the `x.y.z` version [current] is lower than [minimum]. A build
  /// or pre-release suffix (`+1`, `-beta`) is ignored; missing parts are 0.
  static bool _isOlder(String current, String minimum) {
    List<int> parts(String version) => version
        .split(RegExp(r'[+-]'))
        .first
        .split('.')
        .map((part) => int.tryParse(part) ?? 0)
        .toList();

    final a = parts(current), b = parts(minimum);
    for (var i = 0; i < 3; i++) {
      final x = i < a.length ? a[i] : 0, y = i < b.length ? b[i] : 0;
      if (x != y) return x < y;
    }
    return false;
  }

  static AuthType _authType(String value) => switch (value) {
    'mojang-session' => AuthType.mojangSession,
    'unverified' => AuthType.unverified,
    _ => throw FormatException("Unknown auth type: $value"),
  };
}
