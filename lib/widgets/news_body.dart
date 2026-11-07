import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:bc_launcher/utils/news_markdown.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A news body's markdown, whole or its first [maxLines].
class NewsBody extends StatefulWidget {
  final String body;

  /// Lines shown, counting every block's; the block that doesn't fit ends
  /// with "…". All when null.
  final int? maxLines;

  /// Told, after the frame, whether [maxLines] left something out.
  final ValueChanged<bool>? onTruncated;

  const NewsBody({
    super.key,
    required this.body,
    this.maxLines,
    this.onTruncated,
  });

  /// Paragraphs and list items, and the summary of a closed news.
  static TextStyle paragraphStyle(Color text) {
    return TextStyle(
      color: text.withValues(alpha: 0.8),
      fontSize: 13,
      height: 1.5,
    );
  }

  @override
  State<NewsBody> createState() => _NewsBodyState();
}

class _NewsBodyState extends State<NewsBody> {
  late List<NewsBlock> blocks = NewsMarkdown.parse(widget.body);
  final List<TapGestureRecognizer> recognizers = [];
  bool? truncated;

  @override
  void didUpdateWidget(NewsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.body != widget.body) {
      blocks = NewsMarkdown.parse(widget.body);
    }
  }

  @override
  void dispose() {
    disposeRecognizers();
    super.dispose();
  }

  void disposeRecognizers() {
    for (final recognizer in recognizers) {
      recognizer.dispose();
    }
    recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    disposeRecognizers();
    final text = InstanceTheme.of(context).text;
    final maxLines = widget.maxLines;
    if (maxLines == null) {
      return column([for (final block in blocks) this.block(block, text)]);
    }

    return LayoutBuilder(
      builder: (context, box) {
        var left = maxLines;
        var cut = false;
        final shown = <Widget>[];
        for (final block in blocks) {
          if (left == 0) {
            cut = true;
            break;
          }
          final lines = lineCount(block, text, box.maxWidth);
          if (lines > left) {
            shown.add(this.block(block, text, maxLines: left));
            cut = true;
            break;
          }
          shown.add(this.block(block, text));
          left -= lines;
        }
        report(cut);
        return column(shown);
      },
    );
  }

  Widget column(List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 8,
      children: children,
    );
  }

  void report(bool cut) {
    if (cut == truncated) return;
    truncated = cut;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => widget.onTruncated?.call(cut),
    );
  }

  /// The lines [block] takes at [width], laid out as [block] lays it out.
  int lineCount(NewsBlock block, Color text, double width) {
    final base = DefaultTextStyle.of(context).style;
    final paragraph = NewsBody.paragraphStyle(text);
    final style = switch (block.type) {
      NewsBlockType.heading => heading(text),
      NewsBlockType.code => code(paragraph),
      _ => paragraph,
    };
    final span = block.type == NewsBlockType.code
        ? TextSpan(text: block.text)
        : spans(block, text, links: false);

    var maxWidth = width;
    if (block.type == NewsBlockType.item) {
      maxWidth -=
          indent(block) +
          measure(TextSpan(text: marker(block)), base.merge(paragraph)).width;
    } else if (block.type == NewsBlockType.code) {
      maxWidth -= _codePadding.horizontal;
    }

    final painter = TextPainter(
      text: TextSpan(style: base.merge(style), children: [span]),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxWidth);
    final lines = painter.computeLineMetrics().length;
    painter.dispose();
    return lines;
  }

  Size measure(TextSpan span, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(style: style, children: [span]),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final size = painter.size;
    painter.dispose();
    return size;
  }

  static const _codePadding = EdgeInsets.symmetric(
    horizontal: 12,
    vertical: 10,
  );

  TextStyle heading(Color text) {
    return TextStyle(color: text, fontSize: 15, fontWeight: FontWeight.bold);
  }

  TextStyle code(TextStyle paragraph) {
    return paragraph.copyWith(fontFamily: 'monospace', fontSize: 12);
  }

  double indent(NewsBlock block) => 14.0 * (block.depth + 1);

  String marker(NewsBlock block) => "${block.marker} ";

  /// [block], cut at [maxLines] with "…" when given.
  Widget block(NewsBlock block, Color text, {int? maxLines}) {
    final paragraph = NewsBody.paragraphStyle(text);
    final overflow = maxLines != null ? TextOverflow.ellipsis : null;

    return switch (block.type) {
      NewsBlockType.heading => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text.rich(
          spans(block, text),
          style: heading(text),
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
      NewsBlockType.paragraph => Text.rich(
        spans(block, text),
        style: paragraph,
        maxLines: maxLines,
        overflow: overflow,
      ),
      NewsBlockType.item => Padding(
        padding: EdgeInsets.only(left: indent(block)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(marker(block), style: paragraph),
            Expanded(
              child: Text.rich(
                spans(block, text),
                style: paragraph,
                maxLines: maxLines,
                overflow: overflow,
              ),
            ),
          ],
        ),
      ),
      NewsBlockType.code => Container(
        width: double.infinity,
        padding: _codePadding,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          block.text,
          style: code(paragraph),
          maxLines: maxLines,
          overflow: overflow,
        ),
      ),
    };
  }

  /// [block]'s text with its styles; [links] can be tapped.
  TextSpan spans(NewsBlock block, Color text, {bool links = true}) {
    return TextSpan(
      children: [
        for (final span in block.spans)
          TextSpan(
            text: span.text,
            style: TextStyle(
              fontWeight: span.bold ? FontWeight.bold : null,
              fontStyle: span.italic ? FontStyle.italic : null,
              fontFamily: span.code ? 'monospace' : null,
              backgroundColor: span.code
                  ? Colors.white.withValues(alpha: 0.1)
                  : null,
              color: span.link != null ? text : null,
              decoration: span.link != null ? TextDecoration.underline : null,
              decorationColor: text,
            ),
            mouseCursor: span.link != null ? SystemMouseCursors.click : null,
            recognizer: span.link == null || !links
                ? null
                : recognizer(span.link!),
          ),
      ],
    );
  }

  TapGestureRecognizer recognizer(Uri link) {
    final recognizer = TapGestureRecognizer()
      ..onTap = () => launchUrl(link, mode: LaunchMode.externalApplication);
    recognizers.add(recognizer);
    return recognizer;
  }
}
