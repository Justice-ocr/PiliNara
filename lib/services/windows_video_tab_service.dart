import 'dart:io' show Platform;

import 'package:PiliPlus/services/windows_back_navigation_policy.dart';
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
    if (type == WindowsMediaTabType.dynamic && arguments['dynamicId'] != null) {
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
  static final RxList<WindowsVideoTabItem> tabs = <WindowsVideoTabItem>[].obs;
  static final RxnString activeId = RxnString();
  static final RxSet<String> splitTabIds = <String>{}.obs;
  static final RxSet<String> audibleTabIds = <String>{}.obs;
  static final RxSet<String> splitDraftTabIds = <String>{}.obs;
  static final RxBool splitSelectionMode = false.obs;
  static final RxnString maximizedSplitTabId = RxnString();
  static final RxDouble splitHorizontalRatio = 0.5.obs;
  static final RxDouble splitVerticalRatio = 0.5.obs;
  static final Map<String, void Function()> _activators = {};
  static final Map<String, void Function()> _deactivators = {};
  static final Map<String, void Function(bool visible, bool focused)>
  _presenters = {};
  static final Map<String, RxBool> _muteStates = {};
  static final Map<String, Future<void> Function(bool muted)> _muteSetters =
      {};
  static final Map<String, void Function()> _closers = {};
  static final Map<String, List<bool Function()>> _contextPoppers = {};
  static final Map<String, _WindowsVideoTabPlayer> _players = {};
  static final Map<String, GlobalKey<NavigatorState>> _navigatorKeys = {};
  static final List<String> _activationHistory = [];
  static final List<WindowsVideoTabItem> _closedTabs = [];
  static bool _hostMounted = false;
  static Map? currentArguments;

  @visibleForTesting
  static bool? enabledOverride;

  static bool get enabled =>
      enabledOverride ?? (Platform.isWindows && Pref.enableWindowsVideoTabs);

  static bool get isNotEmpty => tabs.isNotEmpty;

  static const hostRoute = '/windowsMediaTabs';
  static const rootRoute = '/';
  static const homeTabId = 'home';
  static const maxMediaTabs = 8;
  static const maxSplitTabs = 4;
  static const maxClosedTabs = 12;
  static const workspaceRoutes = {
    '/download',
    '/fav',
    '/history',
    '/later',
    '/myReply',
    '/setting',
    '/subscription',
    '/whisper',
  };
  static const nestedRoutes = {
    '/search',
    '/searchTrending',
    '/member',
    '/memberSearch',
    '/editProfile',
    '/spaceSetting',
    '/dynamicDetail',
    '/articlePage',
    '/articleList',
    '/dynTopic',
    '/blockSetting',
    '/blackListPage',
    '/sponsorBlock',
    '/aiSetting',
    '/playSpeedSet',
    '/colorSetting',
    '/fontSizeSetting',
    '/barSetting',
    '/historySearch',
    '/laterSearch',
    '/favDetail',
    '/favSearch',
    '/popularSeries',
    '/popularPrecious',
    '/rank',
    '/whisperDetail',
    '/replyMe',
    '/atMe',
    '/likeMe',
    '/sysMsg',
    '/webview',
    '/subDetail',
    '/msgLikeDetail',
    '/memberDynamics',
    '/follow',
    '/fan',
    '/followSearch',
    '/followed',
    '/sameFollowing',
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

  static List<WindowsVideoTabItem> get recentlyClosedTabs =>
      List<WindowsVideoTabItem>.unmodifiable(_closedTabs);

  static bool get hasMediaTabs => mediaTabCount > 0;

  static bool get isSplitActive => splitTabs.length >= 2;

  static String? get maximizedSplitTab => maximizedSplitTabId.value;

  static bool get isSplitMaximized =>
      isSplitActive &&
      maximizedSplitTabId.value != null &&
      splitTabIds.contains(maximizedSplitTabId.value);

  static bool get canApplySplitSelection =>
      splitDraftTabIds.length >= 2 && splitDraftTabIds.length <= maxSplitTabs;

  static List<WindowsVideoTabItem> get splitTabs => tabs
      .where((item) => splitTabIds.contains(item.id))
      .toList(growable: false);

  static bool isSplitTab(String id) => splitTabIds.contains(id);

  static bool isSplitAudioEnabled(String id) => audibleTabIds.contains(id);

  static bool shouldSuppressTabAudio(String id, bool focused) =>
      isSplitActive ? !audibleTabIds.contains(id) : !focused;

  static RxBool? muteStateFor(String id) => _muteStates[id];

  static bool isVisibleTab(String id) =>
      isSplitActive ? splitTabIds.contains(id) : activeId.value == id;

  static bool isSplitCandidate(WindowsVideoTabItem item) => item.isHeavyMedia;

  static void beginSplitSelection() {
    if (!enabled) return;
    ensureHomeTab();
    splitDraftTabIds
      ..clear()
      ..addAll(
        isSplitActive
            ? splitTabIds
            : activeId.value != null &&
                    tabs.any(
                      (item) =>
                          item.id == activeId.value && item.isHeavyMedia,
                    )
                ? <String>{activeId.value!}
                : <String>{},
      );
    splitDraftTabIds.refresh();
    splitSelectionMode.value = true;
  }

  static void toggleSplitDraft(String id) {
    if (!splitSelectionMode.value) return;
    WindowsVideoTabItem? item;
    for (final candidate in tabs) {
      if (candidate.id == id) {
        item = candidate;
        break;
      }
    }
    if (item == null || !item.isHeavyMedia) return;
    if (splitDraftTabIds.contains(id)) {
      splitDraftTabIds.remove(id);
    } else if (splitDraftTabIds.length < maxSplitTabs) {
      splitDraftTabIds.add(id);
    }
    splitDraftTabIds.refresh();
  }

  static void cancelSplitSelection() {
    splitSelectionMode.value = false;
    splitDraftTabIds.clear();
    splitDraftTabIds.refresh();
  }

  static bool applySplitSelection() {
    if (!canApplySplitSelection) return false;
    final previousAudible = Set<String>.from(audibleTabIds);
    splitTabIds
      ..clear()
      ..addAll(splitDraftTabIds);
    splitTabIds.refresh();
    maximizedSplitTabId.value = null;
    splitSelectionMode.value = false;
    splitDraftTabIds.clear();
    splitDraftTabIds.refresh();
    if (!splitTabIds.contains(activeId.value)) {
      activeId.value = splitTabIds.first;
      currentArguments = tabs
          .firstWhere((item) => item.id == activeId.value)
          .arguments;
      _rememberActive(activeId.value!);
    }
    audibleTabIds
      ..clear()
      ..addAll(previousAudible.intersection(splitTabIds));
    if (audibleTabIds.isEmpty && activeId.value case final activeIdValue?) {
      audibleTabIds.add(activeIdValue);
    }
    audibleTabIds.refresh();
    _syncPresentation();
    return true;
  }

  static void exitSplit() {
    splitTabIds.clear();
    audibleTabIds.clear();
    splitTabIds.refresh();
    audibleTabIds.refresh();
    maximizedSplitTabId.value = null;
    splitSelectionMode.value = false;
    splitDraftTabIds.clear();
    splitDraftTabIds.refresh();
    _syncPresentation();
  }

  static void focusSplitTab(String id) {
    if (!isSplitActive || !splitTabIds.contains(id)) {
      select(id);
      return;
    }
    if (activeId.value == id) return;
    activeId.value = id;
    currentArguments = tabs.firstWhere((item) => item.id == id).arguments;
    _rememberActive(id);
    _syncPresentation();
  }

  static Future<void> setSplitTabMuted(String id, bool muted) async {
    final setter = _muteSetters[id];
    if (setter == null) return;
    await setter(muted);
  }

  static Future<void> setSplitTabAudioEnabled(
    String id,
    bool enabled,
  ) async {
    if (!isSplitActive || !splitTabIds.contains(id)) return;
    if (enabled) {
      audibleTabIds.add(id);
    } else {
      audibleTabIds.remove(id);
    }
    if (audibleTabIds.isEmpty && activeId.value case final activeIdValue?) {
      audibleTabIds.add(activeIdValue);
    }
    audibleTabIds.refresh();
    _syncPresentation();
  }

  static Future<void> setSplitPrimaryAudio(String id) async {
    if (!isSplitActive || !splitTabIds.contains(id)) return;
    focusSplitTab(id);
    audibleTabIds.add(id);
    audibleTabIds.refresh();
    await setSplitTabMuted(id, false);
    _syncPresentation();
  }

  static void toggleSplitMaximized(String id) {
    if (!isSplitActive || !splitTabIds.contains(id)) return;
    focusSplitTab(id);
    maximizedSplitTabId.value = maximizedSplitTabId.value == id ? null : id;
  }

  static void setSplitHorizontalRatio(double ratio) {
    splitHorizontalRatio.value = ratio.clamp(0.15, 0.85);
  }

  static void setSplitVerticalRatio(double ratio) {
    splitVerticalRatio.value = ratio.clamp(0.15, 0.85);
  }

  static void resetSplitBounds() {
    splitHorizontalRatio.value = 0.5;
    splitVerticalRatio.value = 0.5;
  }

  static void removeFromSplit(String id) {
    if (!isSplitActive || !splitTabIds.contains(id)) return;
    final wasFocused = activeId.value == id;
    splitTabIds.remove(id);
    splitTabIds.refresh();
    if (maximizedSplitTabId.value == id) {
      maximizedSplitTabId.value = null;
    }
    if (!isSplitActive) {
      exitSplit();
      return;
    }
    if (wasFocused) {
      final next = splitTabs.first;
      activeId.value = next.id;
      currentArguments = next.arguments;
      _rememberActive(next.id);
    }
    _syncPresentation();
  }

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

  static Future<T?>? pushNamedInActiveTab<T extends Object?>(
    String page, {
    Object? arguments,
    Map<String, String>? parameters,
    bool replace = false,
  }) {
    if (!enabled || !_hostMounted || !_isHostCurrent) return null;
    final uri = Uri.tryParse(page);
    if (uri == null || !nestedRoutes.contains(uri.path)) return null;
    final id = activeId.value;
    final navigator = id == null ? null : _navigatorKeys[id]?.currentState;
    if (navigator == null) return null;
    final routeData = WindowsTabRouteData(
      arguments: arguments,
      parameters: {
        ...uri.queryParameters,
        ...?parameters,
      },
    );
    if (replace) {
      return navigator.pushReplacementNamed<T, Object?>(
        uri.path,
        arguments: routeData,
      );
    }
    return navigator.pushNamed<T>(uri.path, arguments: routeData);
  }

  static bool navigateInActiveTab(
    String page, {
    Object? arguments,
    Map<String, String>? parameters,
    bool replace = false,
  }) =>
      pushNamedInActiveTab<void>(
        page,
        arguments: arguments,
        parameters: parameters,
        replace: replace,
      ) !=
      null;

  static void popActiveTabToRoot() {
    final id = activeId.value;
    final navigator = id == null ? null : _navigatorKeys[id]?.currentState;
    navigator?.popUntil((route) => route.isFirst);
  }

  static bool popActiveTab() {
    final id = activeId.value;
    final contextPoppers = id == null ? null : _contextPoppers[id];
    final navigator = id == null ? null : _navigatorKeys[id]?.currentState;
    return WindowsBackNavigationPolicy.dispatch(
      popContext: () {
        if (contextPoppers == null) return false;
        for (final popper in contextPoppers.reversed) {
          if (popper()) return true;
        }
        return false;
      },
      popPage: () {
        if (navigator?.canPop() != true) return false;
        navigator!.pop();
        return true;
      },
    );
  }

  static void closeActiveTab() {
    final id = activeId.value;
    if (id != null && id != homeTabId) {
      close(id);
    }
  }

  static bool get canRestoreClosedTab => _closedTabs.isNotEmpty;

  static bool isPinned(String id) {
    final index = tabs.indexWhere((item) => item.id == id);
    return index != -1 && tabs[index].arguments['pinned'] == true;
  }

  static void togglePinned(String id) {
    final index = tabs.indexWhere((item) => item.id == id);
    if (index == -1 || tabs[index].isHome) return;
    final tab = tabs[index];
    tab.arguments['pinned'] = tab.arguments['pinned'] != true;
    tab.updatedAt = DateTime.now();
    tabs.refresh();
  }

  static bool restoreLastClosedTab() {
    if (_closedTabs.isEmpty) return false;
    return _restoreClosedTab(_closedTabs.removeLast());
  }

  static bool restoreClosedTab(String id) {
    final index = _closedTabs.lastIndexWhere((tab) => tab.id == id);
    if (index == -1) return false;
    return _restoreClosedTab(_closedTabs.removeAt(index));
  }

  static bool _restoreClosedTab(WindowsVideoTabItem tab) {
    if (has(tab.id)) {
      select(tab.id);
      return true;
    }
    final now = DateTime.now();
    tabs.add(
      WindowsVideoTabItem(
        id: tab.id,
        type: tab.type,
        arguments: Map<String, dynamic>.from(tab.arguments),
        createdAt: tab.createdAt,
        updatedAt: now,
      ),
    );
    select(tab.id);
    return true;
  }

  static void closeOthers(String id) {
    final ids = tabs
        .where((tab) => !tab.isHome && tab.id != id && !isPinned(tab.id))
        .map((tab) => tab.id)
        .toList(growable: false);
    for (final tabId in ids) {
      close(tabId);
    }
    select(id);
  }

  static void closeTabsToLeft(String id) => _closeRelativeTabs(id, left: true);

  static void closeTabsToRight(String id) =>
      _closeRelativeTabs(id, left: false);

  static void _closeRelativeTabs(String id, {required bool left}) {
    final target = tabs.indexWhere((tab) => tab.id == id);
    if (target == -1) return;
    final ids = tabs
        .asMap()
        .entries
        .where(
          (entry) =>
              !entry.value.isHome &&
              !isPinned(entry.value.id) &&
              (left ? entry.key < target : entry.key > target),
        )
        .map((entry) => entry.value.id)
        .toList(growable: false);
    for (final tabId in ids) {
      close(tabId);
    }
    select(id);
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
      return dynamicId == null || dynamicId.isEmpty ? '' : 'dynamic:$dynamicId';
    }
    if (type == WindowsMediaTabType.tool) {
      final route = arguments['tabRoute']?.toString();
      return route == null || route.isEmpty ? '' : 'tool:$route';
    }
    final bvid = arguments['bvid']?.toString();
    final cid = arguments['cid']?.toString();
    final epId = arguments['epId']?.toString();
    final seasonId = arguments['seasonId']?.toString();
    final key = [
      bvid,
      cid,
      epId,
      seasonId,
    ].where((item) => item != null && item.isNotEmpty).join(':');
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
      final wasPinned = tab.arguments['pinned'] == true;
      tab.arguments
        ..clear()
        ..addAll(normalized);
      if (!tab.arguments.containsKey('title') && previousTitle != null) {
        tab.arguments['title'] = previousTitle;
      }
      if (wasPinned) tab.arguments['pinned'] = true;
      tab.updatedAt = DateTime.now();
      tabs.refresh();
    }
    if (activate) {
      if (isSplitActive && !splitTabIds.contains(id)) {
        exitSplit();
      }
      activeId.value = id;
      currentArguments = normalized;
      _rememberActive(id);
      _syncPresentation();
    }
    if (type == WindowsMediaTabType.video || type == WindowsMediaTabType.live) {
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
      if (isSplitActive && !splitTabIds.contains(id)) {
        exitSplit();
      }
      activeId.value = id;
      currentArguments = tabs[index].isHome ? null : tabs[index].arguments;
      _rememberActive(id);
      _syncPresentation();
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
                item.isHeavyMedia && item.id != keepId && item.id != active,
          )
          .toList(growable: false);
      final fallback = tabs
          .where((item) => item.isHeavyMedia && item.id != keepId)
          .toList(growable: false);
      final removable = candidates.isNotEmpty ? candidates : fallback;
      if (removable.isEmpty) return;
      removable.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      close(removable.first.id, remember: false);
    }
  }

  static void close(String id, {bool remember = true}) {
    if (id == homeTabId) return;
    final index = tabs.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final closingTab = tabs[index];
    final closingFocusedTab = activeId.value == id;
    final closingSplitTab = splitTabIds.contains(id);
    if (remember) {
      _closedTabs
        ..removeWhere((item) => item.id == id)
        ..add(
          WindowsVideoTabItem(
            id: closingTab.id,
            type: closingTab.type,
            arguments: Map<String, dynamic>.from(closingTab.arguments),
            createdAt: closingTab.createdAt,
            updatedAt: closingTab.updatedAt,
          ),
        );
      if (_closedTabs.length > maxClosedTabs) {
        _closedTabs.removeAt(0);
      }
    }
    final deactivate = _deactivators.remove(id);
    if (closingFocusedTab) {
      deactivate?.call();
    }
    final close = _closers.remove(id);
    _activators.remove(id);
    _presenters.remove(id);
    _muteStates.remove(id);
    _muteSetters.remove(id);
    _contextPoppers.remove(id);
    _players.remove(id)?.dispose();
    _navigatorKeys.remove(id);
    _activationHistory.remove(id);
    tabs.removeWhere((item) => item.id == id);
    splitTabIds.remove(id);
    audibleTabIds.remove(id);
    splitDraftTabIds.remove(id);
    if (maximizedSplitTabId.value == id) {
      maximizedSplitTabId.value = null;
    }
    if (splitTabIds.length < 2) {
      splitTabIds.clear();
    }
    splitTabIds.refresh();
    audibleTabIds.refresh();
    splitDraftTabIds.refresh();
    if (closingFocusedTab) {
      final nextId = closingSplitTab && isSplitActive
          ? splitTabIds.first
          : _activationHistory.reversed.firstWhere(
              has,
              orElse: () => homeTabId,
            );
      activeId.value = null;
      ensureHomeTab();
      select(nextId);
    } else {
      _syncPresentation();
    }
    if (isSplitActive && audibleTabIds.isEmpty) {
      final fallbackAudioId = activeId.value;
      if (fallbackAudioId != null && splitTabIds.contains(fallbackAudioId)) {
        audibleTabIds.add(fallbackAudioId);
        audibleTabIds.refresh();
        _syncPresentation();
      }
    }
    if (!_hostMounted && Get.currentRoute != hostRoute) {
      close?.call();
    }
  }

  static void clear() {
    _deactivateCurrent();
    final closers = List<void Function()>.from(
      _closers.entries
          .where((entry) => entry.key != homeTabId)
          .map((entry) => entry.value),
    );
    _closers.clear();
    _activators.clear();
    _deactivators.clear();
    _presenters.clear();
    _muteStates.clear();
    _muteSetters.clear();
    _contextPoppers.clear();
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
    _closedTabs.clear();
    splitTabIds.clear();
    audibleTabIds.clear();
    splitDraftTabIds.clear();
    splitSelectionMode.value = false;
    maximizedSplitTabId.value = null;
    audibleTabIds.refresh();
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
    required void Function() deactivate,
    required void Function() close,
    void Function(bool visible, bool focused)? present,
    RxBool? muteState,
    Future<void> Function(bool muted)? setMuted,
  }) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    _activators[id] = activate;
    _deactivators[id] = deactivate;
    _closers[id] = close;
    if (present != null) {
      _presenters[id] = present;
    }
    if (muteState != null) {
      _muteStates[id] = muteState;
    }
    if (setMuted != null) {
      _muteSetters[id] = setMuted;
    }
    _syncPresentation();
  }

  static void unregisterRoute(Map arguments, void Function() close) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    if (identical(_closers[id], close)) {
      _closers.remove(id);
      _activators.remove(id);
      _deactivators.remove(id);
      _presenters.remove(id);
      _muteStates.remove(id);
      _muteSetters.remove(id);
    }
  }

  static void registerContextPopper(
    Map arguments,
    bool Function() popContext,
  ) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    _contextPoppers.putIfAbsent(id, () => []).add(popContext);
  }

  static void unregisterContextPopper(
    Map arguments,
    bool Function() popContext,
  ) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    final poppers = _contextPoppers[id];
    poppers?.removeWhere((entry) => identical(entry, popContext));
    if (poppers?.isEmpty == true) _contextPoppers.remove(id);
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
      if (isSplitActive && !splitTabIds.contains(id)) {
        exitSplit();
      }
      activeId.value = id;
      currentArguments = tabs[index].isHome ? null : tabs[index].arguments;
      _rememberActive(id);
      _syncPresentation();
    }
  }

  static void _deactivateCurrent({String? exceptId}) {
    final current = activeId.value;
    if (current == null || current == exceptId) return;
    _deactivators[current]?.call();
  }

  static void _syncPresentation() {
    final focused = activeId.value;
    final visibleIds = isSplitActive
        ? splitTabIds
        : (focused == null ? <String>{} : <String>{focused});
    for (final item in tabs) {
      final id = item.id;
      final visible = visibleIds.contains(id);
      final isFocused = id == focused;
      final presenter = _presenters[id];
      if (presenter != null) {
        presenter(visible, isFocused);
      } else if (isFocused) {
        _activators[id]?.call();
      } else if (!visible) {
        _deactivators[id]?.call();
      }
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

class _WindowsVideoTabPlayer {
  const _WindowsVideoTabPlayer(this.player, this._dispose);

  final Object player;
  final void Function(Object player) _dispose;

  void dispose() => _dispose(player);
}
