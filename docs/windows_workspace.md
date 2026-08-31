# Windows Workspace

The Windows workspace keeps media tabs, tool tabs, nested pages, split layout,
and player presentation separate from upstream page implementations.

`WindowsWorkspaceTab` is the one persistent model for every tab. Video, live,
search, member, and tool pages differ only by `WindowsWorkspaceTabType`; they
must not grow separate tab-state or closed-tab models. Runtime-only resources
(nested navigators, player instances, callbacks, and mute state) stay in
`state/windows_workspace_tab_runtime.dart`.

## Route Registration

Add every page that can open inside the Windows workspace to
`lib/windows_workspace/routing/windows_workspace_route_registry.dart`.
Each definition owns the route path, its opening mode, page builder, and the
default title for a tool tab. Do not add the same route to the tab service,
Windows tab page, or `app_pages.dart` manually.

- Use `WindowsWorkspaceRouteKind.toolTab` for persistent tool pages such as
  history, downloads, settings, and subscriptions.
- Use `WindowsWorkspaceRouteKind.nested` for pages that stay in the current
  tab's navigation stack.
- Keep a legacy route alias as a separate definition when it must remain
  compatible with existing links.

## Navigation Rules

Use `PageUtils` from pages that can run in the workspace:

- `toMember` for member pages.
- `toDupNamed` for a registered nested page.
- `openToolTab` or `openWorkspaceTab` for a tool tab.

Do not introduce a direct `Get.toNamed` for a registered workspace route. It
bypasses the active tab navigator and is the most common source of pages that
appear to leave the Windows workspace.

## Module Boundaries

- `models/` contains tab identity, capabilities, root route mapping, and route
  payload data.
- `state/` owns reactive tab state and runtime callbacks.
- `navigation/` owns the nested `Navigator` lifecycle.
- `split/` owns split selection, audio policy, and split geometry state.
- `WindowsVideoTabService` is a compatibility facade for existing callers.
  New behavior belongs in a focused `windows_workspace/` module first, then
  the facade delegates to it.

When upstream changes touch common pages, prefer adding a small PageUtils or
registry adapter over modifying unrelated page navigation directly.

## Tests

Keep route-registry tests synchronized with new workspace entries. Add a unit
test for changes to tab identity, lifecycle, selection, audio, split state, or
route classification. The `Windows Workspace Checks` workflow runs the
focused analysis and unit tests with Flutter from `pubspec.yaml` and native
assets enabled. UI clicks and visual acceptance remain a manual Windows check.

## Manual Windows Acceptance

Run these checks on a packaged Windows build after CI passes:

1. Open settings, history, downloads, subscriptions, and private messages:
   each must open or select one tool tab instead of replacing the workspace.
2. From a workspace page, open search, a member page, and live area/follow
   pages: each registered nested route must stay inside the current tab.
3. Use `Ctrl+Tab` and `Ctrl+Shift+Tab`, including from the first tab; both must
   wrap correctly. Close, pin, restore, close-left, close-right, and
   close-others actions must work for media and tool tabs.
4. Create a two-to-four pane split with video and live tabs. Check focus,
   audio mix, mute, primary audio, remove-from-split, maximize, and divider
   reset.
5. Confirm the Neo shell, horizontal card layout, and responsive sidebar retain
   the intended Windows styling at the target window sizes.
