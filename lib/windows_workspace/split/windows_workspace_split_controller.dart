import 'package:PiliPlus/windows_workspace/models/windows_workspace_tab.dart';
import 'package:PiliPlus/windows_workspace/state/windows_workspace_tab_state.dart';

class WindowsWorkspaceSplitController {
  WindowsWorkspaceSplitController({
    required WindowsWorkspaceTabState state,
    required this.maxSplitTabs,
    required this.onSyncPresentation,
    required this.onRememberActive,
    required this.onEnsureTabAudible,
    required this.setMuted,
  }) : _state = state;

  final WindowsWorkspaceTabState _state;
  final int maxSplitTabs;
  final void Function() onSyncPresentation;
  final void Function(String id) onRememberActive;
  final void Function(String id) onEnsureTabAudible;
  final Future<void> Function(String id, bool muted) setMuted;

  bool get isActive => _state.splitTabIds.length >= 2;

  String? get maximizedTabId => _state.maximizedSplitTabId.value;

  bool get isMaximized =>
      isActive &&
      maximizedTabId != null &&
      _state.splitTabIds.contains(maximizedTabId);

  bool get canApplySelection =>
      _state.splitDraftTabIds.length >= 2 &&
      _state.splitDraftTabIds.length <= maxSplitTabs;

  List<WindowsWorkspaceTab> get splitTabs => _state.tabs
      .where((item) => _state.splitTabIds.contains(item.id))
      .toList(growable: false);

  bool isSplitTab(String id) => _state.splitTabIds.contains(id);

  bool isAudioEnabled(String id) => _state.audibleTabIds.contains(id);

  bool shouldSuppressAudio(String id, bool focused) {
    if (isActive && !_state.splitTabIds.contains(id)) return true;
    if (_state.audibleTabIds.isEmpty && focused && !isActive) return false;
    return !_state.audibleTabIds.contains(id);
  }

  bool isVisible(String id) =>
      isActive ? _state.splitTabIds.contains(id) : _state.activeId.value == id;

  void beginSelection({
    required bool enabled,
    required void Function() ensureHomeTab,
  }) {
    if (!enabled) return;
    ensureHomeTab();
    _state.splitDraftTabIds
      ..clear()
      ..addAll(
        isActive
            ? _state.splitTabIds
            : _state.activeId.value != null &&
                    _state.tabs.any(
                      (item) =>
                          item.id == _state.activeId.value && item.canSplit,
                    )
                ? <String>{_state.activeId.value!}
                : <String>{},
      );
    _state.splitDraftTabIds.refresh();
    _state.splitSelectionMode.value = true;
  }

  void toggleDraft(String id) {
    if (!_state.splitSelectionMode.value) return;
    WindowsWorkspaceTab? item;
    for (final candidate in _state.tabs) {
      if (candidate.id == id) {
        item = candidate;
        break;
      }
    }
    if (item == null || !item.canSplit) return;
    if (_state.splitDraftTabIds.contains(id)) {
      _state.splitDraftTabIds.remove(id);
    } else if (_state.splitDraftTabIds.length < maxSplitTabs) {
      _state.splitDraftTabIds.add(id);
    }
    _state.splitDraftTabIds.refresh();
  }

  void cancelSelection() {
    _state.splitSelectionMode.value = false;
    _state.splitDraftTabIds.clear();
    _state.splitDraftTabIds.refresh();
  }

  bool applySelection() {
    if (!canApplySelection) return false;
    final previousAudible = Set<String>.from(_state.audibleTabIds);
    _state.splitTabIds
      ..clear()
      ..addAll(_state.splitDraftTabIds);
    _state.splitTabIds.refresh();
    _state.maximizedSplitTabId.value = null;
    _state.splitSelectionMode.value = false;
    _state.splitDraftTabIds.clear();
    _state.splitDraftTabIds.refresh();
    if (!_state.splitTabIds.contains(_state.activeId.value)) {
      _state.activeId.value = _state.splitTabIds.first;
      _state.currentArguments = _state.tabs
          .firstWhere((item) => item.id == _state.activeId.value)
          .arguments;
      onRememberActive(_state.activeId.value!);
    }
    _state.audibleTabIds
      ..clear()
      ..addAll(previousAudible);
    if (_state.audibleTabIds.intersection(_state.splitTabIds).isEmpty) {
      final activeId = _state.activeId.value;
      if (activeId != null && _state.splitTabIds.contains(activeId)) {
        _state.audibleTabIds.add(activeId);
      }
    }
    _state.audibleTabIds.refresh();
    onSyncPresentation();
    return true;
  }

