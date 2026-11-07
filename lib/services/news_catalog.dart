import 'package:bc_launcher/models/news.dart';
import 'package:bc_launcher/services/api_client.dart';
import 'package:flutter/foundation.dart';

typedef NewsPage = ({List<News> items, String? nextCursor});

/// An instance's news, loaded a page (20) at a time: pinned first, then the
/// newest.
class NewsCatalog extends ChangeNotifier {
  final Future<NewsPage> Function(String? cursor) _fetch;

  NewsCatalog(this._fetch);

  NewsCatalog.forInstance(ApiClient api, String instanceId)
    : this((cursor) => api.news(instanceId, cursor: cursor));

  final List<News> items = [];

  String? _cursor;
  bool _started = false;
  bool _disposed = false;

  bool loading = false;

  /// Why the last page couldn't be loaded; cleared by the next [load].
  Object? error;

  /// Whether there are pages left to [load], the first one included.
  bool get hasMore => !_started || _cursor != null;

  /// Loads the next page, unless one is loading or there are no more. An
  /// invalid cursor starts again from the first page.
  Future<void> load() async {
    if (loading || !hasMore) return;
    loading = true;
    error = null;
    _notify();

    try {
      final page = await _fetch(_cursor);
      items.addAll(page.items);
      _cursor = page.nextCursor;
      _started = true;
    } on ApiError catch (e) {
      if (e.code == 'invalid_cursor' && _cursor != null) {
        items.clear();
        _cursor = null;
        _started = false;
        loading = false;
        return load();
      }
      error = e;
    } catch (e) {
      error = e;
    }
    loading = false;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
