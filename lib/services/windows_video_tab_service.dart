import 'dart:io' show Platform;

export 'package:PiliPlus/windows_workspace/models/windows_workspace_tab.dart';

import 'package:PiliPlus/services/windows_back_navigation_policy.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/windows_workspace/models/windows_workspace_tab.dart';
import 'package:PiliPlus/windows_workspace/navigation/windows_workspace_tab_navigator.dart';
import 'package:PiliPlus/windows_workspace/routing/windows_workspace_route_registry.dart';
import 'package:PiliPlus/windows_workspace/split/windows_workspace_split_controller.dart';
import 'package:PiliPlus/windows_workspace/state/windows_workspace_tab_runtime.dart';
import 'package:PiliPlus/windows_workspace/state/windows_workspace_tab_state.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';

abstract final class WindowsVideoTabService {
  static const hostRoute = '/windowsMediaTabs';
  static const rootRoute = '/';
  static const homeTabId = 'home';
  static const maxMediaTabs = 8;
  static const maxSplitTabs = 4;
  static const maxClosedTabs = 12;

  static final WindowsWorkspaceTabState _state = WindowsWorkspaceTabState();
  static final WindowsWorkspaceTabRuntime _runtime =
      WindowsWorkspaceTabRuntime();
  static final WindowsWorkspaceTabNavigator _navigator =
      WindowsWorkspaceTabNavigator(_runtime);
  static final WindowsWorkspaceSplitController _splitController =
      WindowsWorkspaceSplitController(
    state: _state,
    maxSplitTabs: maxSplitTabs,
    onSyncPresentation: _syncPresentation,
    onRememberActive: _rememberActive,
    onEnsureTabAudible: _ensureTabAudible,
    setMuted: (id, muted) async {
      final setter = _muteSetters[id];
      if (setter != null) {
        await setter(muted);
      }
    },
  );

  static final RxList<WindowsWorkspaceTab> tabs = _state.tabs;
  static final RxnString activeId = _state.activeId;
  static final RxSet<String> splitTabIds = _state.splitTabIds;
  static final RxSet<String> audibleTabIds = _state.audibleTabIds;
  static final RxSet<String> splitDraftTabIds = _state.splitDraftTabIds;
  static final RxBool splitSelectionMode = _state.splitSelectionMode;
  static final RxnString maximizedSplitTabId = _state.maximizedSplitTabId;
  static final RxDouble splitHorizontalRatio = _state.splitHorizontalRatio;
  static final RxDouble splitVerticalRatio = _state.splitVerticalRatio;
  static final Map<String, void Function()> _activators = _runtime.activators;
  static final Map<String, void Function()> _deactivators =
      _runtime.deactivators;
  static final Map<String, void Function(bool visible, bool focused)>
      _presenters = _runtime.presenters;
  static final Map<String, RxBool> _muteStates = _runtime.muteStates;
  static final Map<String, Future<void> Function(bool muted)> _muteSetters =
      _runtime.muteSetters;
  static final Map<String, void Function()> _closers = _runtime.closers;
  static final Map<String, List<bool Function()>> _contextPoppers =
      _runtime.contextPoppers;
  static final Map<String, WindowsWorkspaceCachedPlayer> _players =
      _runtime.players;
  static final Map<String, GlobalKey<NavigatorState>> _navigatorKeys =
      _runtime.navigatorKeys;
  static final List<String> _activationHistory = _state.activationHistory;
  static final List<WindowsWorkspaceTab> _closedTabs = _state.closedTabs;

  static bool get _hostMounted => _runtime.hostMounted;
  static set _hostMounted(bool value) => _runtime.hostMounted = value;

  static Map? get currentArguments => _state.currentArguments;
  static set currentArguments(Map? value) => _state.currentArguments = value;

  @visibleForTesting
  static bool? enabledOverride;

  static bool get enabled =>
      enabledOverride ?? (Platform.isWindows && Pref.enableWindowsVideoTabs);

