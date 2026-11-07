import 'package:bc_launcher/models/news.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:bc_launcher/services/news_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

News news(String id) => News(
  id: id,
  title: id,
  body: '',
  pinned: false,
  publishedAt: DateTime.utc(2026, 11, 1),
);

void main() {
  test(
    'loads page after page with the cursor until there are no more',
    () async {
      final cursors = <String?>[];
      final catalog = NewsCatalog((cursor) async {
        cursors.add(cursor);
        return cursor == null
            ? (items: [news('a'), news('b')], nextCursor: 'c2')
            : (items: [news('c')], nextCursor: null);
      });

      expect(catalog.hasMore, isTrue);
      await catalog.load();
      expect(catalog.items.map((n) => n.id), ['a', 'b']);
      expect(catalog.hasMore, isTrue);

      await catalog.load();
      expect(catalog.items.map((n) => n.id), ['a', 'b', 'c']);
      expect(catalog.hasMore, isFalse);

      await catalog.load();
      expect(cursors, [null, 'c2']);
    },
  );

  test('a load while another is running does nothing', () async {
    var calls = 0;
    final catalog = NewsCatalog((cursor) async {
      calls++;
      return (items: [news('a')], nextCursor: null);
    });

    await Future.wait([catalog.load(), catalog.load()]);
    expect(calls, 1);
  });

  test('an error is kept until the next load, which retries', () async {
    var fail = true;
    final catalog = NewsCatalog((cursor) async {
      if (fail) throw const ApiError(ApiErrorType.offline);
      return (items: [news('a')], nextCursor: null);
    });

    await catalog.load();
    expect(catalog.error, isA<ApiError>());
    expect(catalog.items, isEmpty);
    expect(catalog.hasMore, isTrue);

    fail = false;
    await catalog.load();
    expect(catalog.error, isNull);
    expect(catalog.items.map((n) => n.id), ['a']);
  });

  test('an invalid cursor starts again from the first page', () async {
    final cursors = <String?>[];
    final catalog = NewsCatalog((cursor) async {
      cursors.add(cursor);
      if (cursor == 'old') {
        throw const ApiError(
          ApiErrorType.other,
          code: 'invalid_cursor',
          status: 400,
        );
      }
      return cursors.length == 1
          ? (items: [news('a')], nextCursor: 'old')
          : (items: [news('a'), news('b')], nextCursor: null);
    });

    await catalog.load();
    await catalog.load();
    expect(cursors, [null, 'old', null]);
    expect(catalog.items.map((n) => n.id), ['a', 'b']);
    expect(catalog.error, isNull);
  });
}
