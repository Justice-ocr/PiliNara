import 'dart:io' show Platform;

import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum WindowsMediaTabType {
  home,
  search,
  video,
  live,
  member,
  dynamic,
  tool,
}

class WindowsTabRouteData {
  const WindowsTabRouteData({
    this.arguments,
    this.parameters = const {},
  });

  final Object? arguments;
  final Map<String, String> parameters;
}

class WindowsVideoTabItem {
  WindowsVideoTabItem({
    required this.id,
    required this.type,
    required this.arguments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final WindowsMediaTabType type;
  final Map<String, dynamic> arguments;
  final DateTime createdAt;
  DateTime updatedAt;

  bool get isHome => type == WindowsMediaTabType.home;
  bool get isHeavyMedia =>
      type == WindowsMediaTabType.video || type == WindowsMediaTabType.live;

  String get title {
    if (isHome) {
      return '主页';
    }
    final value = arguments['title'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (type == WindowsMediaTabType.search) {
      final keyword = arguments['keyword'];
      if (keyword != null && keyword.toString().trim().isNotEmpty) {
        return '\u641c\u7d22: ${keyword.toString().trim()}';
      }
      return '\u641c\u7d22';
    }
    if (type == WindowsMediaTabType.member) {
      final mid = arguments['mid'];
      return mid == null ? '用户空间' : '用户 $mid';
    }
    if (type == WindowsMediaTabType.dynamic) {
      return '动态详情';
    }
    if (type == WindowsMediaTabType.tool) {
      return arguments['title']?.toString() ?? '工具';
    }
    final bvid = arguments['bvid'];
    if (bvid is String && bvid.isNotEmpty) {
      return bvid;
    }
    final aid = arguments['aid'];
    if (aid != null) {
      return 'av$aid';
    }
    final roomId = arguments['roomId'] ?? arguments['id'];
    if (roomId != null) {
      return '直播间 $roomId';
    }
    return type == WindowsMediaTabType.live ? '直播间' : '视频';
  }

  String get subtitle {
    if (isHome) {
      return '';
    }
    final parts = <String>[];
    if (type == WindowsMediaTabType.search) {
      final index = arguments['initIndex'];
      if (index != null) {
        parts.add('tab $index');
      }
      return parts.join(' 路 ');
    }
    if (type == WindowsMediaTabType.live) {
      final roomId = arguments['roomId'] ?? arguments['id'];
      if (roomId != null) {
        parts.add('room $roomId');
      }
      return parts.join(' · ');
    }
    if (type == WindowsMediaTabType.member && arguments['mid'] != null) {
      return 'UID ${arguments['mid']}';
    }
    if (type == WindowsMediaTabType.dynamic &&
        arguments['dynamicId'] != null) {
      return 'ID ${arguments['dynamicId']}';
    }
    if (arguments['bvid'] case final String bvid when bvid.isNotEmpty) {
      parts.add(bvid);
    }
    if (arguments['cid'] case final int cid) {
      parts.add('cid $cid');
    }
    if (arguments['progress'] case final int progress when progress > 0) {
      parts.add(_formatProgress(Duration(milliseconds: progress)));
    }
    return parts.join(' · ');
  }

  static String _formatProgress(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

abstract final class WindowsVideoTabService {
  static final RxList<WindowsVideoTabItem> tabs =
      <WindowsVideoTabItem>[].obs;
  static final RxnString activeId = RxnString();
  static final Map<String, void Function()> _activators = {};
  static final Map<String, void Function()> _closers = {};
  static final Map<String, _WindowsVideoTabPlayer> _players = {};
  static final Map<String, GlobalKey<NavigatorState>> _navigatorKeys = {};
  static final List<String> _activationHistory = [];
  static bool _hostMounted = false;
  static Map? currentArguments;

  static bool get enabled => Platform.isWindows && Pref.enableWindowsVideoTabs;

  static bool get isNotEmpty => tabs.isNotEmpty;

  static const hostRoute = '/windowsMediaTabs';
  static const rootRoute = '/';
  static const homeTabId = 'home';
  static const maxMediaTabs = 8;
  static const nestedRoutes = {
    '/search',
    '/member',
    '/dynamicDetail',
    '/articlePage',
  };

  static WindowsVideoTabItem _homeTab() {
    final now = DateTime.now();
    return WindowsVideoTabItem(
      id: homeTabId,
      type: WindowsMediaTabType.home,
      arguments: const {'mediaTabType': 'home'},
      createdAt: now,
      updatedAt: now,
    );
  }

  static void ensureHomeTab() {
    if (!enabled) return;
    final index = tabs.indexWhere((item) => item.id == homeTabId);
    if (index == -1) {
      tabs.insert(0, _homeTab());
    } else if (index != 0) {
      final item = tabs.removeAt(index);
      tabs.insert(0, item);
    }
    activeId.value ??= homeTabId;
    _rememberActive(activeId.value!);
  }

  static int get tabCount =>
      tabs.where((item) => item.type != WindowsMediaTabType.home).length;

  static int get mediaTabCount =>
      tabs.where((item) => item.isHeavyMedia).length;

  static bool get hasMediaTabs => mediaTabCount > 0;

  static void setHostMounted(bool value) {
    _hostMounted = value;
    if (!value) {
      _navigatorKeys.clear();
    }
  }

  static GlobalKey<NavigatorState> navigatorKeyFor(String id) =>
      _navigatorKeys.putIfAbsent(id, GlobalKey<NavigatorState>.new);

  static void retainNavigatorKeys(Set<String> ids) {
    _navigatorKeys.removeWhere((id, _) => !ids.contains(id));
  }

  static bool navigateInActiveTab(
    String page, {
    Object? arguments,
    Map<String, String>? parameters,
    bool replace = false,
  }) {
    if (!enabled || !_hostMounted || !_isHostCurrent) return false;
    final uri = Uri.tryParse(page);
    if (uri == null || !nestedRoutes.contains(uri.path)) return false;
    final id = activeId.value;
    final navigator = id == null ? null : _navigatorKeys[id]?.currentState;
    if (navigator == null) return false;
    final routeData = WindowsTabRouteData(
      arguments: arguments,
      parameters: {
        ...uri.queryParameters,
        ...?parameters,
      },
    );
    if (replace) {
      navigator.pushReplacementNamed(uri.path, arguments: routeData);
    } else {
      navigator.pushNamed(uri.path, arguments: routeData);
    }
    return true;
  }

  static void popActiveTabToRoot() {
    final id = activeId.value;
    final navigator = id == null ? null : _navigatorKeys[id]?.currentState;
    navigator?.popUntil((route) => route.isFirst);
  }

  static bool popActiveTab() {
    final id = activeId.value;
    final navigator = id == null ? null : _navigatorKeys[id]?.currentState;
    if (navigator?.canPop() != true) return false;
    navigator!.pop();
    return true;
  }

  static void closeActiveTab() {
    final id = activeId.value;
    if (id != null && id != homeTabId) {
      close(id);
    }
  }

  static void selectRelative(int offset) {
    if (tabs.length < 2) return;
    final current = tabs.indexWhere((item) => item.id == activeId.value);
    final start = current == -1 ? 0 : current;
    final next = (start + offset) % tabs.length;
    select(tabs[next].id);
  }

  static bool get _isHostCurrent =>
      Get.currentRoute == hostRoute || Get.currentRoute == rootRoute;

  static bool _isHostRoute(Route<dynamic> route) {
    final name = route.settings.name;
    return route.isFirst || name == hostRoute || name == rootRoute;
  }

  static String keyFromArgs(Map arguments) {
    final type = _typeFromArgs(arguments);
    if (type == WindowsMediaTabType.home) {
      return homeTabId;
    }
    if (type == WindowsMediaTabType.live) {
      final roomId =
          arguments['roomId']?.toString() ?? arguments['id']?.toString();
      return roomId == null || roomId.isEmpty ? '' : 'live:$roomId';
    }
    if (type == WindowsMediaTabType.search) {
      final keyword = arguments['keyword']?.toString();
      return keyword == null || keyword.isEmpty ? '' : 'search:$keyword';
    }
    if (type == WindowsMediaTabType.member) {
      final mid = arguments['mid']?.toString();
      return mid == null || mid.isEmpty ? '' : 'member:$mid';
    }
    if (type == WindowsMediaTabType.dynamic) {
      final dynamicId = arguments['dynamicId']?.toString();
      return dynamicId == null || dynamicId.isEmpty
          ? ''
          : 'dynamic:$dynamicId';
    }
    if (type == WindowsMediaTabType.tool) {
      final route = arguments['tabRoute']?.toString();
      return route == null || route.isEmpty ? '' : 'tool:$route';
    }
    final bvid = arguments['bvid']?.toString();
    final cid = arguments['cid']?.toString();
    final epId = arguments['epId']?.toString();
    final seasonId = arguments['seasonId']?.toString();
    final key = [bvid, cid, epId, seasonId]
        .where((item) => item != null && item.isNotEmpty)
        .join(':');
    return key.isEmpty ? '' : 'video:$key';
  }

  static WindowsMediaTabType _typeFromArgs(Map arguments) {
    final type = arguments['mediaTabType'];
    if (type == WindowsMediaTabType.home || type == 'home') {
      return WindowsMediaTabType.home;
    }
    if (type == WindowsMediaTabType.live || type == 'live') {
      return WindowsMediaTabType.live;
    }
    if (type == WindowsMediaTabType.search || type == 'search') {
      return WindowsMediaTabType.search;
    }
    if (type == WindowsMediaTabType.member || type == 'member') {
      return WindowsMediaTabType.member;
    }
    if (type == WindowsMediaTabType.dynamic || type == 'dynamic') {
      return WindowsMediaTabType.dynamic;
    }
    if (type == WindowsMediaTabType.tool || type == 'tool') {
      return WindowsMediaTabType.tool;
    }
    return WindowsMediaTabType.video;
  }

  static void upsert(
    Map arguments, {
    WindowsMediaTabType type = WindowsMediaTabType.video,
    bool activate = true,
  }) {
    if (!enabled) return;
    ensureHomeTab();
    final normalized = Map<String, dynamic>.from(arguments)
      ..['mediaTabType'] = type.name;
    final id = keyFromArgs(normalized);
    if (id.isEmpty) return;

    final index = tabs.indexWhere((item) => item.id == id);
    if (index == -1) {
      final now = DateTime.now();
      tabs.add(
        WindowsVideoTabItem(
          id: id,
          type: type,
          arguments: normalized,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      final tab = tabs[index];
      final previousTitle = tab.arguments['title'];
      tab.arguments
        ..clear()
        ..addAll(normalized);
      if (!tab.arguments.containsKey('title') && previousTitle != null) {
        tab.arguments['title'] = previousTitle;
      }
      tab.updatedAt = DateTime.now();
      tabs.refresh();
    }
    if (activate) {
      activeId.value = id;
      currentArguments = normalized;
      _rememberActive(id);
    }
    if (type == WindowsMediaTabType.video ||
        type == WindowsMediaTabType.live) {
      _trimMediaTabs(keepId: id);
    }
  }

  static void updateProgress(Map arguments, Duration? progress) {
    if (!enabled || progress == null) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    final index = tabs.indexWhere((item) => item.id == id);
    if (index == -1) return;
    tabs[index].arguments['progress'] = progress.inMilliseconds;
    tabs[index].updatedAt = DateTime.now();
    tabs.refresh();
  }

  static bool has(String id) => tabs.any((item) => item.id == id);

  static void setActive(Map arguments) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    final index = tabs.indexWhere((item) => item.id == id);
    if (id.isNotEmpty && index != -1) {
      activeId.value = id;
      currentArguments = tabs[index].isHome ? null : tabs[index].arguments;
      _rememberActive(id);
    }
  }

  static Future<void>? openTab(
    Map arguments, {
    required WindowsMediaTabType type,
    bool off = false,
  }) {
    upsert(arguments, type: type);
    return showHost(off: off);
  }

  static void updateTitle(String id, String? title) {
    if (title == null || title.trim().isEmpty) return;
    final index = tabs.indexWhere((item) => item.id == id);
    if (index == -1) return;
    tabs[index].arguments['title'] = title.trim();
    tabs[index].updatedAt = DateTime.now();
    tabs.refresh();
  }

  static void _rememberActive(String id) {
    _activationHistory
      ..remove(id)
      ..add(id);
  }

  static void _trimMediaTabs({required String keepId}) {
    while (mediaTabCount > maxMediaTabs) {
      final active = activeId.value;
      final candidates = tabs
          .where(
            (item) =>
                item.isHeavyMedia &&
                item.id != keepId &&
                item.id != active,
          )
          .toList(growable: false);
      final fallback = tabs
          .where((item) => item.isHeavyMedia && item.id != keepId)
          .toList(growable: false);
      final removable = candidates.isNotEmpty ? candidates : fallback;
      if (removable.isEmpty) return;
      removable.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      close(removable.first.id);
    }
  }

  static void close(String id) {
    if (id == homeTabId) return;
    final close = _closers.remove(id);
    _activators.remove(id);
    _players.remove(id)?.dispose();
    _navigatorKeys.remove(id);
    _activationHistory.remove(id);
    tabs.removeWhere((item) => item.id == id);
    if (activeId.value == id) {
      final nextId = _activationHistory.reversed.firstWhere(
        has,
        orElse: () => homeTabId,
      );
      activeId.value = null;
      ensureHomeTab();
      select(nextId);
    }
    if (!_hostMounted && Get.currentRoute != hostRoute) {
      close?.call();
    }
  }

  static void clear() {
    final closers = List<void Function()>.from(
      _closers.entries
          .where((entry) => entry.key != homeTabId)
          .map((entry) => entry.value),
    );
    _closers.clear();
    _activators.clear();
    for (final close in closers) {
      close();
    }
    for (final cached in _players.values) {
      cached.dispose();
    }
    _players.clear();
    _navigatorKeys.removeWhere((id, _) => id != homeTabId);
    _activationHistory
      ..clear()
      ..add(homeTabId);
    tabs
      ..clear()
      ..add(_homeTab());
    activeId.value = homeTabId;
    currentArguments = null;
  }

  static T? takePlayer<T extends Object>(Map arguments) {
    final id = keyFromArgs(arguments);
    final cached = _players.remove(id);
    if (cached == null) return null;
    if (cached.player case final T player) {
      return player;
    }
    cached.dispose();
    return null;
  }

  static void keepPlayer<T extends Object>(
    Map arguments,
    T player, {
    required void Function(T player) dispose,
  }) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty || !has(id)) return;
    _players[id] = _WindowsVideoTabPlayer(
      player,
      (player) => dispose(player as T),
    );
  }

  static T? removePlayer<T extends Object>(Map arguments) {
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return null;
    final cached = _players.remove(id);
    if (cached == null) return null;
    if (cached.player case final T player) {
      return player;
    }
    cached.dispose();
    return null;
  }

  static void registerRoute(
    Map arguments, {
    required void Function() activate,
    required void Function() close,
  }) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    _activators[id] = activate;
    _closers[id] = close;
  }

  static void unregisterRoute(Map arguments, void Function() close) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    if (identical(_closers[id], close)) {
      _closers.remove(id);
      _activators.remove(id);
    }
  }

  static Future<void>? open(WindowsVideoTabItem item) {
    if (!enabled) return null;
    select(item.id);
    if (_hostMounted) {
      if (!_isHostCurrent) {
        Get.until(_isHostRoute);
      }
      return null;
    }
    if (!_isHostCurrent) {
      return Get.toNamed(hostRoute, preventDuplicates: true);
    }
    return null;
  }

  static void select(String id) {
    if (!enabled) return;
    ensureHomeTab();
    final index = tabs.indexWhere((item) => item.id == id);
    if (index != -1) {
      activeId.value = id;
      currentArguments = tabs[index].isHome ? null : tabs[index].arguments;
      _rememberActive(id);
      _activators[id]?.call();
    }
  }

  static Future<void>? showHost({bool off = false}) {
    if (!enabled) {
      return null;
    }
    ensureHomeTab();
    if (_hostMounted) {
      if (!_isHostCurrent) {
        Get.until(_isHostRoute);
      }
      return null;
    }
    if (_isHostCurrent) {
      return null;
    }
    if (off) {
      return Get.offNamed(hostRoute);
    }
    return Get.toNamed(hostRoute, preventDuplicates: true);
  }

}

class WindowsMediaTabBar extends StatelessWidget {
  const WindowsMediaTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    if (!WindowsVideoTabService.enabled) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    return Obx(() {
      final tabs = WindowsVideoTabService.tabs;
      if (tabs.isEmpty) {
        return const SizedBox.shrink();
      }
      final activeId = WindowsVideoTabService.activeId.value;
      return Material(
        color: theme.colorScheme.surface,
        elevation: 1,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              itemBuilder: (context, index) {
                final item = tabs[index];
                final active = activeId == item.id;
                return _WindowsMediaTabChip(item: item, active: active);
              },
              separatorBuilder: (_, _) => const SizedBox(width: 6),
              itemCount: tabs.length,
            ),
          ),
        ),
      );
    });
  }
}

