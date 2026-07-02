import 'package:PiliPlus/http/user.dart';
import 'package:PiliPlus/models/model_video.dart';
import 'package:PiliPlus/utils/recommend_filter.dart';

abstract final class VideoTagFilter {
  static final Map<String, List<String>> _tagCache = {};
  static final Map<String, Future<List<String>>> _pendingRequests = {};

  static Future<List<T>> filterItems<T extends BaseVideoItemModel>(
    Iterable<T> items,
  ) async {
    if (!RecommendFilter.enableVideoTagFilter) {
      return items.toList();
    }

    final source = items.toList();
    if (source.isEmpty) {
      return source;
    }

    final shouldRemove = await Future.wait(source.map(_shouldRemove));
    final list = <T>[];
    for (var i = 0; i < source.length; i++) {
      if (!shouldRemove[i]) {
        list.add(source[i]);
      }
    }
    return list;
  }

  static Future<bool> _shouldRemove(BaseVideoItemModel item) async {
    final bvid = item.bvid;
    if (bvid == null || bvid.isEmpty) {
      return false;
    }

    final tags = await _getTags(bvid, item.cid);
    return RecommendFilter.filterVideoTags(tags);
  }

  static Future<List<String>> _getTags(String bvid, Object? cid) {
    final cached = _tagCache[bvid];
    if (cached != null) {
      return Future.value(cached);
    }

    return _pendingRequests.putIfAbsent(bvid, () async {
      try {
        final res = await UserHttp.videoTags(bvid: bvid, cid: cid);
        final tags = res.dataOrNull
                ?.map((e) => e.tagName?.trim())
                .whereType<String>()
                .where((e) => e.isNotEmpty)
                .toList() ??
            <String>[];
        _tagCache[bvid] = tags;
        return tags;
      } finally {
        _pendingRequests.remove(bvid);
      }
    });
  }
}
