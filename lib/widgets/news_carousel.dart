import 'package:bc_launcher/models/news.dart';
import 'package:bc_launcher/services/news_catalog.dart';
import 'package:bc_launcher/utils/instance_theme.dart';
import 'package:bc_launcher/utils/utility.dart';
import 'package:bc_launcher/widgets/news_body.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// An instance's news, one at a time, with arrows to go through them. Empty
/// when it has none or they can't be loaded.
class NewsCarousel extends StatefulWidget {
  final NewsCatalog catalog;

  const NewsCarousel({super.key, required this.catalog});

  @override
  State<NewsCarousel> createState() => _NewsCarouselState();
}

class _NewsCarouselState extends State<NewsCarousel> {
  /// The next page is asked for this many news before the end.
  static const _preload = 3;

  /// Above a news' text; the text fades out within it when scrolled.
  static const _topPadding = 16.0;

  /// The lines of body a closed news shows.
  static const _summaryLines = 3;

  int index = 0;
  bool expanded = false;

  /// Whether the closed news has more body than it shows.
  bool overflowing = false;

  NewsCatalog get catalog => widget.catalog;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: catalog,
      builder: (context, _) {
        final items = catalog.items;
        // No news, or the first page couldn't be loaded: nothing at all.
        if (items.isEmpty) return const SizedBox.shrink();
        if (index > items.length) index = 0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            header(),
            Flexible(
              child: index < items.length
                  ? card(items[index])
                  : catalog.error != null
                  ? errorBox()
                  : loadingCard(),
            ),
          ],
        );
      },
    );
  }

  /// "Latest news" and, when there are news, ‹ 1 / 3 ›.
  Widget header() {
    final l = Utility.getLocalizations(context);
    final text = InstanceTheme.of(context).text;
    final count = catalog.items.length;
    final hasNext =
        index < count - 1 || (index == count - 1 && catalog.hasMore);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          l.latestNews,
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (count > 0)
          Row(
            spacing: 10,
            children: [
              arrow(Icons.chevron_left, index > 0, -1),
              Text(
                "${index + 1} / ${index < count ? count : index + 1}",
                style: TextStyle(
                  color: text.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              arrow(Icons.chevron_right, hasNext, 1),
            ],
          ),
      ],
    );
  }

  Widget arrow(IconData icon, bool enabled, int step) {
    return Opacity(
      opacity: enabled ? 1 : 0.3,
      child: IconButton(
        onPressed: enabled ? () => go(index + step) : null,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        icon: Icon(icon, size: 22),
        color: InstanceTheme.of(context).text,
        disabledColor: InstanceTheme.of(context).text,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
        style: IconButton.styleFrom(overlayColor: Colors.transparent),
      ),
    );
  }

  /// Shows the news at [to], closed, and asks for the next page when it is
  /// near the end.
  void go(int to) {
    setState(() {
      index = to;
      expanded = false;
      overflowing = false;
    });
    if (to >= catalog.items.length - _preload) catalog.load();
  }

  BoxDecoration cardDecoration() {
    return BoxDecoration(
      color: InstanceTheme.of(context).background.withValues(alpha: 0.92),
      border: Border.all(
        width: 0.5,
        color: Colors.white.withValues(alpha: 0.14),
      ),
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget card(News news) {
    final l = Utility.getLocalizations(context);
    final theme = InstanceTheme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Container(
      key: ValueKey(news.id),
      clipBehavior: Clip.antiAlias,
      decoration: cardDecoration(),
      // The image stays; only what is under it scrolls.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (news.imageUrl != null)
            Image.network(
              news.imageUrl!,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const SizedBox.shrink(),
            ),
          Flexible(
            // Fades the text out under the image, within the empty top
            // padding, so it is only seen while scrolling.
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: const [Color(0x00FFFFFF), Color(0xFFFFFFFF)],
                stops: [0, _topPadding / bounds.height],
              ).createShader(bounds),
              child: SingleChildScrollView(
                key: ValueKey(expanded),
                physics: expanded ? null : const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, _topPadding, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          if (news.pinned)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: theme.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l.pinnedNews,
                                style: TextStyle(
                                  color: theme.text,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Text(
                            DateFormat.yMMMd(locale)
                                .format(news.publishedAt.toLocal()),
                            style: TextStyle(
                              color: theme.text.withValues(alpha: 0.6),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        news.title,
                        style: TextStyle(
                          color: theme.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // "Read more" only when the summary doesn't fit.
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: expanded
                            ? NewsBody(body: news.body)
                            : closedBody(news),
                      ),
                      if (expanded || overflowing || news.link != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              if (expanded || overflowing) toggle(),
                              const Spacer(),
                              if (news.link != null) open(news),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The start of [news]' body, as many lines as a closed news shows.
  Widget closedBody(News news) {
    return NewsBody(
      body: news.body,
      maxLines: _summaryLines,
      onTruncated: (value) {
        if (mounted && value != overflowing) {
          setState(() => overflowing = value);
        }
      },
    );
  }

  /// "Read more" / "Read less".
  Widget toggle() {
    final l = Utility.getLocalizations(context);
    final text = InstanceTheme.of(context).text;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => setState(() => expanded = !expanded),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            spacing: 5,
            children: [
              Text(
                expanded ? l.readLess : l.readMore,
                style: TextStyle(
                  color: text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(Icons.expand_more, color: text, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Open ↗", to the news' link.
  Widget open(News news) {
    final l = Utility.getLocalizations(context);
    final text = InstanceTheme.of(context).text;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => launchUrl(
          Uri.parse(news.link!),
          mode: LaunchMode.externalApplication,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(5),
          ),
          child: Row(
            spacing: 6,
            children: [
              Text(
                l.open,
                style: TextStyle(
                  color: text,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(Icons.north_east, color: text, size: 11),
            ],
          ),
        ),
      ),
    );
  }

  /// A news that hasn't arrived yet.
  Widget loadingCard() {
    final theme = InstanceTheme.of(context);
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: cardDecoration(),
      child: SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: theme.primary,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  /// The news couldn't be loaded, with "Retry".
  Widget errorBox() {
    final l = Utility.getLocalizations(context);
    final text = InstanceTheme.of(context).text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        border: Border.all(
          width: 0.5,
          color: Colors.white.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 10,
        children: [
          Icon(Icons.wifi_off, color: text.withValues(alpha: 0.5), size: 28),
          Text(
            l.newsError,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                onPressed: catalog.load,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l.retry,
                    style: TextStyle(
                      color: text,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