class _WindowsMediaTabChip extends StatelessWidget {
  const _WindowsMediaTabChip({
    required this.item,
    required this.active,
  });

  final WindowsVideoTabItem item;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bg = active ? colors.primaryContainer : colors.surfaceContainerHighest;
    final fg = active ? colors.onPrimaryContainer : colors.onSurfaceVariant;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 132, maxWidth: 260),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: active ? null : () => WindowsVideoTabService.select(item.id),
          child: Padding(
            padding: const EdgeInsets.only(left: 10, right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_iconForItem(item), size: 17, color: fg),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: fg),
                  ),
                ),
                if (!item.isHome)
                  SizedBox(
                    width: 28,
                    height: 28,
                    child: IconButton(
                      tooltip: '关闭标签',
                      padding: EdgeInsets.zero,
                      iconSize: 16,
                      color: fg,
                      onPressed: () => WindowsVideoTabService.close(item.id),
                      icon: const Icon(Icons.close),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _iconForItem(WindowsVideoTabItem item) {
    return switch (item.type) {
      WindowsMediaTabType.home => Icons.home_outlined,
      WindowsMediaTabType.search => Icons.search,
      WindowsMediaTabType.live => Icons.sensors,
      WindowsMediaTabType.video => Icons.play_circle_outline,
      WindowsMediaTabType.member => Icons.person_outline,
      WindowsMediaTabType.dynamic => Icons.motion_photos_on_outlined,
      WindowsMediaTabType.tool => switch (item.arguments['tabRoute']) {
        '/setting' => Icons.settings_outlined,
        '/download' => Icons.download_outlined,
        '/whisper' => Icons.chat_bubble_outline,
        _ => Icons.apps_outlined,
      },
    };
  }
}

class _WindowsVideoTabPlayer {
  const _WindowsVideoTabPlayer(this.player, this._dispose);

  final Object player;
  final void Function(Object player) _dispose;

  void dispose() => _dispose(player);
}
