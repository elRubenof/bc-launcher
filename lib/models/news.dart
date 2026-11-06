/// A published news item of an instance
/// (`GET /api/v1/instances/:id/news`).
class News {
  final String id;
  final String title;

  /// Markdown.
  final String body;
  final String? imageUrl;

  /// Where the "Open" button goes; no button without it.
  final String? link;
  final bool pinned;
  final DateTime publishedAt;

  const News({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.link,
    required this.pinned,
    required this.publishedAt,
  });

  factory News.fromJson(Map<String, dynamic> json) {
    return News(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      imageUrl: json['imageUrl'],
      link: json['link'],
      pinned: json['pinned'],
      publishedAt: DateTime.parse(json['publishedAt']),
    );
  }
}