  void exit() {
    _state.splitTabIds.clear();
    _state.splitTabIds.refresh();
    _state.audibleTabIds.refresh();
    _state.maximizedSplitTabId.value = null;
    _state.splitSelectionMode.value = false;
    _state.splitDraftTabIds.clear();
    _state.splitDraftTabIds.refresh();
    final activeId = _state.activeId.value;
    if (_state.audibleTabIds.isEmpty && activeId != null) {
      onEnsureTabAudible(activeId);
    }
    onSyncPresentation();
  }

  void focusTab(String id, {required void Function(String id) selectTab}) {
    if (!isActive || !_state.splitTabIds.contains(id)) {
      selectTab(id);
      return;
    }
    if (_state.activeId.value == id) return;
    _state.activeId.value = id;
    _state.currentArguments =
        _state.tabs.firstWhere((item) => item.id == id).arguments;
    onRememberActive(id);
    onSyncPresentation();
  }

  Future<void> setTabAudioEnabled(String id, bool enabled) async {
    if (!_supportsAudio(id)) return;
    if (enabled) {
      _state.audibleTabIds.add(id);
    } else {
      _state.audibleTabIds.remove(id);
    }
    final hasAudibleSplitTab =
        isActive && _state.audibleTabIds.any(_state.splitTabIds.contains);
    if ((!isActive && _state.audibleTabIds.isEmpty) ||
        (isActive && !hasAudibleSplitTab)) {
      final activeId = _state.activeId.value;
      if (activeId != null &&
          (!isActive || _state.splitTabIds.contains(activeId))) {
        _state.audibleTabIds.add(activeId);
      }
    }
    _state.audibleTabIds.refresh();
    onSyncPresentation();
  }

  Future<void> setSplitTabAudioEnabled(String id, bool enabled) async {
    if (!isActive || !_state.splitTabIds.contains(id)) return;
    await setTabAudioEnabled(id, enabled);
  }

  Future<void> setPrimaryAudio(
    String id, {
    required void Function(String id) selectTab,
  }) async {
    if (!isActive || !_state.splitTabIds.contains(id)) return;
    focusTab(id, selectTab: selectTab);
    _state.audibleTabIds.add(id);
    _state.audibleTabIds.refresh();
    await setMuted(id, false);
    onSyncPresentation();
  }

  void toggleMaximized(String id,
      {required void Function(String id) selectTab}) {
    if (!isActive || !_state.splitTabIds.contains(id)) return;
    focusTab(id, selectTab: selectTab);
    _state.maximizedSplitTabId.value =
        _state.maximizedSplitTabId.value == id ? null : id;
  }

  void setHorizontalRatio(double ratio) {
    _state.splitHorizontalRatio.value = ratio.clamp(0.15, 0.85);
  }

  void setVerticalRatio(double ratio) {
    _state.splitVerticalRatio.value = ratio.clamp(0.15, 0.85);
  }

  void resetBounds() {
    _state.splitHorizontalRatio.value = 0.5;
    _state.splitVerticalRatio.value = 0.5;
  }

  void removeTab(String id) {
    if (!isActive || !_state.splitTabIds.contains(id)) return;
    final wasFocused = _state.activeId.value == id;
    _state.splitTabIds.remove(id);
    _state.splitTabIds.refresh();
    if (_state.maximizedSplitTabId.value == id) {
      _state.maximizedSplitTabId.value = null;
    }
    if (!isActive) {
      exit();
      return;
    }
    if (wasFocused) {
      final next = splitTabs.first;
      _state.activeId.value = next.id;
      _state.currentArguments = next.arguments;
      onRememberActive(next.id);
    }
    onSyncPresentation();
  }

  bool _supportsAudio(String id) =>
      _state.tabs.any((item) => item.id == id && item.supportsAudio);
}
