import 'package:markdown/markdown.dart' as md;

enum NewsBlockType { heading, paragraph, item, code }

/// A run of text of a news body with its style.
class NewsSpan {
  final String text;
  final bool bold;
  final bool italic;
  final bool code;

  /// Only http(s) links; any other is plain text.
  final Uri? link;

  const NewsSpan(
    this.text, {
    this.bold = false,
    this.italic = false,
    this.code = false,
    this.link,
  });
}

/// A heading, paragraph, list item or code block of a news body.
class NewsBlock {
  final NewsBlockType type;
  final List<NewsSpan> spans;

  /// A list item's "•" or "1.".
  final String? marker;

  /// How deep a list item is nested, from 0.
  final int depth;

  const NewsBlock(this.type, this.spans, {this.marker, this.depth = 0});

  String get text => spans.map((span) => span.text).join();
}

/// A news body's markdown, as the API allows it: headings, `**bold**`,
/// `*italic*`, lists, `code` and http(s) links. `_` is never italic, because
/// Minecraft names use it.
class NewsMarkdown {
  static List<NewsBlock> parse(String body) {
    final document = md.Document(
      encodeHtml: false,
      withDefaultInlineSyntaxes: false,
      inlineSyntaxes: [
        md.EscapeSyntax(),
        md.AutolinkSyntax(),
        md.LinkSyntax(),
        md.LineBreakSyntax(),
        md.EmphasisSyntax.asterisk(),
        md.CodeSyntax(),
        md.SoftLineBreakSyntax(),
      ],
    );
    final blocks = <NewsBlock>[];
    _blocks(document.parse(body), blocks, depth: 0);
    return blocks;
  }

  static void _blocks(
    List<md.Node> nodes,
    List<NewsBlock> blocks, {
    required int depth,
  }) {
    for (final node in nodes) {
      if (node is md.Text) {
        if (node.text.trim().isEmpty) continue;
        blocks.add(NewsBlock(NewsBlockType.paragraph, [NewsSpan(node.text)]));
        continue;
      }
      if (node is! md.Element) continue;

      switch (node.tag) {
        case 'h1' || 'h2' || 'h3' || 'h4' || 'h5' || 'h6':
          blocks.add(NewsBlock(NewsBlockType.heading, _spans(node.children)));
        case 'p':
          blocks.add(NewsBlock(NewsBlockType.paragraph, _spans(node.children)));
        case 'pre':
          blocks.add(
            NewsBlock(NewsBlockType.code, [
              NewsSpan(node.textContent.trimRight(), code: true),
            ]),
          );
        case 'ul' || 'ol':
          _list(node, blocks, depth: depth);
        case 'hr':
          break;
        default:
          _blocks(node.children ?? [], blocks, depth: depth);
      }
    }
  }

  static void _list(
    md.Element list,
    List<NewsBlock> blocks, {
    required int depth,
  }) {
    var number = int.tryParse(list.attributes['start'] ?? '') ?? 1;
    for (final item in list.children ?? <md.Node>[]) {
      if (item is! md.Element || item.tag != 'li') continue;

      final marker = list.tag == 'ol' ? '${number++}.' : '•';
      final inline = <md.Node>[];
      final nested = <md.Node>[];
      for (final child in item.children ?? <md.Node>[]) {
        final isBlock =
            child is md.Element &&
            (child.tag == 'ul' || child.tag == 'ol' || child.tag == 'pre');
        if (isBlock) {
          nested.add(child);
        } else if (child is md.Element && child.tag == 'p') {
          inline.addAll(child.children ?? []);
        } else {
          inline.add(child);
        }
      }
      blocks.add(
        NewsBlock(
          NewsBlockType.item,
          _spans(inline),
          marker: marker,
          depth: depth,
        ),
      );
      _blocks(nested, blocks, depth: depth + 1);
    }
  }

  static List<NewsSpan> _spans(
    List<md.Node>? nodes, {
    bool bold = false,
    bool italic = false,
    Uri? link,
  }) {
    final spans = <NewsSpan>[];
    for (final node in nodes ?? <md.Node>[]) {
      if (node is md.Text) {
        // A soft line break is a space; a hard one comes as `br`.
        final text = node.text.replaceAll('\n', ' ');
        spans.add(NewsSpan(text, bold: bold, italic: italic, link: link));
        continue;
      }
      if (node is! md.Element) continue;

      switch (node.tag) {
        case 'strong':
          spans.addAll(
            _spans(node.children, bold: true, italic: italic, link: link),
          );
        case 'em':
          spans.addAll(
            _spans(node.children, bold: bold, italic: true, link: link),
          );
        case 'code':
          spans.add(NewsSpan(node.textContent, code: true, link: link));
        case 'br':
          spans.add(const NewsSpan('\n'));
        case 'a':
          spans.addAll(
            _spans(
              node.children,
              bold: bold,
              italic: italic,
              link: _httpLink(node.attributes['href']),
            ),
          );
        case 'img':
          break;
        default:
          spans.addAll(
            _spans(node.children, bold: bold, italic: italic, link: link),
          );
      }
    }
    return spans;
  }

  static Uri? _httpLink(String? href) {
    final uri = href == null ? null : Uri.tryParse(href);
    if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
      return null;
    }
    return uri;
  }
}
