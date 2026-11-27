import 'dart:ui' show FontFeature;

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models_new/search/search_trending/data.dart';
import 'package:PiliPlus/models_new/search/search_trending/list.dart';
import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_media_meta.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

/// Shared local search-history store synced with [BaseSearchController] so
/// searches triggered from the floating command palette or trending board
/// seamlessly appear in and update the history list.
abstract final class WindowsNeoSearchHistoryStore {
  static List<String> load() {
    try {
      final raw = GStorage.historyWord.get('cacheList');
      if (raw is List) {
        return raw.whereType<String>().where((e) => e.trim().isNotEmpty).toList();
      }
    } catch (_) {}
    return <String>[];
  }

  static void record(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    bool shouldRecord = true;
    try {
      shouldRecord = Pref.recordSearchHistory;
    } catch (_) {}
    if (!shouldRecord) return;

    final list = load();
    list.remove(trimmed);
    list.insert(0, trimmed);
    if (list.length > 40) {
      list.removeRange(40, list.length);
    }
    _save(list);
  }

  static void remove(String keyword) {
    final list = load();
    if (list.remove(keyword)) {
      _save(list);
    }
  }

  static void clear() {
    try {
      GStorage.historyWord.delete('cacheList');
    } catch (_) {}
    if (Get.isRegistered<BaseSearchController>()) {
      Get.find<BaseSearchController>().historyList.clear();
    }
  }

  static void _save(List<String> list) {
    try {
      GStorage.historyWord.put('cacheList', list);
    } catch (_) {}
    if (Get.isRegistered<BaseSearchController>()) {
      Get.find<BaseSearchController>().historyList.assignAll(list);
    }
  }
}

/// Short-lived memory cache for real-time trending data so reopening `Ctrl+K`
/// feels instantaneous while still allowing manual refresh.
abstract final class WindowsNeoTrendingCache {
  static SearchTrendingData? _cached;
  static DateTime? _fetchedAt;
  static const _ttl = Duration(minutes: 2);

  static SearchTrendingData? get validData {
    final data = _cached;
    final at = _fetchedAt;
    if (data == null || at == null) return null;
    if (DateTime.now().difference(at) > _ttl) return null;
    return data;
  }

  static Future<LoadingState<SearchTrendingData>> fetch({
    int limit = 16,
    bool force = false,
  }) async {
    if (!force) {
      final cached = validData;
      if (cached != null) return Success(cached);
    }
    final res = await SearchHttp.searchTrending(limit: limit, needsTop: true);
    if (res case Success(:final response)) {
      _cached = response;
      _fetchedAt = DateTime.now();
    }
    return res;
  }
}

/// Pure native vector rank indicator for Windows Neo trending boards (replaces
/// italic web/mobile numerals with crisp tabular desktop typography).
class WindowsNeoTrendingRank extends StatelessWidget {
  const WindowsNeoTrendingRank({
    super.key,
    required this.rank,
    this.isPinned = false,
    this.fontSize = 13,
    this.width = 24,
  });

  /// 1-based rank index for non-pinned items.
  final int rank;
  final bool isPinned;
  final double fontSize;
  final double width;

  static Color colorForRank(int rank, WindowsNeoTokens tokens) => switch (rank) {
    1 => const Color(0xFFFF5A5F),
    2 => const Color(0xFFF59E0B),
    3 => tokens.accentInk,
    _ => tokens.muted,
  };

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    if (isPinned) {
      return SizedBox(
        width: width,
        child: Icon(
          Icons.vertical_align_top_rounded,
          size: fontSize + 2,
          color: const Color(0xFFFF5A5F),
        ),
      );
    }
    final color = colorForRank(rank, tokens);
    return SizedBox(
      width: width,
      child: Text(
        rank.toString().padLeft(2, '0'),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: rank <= 3 ? FontWeight.w900 : FontWeight.w700,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
          fontFamilyFallback: tokens.displayFontFallback,
          height: 1,
        ),
      ),
    );
  }
}

/// Pure native vector status tag for trending keywords — replaces Bilibili's
/// low-DPI web PNG icons and mobile live banners with sharp Windows Neo badges.
class WindowsNeoTrendingTag extends StatelessWidget {
  const WindowsNeoTrendingTag({
    super.key,
    required this.item,
    this.isPinned = false,
  });

  final SearchTrendingItemModel item;
  final bool isPinned;

  static (String label, Color color, bool filled)? _resolve(
    SearchTrendingItemModel item,
    bool isPinned,
    WindowsNeoTokens tokens,
  ) {
    if (isPinned) {
      return ('置顶', const Color(0xFFFF5A5F), true);
    }
    if (item.showLiveIcon == true) {
      return ('直播', const Color(0xFFFB7299), true);
    }
    final reason = item.recommendReason?.trim();
    if (reason != null && reason.isNotEmpty) {
      return (reason, tokens.accentInk, false);
    }
    final iconUrl = item.icon?.toLowerCase();
    if (iconUrl != null && iconUrl.isNotEmpty) {
      if (iconUrl.contains('bao') ||
          iconUrl.contains('boom') ||
          iconUrl.contains('explode')) {
        return ('爆', const Color(0xFFE11D48), true);
      }
      if (iconUrl.contains('new')) {
        return ('新', tokens.accentInk, false);
      }
      if (iconUrl.contains('geng') || iconUrl.contains('meme')) {
        return ('梗', const Color(0xFF8B5CF6), false);
      }
      if (iconUrl.contains('live')) {
        return ('直播', const Color(0xFFFB7299), true);
      }
      if (iconUrl.contains('exclus') || iconUrl.contains('first')) {
        return ('独家', const Color(0xFFF59E0B), false);
      }
      return ('热', const Color(0xFFFF6B35), false);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final resolved = _resolve(item, isPinned, tokens);
    if (resolved == null) return const SizedBox.shrink();
    final (label, color, filled) = resolved;

    if (label.length > 2) {
      return WindowsNeoTag(
        text: label,
        tone: WindowsNeoTagTone.neutral,
        fontSize: 10,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: filled
            ? color.withValues(alpha: tokens.isDarkSurface ? 0.24 : 0.14)
            : color.withValues(alpha: tokens.isDarkSurface ? 0.16 : 0.10),
        borderRadius: tokens.mediaBadgeRadius,
        border: Border.all(
          color: color.withValues(alpha: filled ? 0.55 : 0.38),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: tokens.isDarkSurface ? color : color,
          height: 1.1,
        ),
      ),
    );
  }
}
