enum WebTabIcon {
  map,
  trophy,
  calendar,
  book,
  chart,
  live,
  users,
  list,
  form,
  globe,
}

enum WebTabOpenIn { launcher, browser }

/// A web tab of an instance, shown between Home and Settings.
class WebTab {
  final String label;

  /// May contain `{uuid}` and `{name}`, see [resolveUrl].
  final String url;
  final WebTabIcon icon;
  final WebTabOpenIn openIn;

  const WebTab({
    required this.label,
    required this.url,
    required this.icon,
    required this.openIn,
  });

  factory WebTab.fromJson(Map<String, dynamic> json) {
    return WebTab(
      label: json['label'],
      url: json['url'],
      icon: WebTabIcon.values.byName(json['icon']),
      openIn: WebTabOpenIn.values.byName(json['openIn']),
    );
  }

  Map<String, dynamic> toJson() => {
    'label': label,
    'url': url,
    'icon': icon.name,
    'openIn': openIn.name,
  };

  /// [url] with the signed-in player's uuid and name in place of `{uuid}`
  /// and `{name}`.
  Uri resolveUrl({required String uuid, required String name}) {
    return Uri.parse(
      url
          .replaceAll('{uuid}', Uri.encodeComponent(uuid))
          .replaceAll('{name}', Uri.encodeComponent(name)),
    );
  }
}