  static bool get isNotEmpty => tabs.isNotEmpty;

  static final Set<String> workspaceRoutes =
      WindowsWorkspaceRouteRegistry.toolTabPaths;
  static final Set<String> nestedRoutes =
      WindowsWorkspaceRouteRegistry.nestedPaths;

  static WindowsWorkspaceTab _homeTab() {
    final now = DateTime.now();
    return WindowsWorkspaceTab(
      id: homeTabId,
      type: WindowsWorkspaceTabType.home,
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

  static int get tabCount => tabs.where((item) => !item.isHome).length;

  static int get mediaTabCount => tabs.where((item) => item.canSplit).length;

  static List<WindowsWorkspaceTab> get recentlyClosedTabs =>
      List<WindowsWorkspaceTab>.unmodifiable(_closedTabs);

  static bool get hasMediaTabs => mediaTabCount > 0;

  static bool get isSplitActive => _splitController.isActive;

  static String? get maximizedSplitTab => _splitController.maximizedTabId;

  static bool get isSplitMaximized => _splitController.isMaximized;

  static bool get canApplySplitSelection => _splitController.canApplySelection;

  static List<WindowsWorkspaceTab> get splitTabs => _splitController.splitTabs;

  static bool isSplitTab(String id) => _splitController.isSplitTab(id);

  static bool isSplitAudioEnabled(String id) =>
      _splitController.isAudioEnabled(id);

  static bool isTabAudioEnabled(String id) =>
      _splitController.isAudioEnabled(id);

  static bool shouldSuppressTabAudio(String id, bool focused) =>
      _splitController.shouldSuppressAudio(id, focused);

  static RxBool? muteStateFor(String id) => _muteStates[id];

  static bool isVisibleTab(String id) => _splitController.isVisible(id);

  static bool isSplitCandidate(WindowsWorkspaceTab item) => item.canSplit;

  static void beginSplitSelection() {
    _splitController.beginSelection(
      enabled: enabled,
      ensureHomeTab: ensureHomeTab,
    );
  }

  static void toggleSplitDraft(String id) => _splitController.toggleDraft(id);

  static void cancelSplitSelection() => _splitController.cancelSelection();

  static bool applySplitSelection() => _splitController.applySelection();

  static void exitSplit() => _splitController.exit();

  static void focusSplitTab(String id) =>
      _splitController.focusTab(id, selectTab: select);

  static Future<void> setSplitTabMuted(String id, bool muted) =>
      _splitController.setMuted(id, muted);

  static Future<void> setSplitTabAudioEnabled(
    String id,
    bool enabled,
  ) =>
      _splitController.setSplitTabAudioEnabled(id, enabled);

  static Future<void> setTabAudioEnabled(
    String id,
    bool enabled,
  ) =>
      _splitController.setTabAudioEnabled(id, enabled);

  static Future<void> setSplitPrimaryAudio(String id) =>
      _splitController.setPrimaryAudio(id, selectTab: select);

  static void toggleSplitMaximized(String id) =>
      _splitController.toggleMaximized(id, selectTab: select);

  static void setSplitHorizontalRatio(double ratio) =>
      _splitController.setHorizontalRatio(ratio);

  static void setSplitVerticalRatio(double ratio) =>
      _splitController.setVerticalRatio(ratio);

  static void resetSplitBounds() => _splitController.resetBounds();

  static void removeFromSplit(String id) => _splitController.removeTab(id);

  static void setHostMounted(bool value) {
    _navigator.setHostMounted(value);
  }

  static GlobalKey<NavigatorState> navigatorKeyFor(String id) =>
      _navigator.navigatorKeyFor(id);

  static void retainNavigatorKeys(Set<String> ids) {
    _navigator.retainNavigatorKeys(ids);
  }

  static Future<T?>? pushNamedInActiveTab<T extends Object?>(
    String page, {
    Object? arguments,
    Map<String, String>? parameters,
    bool replace = false,
  }) {
    return _navigator.pushNamedInActiveTab<T>(
      page,
      enabled: enabled,
      isHostCurrent: _isHostCurrent,
      activeTabId: activeId.value,
      nestedRoutes: nestedRoutes,
      arguments: arguments,
      parameters: parameters,
      replace: replace,
    );
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
    _navigator.popToRoot(activeId.value);
  }

  static bool popActiveTab() {
    final id = activeId.value;
    final contextPoppers = id == null ? null : _contextPoppers[id];
    return WindowsBackNavigationPolicy.dispatch(
      popContext: () {
        if (contextPoppers == null) return false;
        for (final popper in contextPoppers.reversed) {
          if (popper()) return true;
        }
        return false;
      },
      popPage: () => _navigator.popPage(id),
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
    if (index == -1 || !tabs[index].canPin) return;
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

  static bool _restoreClosedTab(WindowsWorkspaceTab tab) {
    if (has(tab.id)) {
      select(tab.id);
      return true;
    }
    final now = DateTime.now();
    tabs.add(tab.copyForRestore(restoredAt: now));
    select(tab.id);
    return true;
  }

  static void closeOthers(String id) {
    final ids = tabs
        .where((tab) => tab.canClose && tab.id != id && !isPinned(tab.id))
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
              entry.value.canClose &&
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
    final next = ((start + offset) % tabs.length + tabs.length) % tabs.length;
    select(tabs[next].id);
  }

  static bool get _isHostCurrent =>
      Get.currentRoute == hostRoute || Get.currentRoute == rootRoute;

  static bool _isHostRoute(Route<dynamic> route) {
    final name = route.settings.name;
    return route.isFirst || name == hostRoute || name == rootRoute;
  }

  static String keyFromArgs(Map arguments) =>
      WindowsWorkspaceTabIdentity.keyFromArguments(arguments);

  static void upsert(
    Map arguments, {
    WindowsWorkspaceTabType type = WindowsWorkspaceTabType.video,
    bool activate = true,
  }) {
    if (!enabled) return;
    ensureHomeTab();
    final normalized = WindowsWorkspaceTabIdentity.normalizeArguments(
      arguments,
      type,
    );
    final id = keyFromArgs(normalized);
    if (id.isEmpty) return;

    final index = tabs.indexWhere((item) => item.id == id);
    if (index == -1) {
      final now = DateTime.now();
      tabs.add(
        WindowsWorkspaceTab(
          id: id,
          type: type,
          arguments: normalized,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      tabs[index].replaceArguments(normalized);
      tabs.refresh();
    }
    if (activate) {
      if (isSplitActive && !splitTabIds.contains(id)) {
        exitSplit();
      }
      activeId.value = id;
      currentArguments = normalized;
      if (!isSplitActive) _ensureTabAudible(id);
      _rememberActive(id);
      _syncPresentation();
    }
    if (tabs.any((item) => item.id == id && item.canSplit)) {
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
      if (!isSplitActive) _ensureTabAudible(id);
      _rememberActive(id);
      _syncPresentation();
    }
  }

  static Future<void>? openTab(
    Map arguments, {
    required WindowsWorkspaceTabType type,
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
            (item) => item.canSplit && item.id != keepId && item.id != active,
          )
          .toList(growable: false);
      final fallback = tabs
          .where((item) => item.canSplit && item.id != keepId)
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
        ..add(closingTab.copyForRestore());
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
    _players[id] = WindowsWorkspaceCachedPlayer(
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

  static Future<void>? open(WindowsWorkspaceTab item) {
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
      if (!isSplitActive) _ensureTabAudible(id);
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

  static bool _supportsTabAudio(String id) =>
      tabs.any((item) => item.id == id && item.supportsAudio);

  static void _ensureTabAudible(String id) {
    if (!_supportsTabAudio(id)) return;
    if (audibleTabIds.add(id)) audibleTabIds.refresh();
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
