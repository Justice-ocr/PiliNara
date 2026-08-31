import 'package:PiliPlus/windows_workspace/models/windows_workspace_tab.dart';
import 'package:PiliPlus/windows_workspace/split/windows_workspace_split_controller.dart';
import 'package:PiliPlus/windows_workspace/state/windows_workspace_tab_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WindowsWorkspaceTab tab(String id) {
    final now = DateTime(2026);
    return WindowsWorkspaceTab(
      id: id,
      type: WindowsWorkspaceTabType.video,
      arguments: {'bvid': id},
      createdAt: now,
      updatedAt: now,
    );
  }

  WindowsWorkspaceSplitController controller(
    WindowsWorkspaceTabState state, {
    void Function()? onSyncPresentation,
  }) =>
      WindowsWorkspaceSplitController(
        state: state,
        maxSplitTabs: 4,
        onSyncPresentation: onSyncPresentation ?? () {},
        onRememberActive: (_) {},
        onEnsureTabAudible: (id) => state.audibleTabIds.add(id),
        setMuted: (_, _) async {},
      );

  test('caps split selection at four media tabs', () {
    final state = WindowsWorkspaceTabState()
      ..tabs.addAll(['a', 'b', 'c', 'd', 'e'].map(tab))
      ..activeId.value = 'a';
    final split = controller(state);

    split.beginSelection(enabled: true, ensureHomeTab: () {});
    for (final id in ['b', 'c', 'd', 'e']) {
      split.toggleDraft(id);
    }

    expect(state.splitDraftTabIds, unorderedEquals(['a', 'b', 'c', 'd']));
  });

  test('applies a split with a visible active tab and audible fallback', () {
    var syncCount = 0;
    final state = WindowsWorkspaceTabState()
      ..tabs.addAll(['a', 'b', 'outside'].map(tab))
      ..activeId.value = 'outside'
      ..splitDraftTabIds.addAll(['a', 'b']);
    final split = controller(state, onSyncPresentation: () => syncCount++);

    expect(split.applySelection(), isTrue);

    expect(split.isActive, isTrue);
    expect(state.activeId.value, 'a');
    expect(state.audibleTabIds, contains('a'));
    expect(split.shouldSuppressAudio('outside', false), isTrue);
    expect(syncCount, 1);
  });
}
