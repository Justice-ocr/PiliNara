# Windows Product Boundary

The Windows branch is a specialized desktop client, not a second copy of the
mobile app. Upstream owns common pages, data loading, account behavior, and
platform-neutral features. This branch owns how those capabilities are hosted
and presented on Windows.

## Windows-Owned Features

- Neo shell, visual tokens, and Windows-specific components in
  `lib/windows_ui/`.
- Workspace tabs, nested navigation, recently closed tabs, split layout,
  keyboard shortcuts, player presentation, and audio policy in
  `lib/windows_workspace/`.
- Windows-only entry adapters in `PageUtils` where an upstream page needs a
  tab or workspace destination.

## Upstream-Owned Features

- API models, controllers, requests, and page business logic.
- Cross-platform content pages and their feature behavior.
- Routes that are not registered for the workspace.

## Decision Rule for New Upstream Features

1. Import the upstream page and business behavior first.
2. If it is reachable from the Windows workspace, classify its route as a
   nested page or tool tab in `WindowsWorkspaceRouteRegistry`.
3. Add or adapt only the Windows entry point and presentation component.
4. Do not fork an upstream page merely to place it in a tab.

An exception requires a documented Windows-specific need: a fundamentally
different interaction model, desktop-only performance constraint, or a visual
component that cannot be expressed as a wrapper. Put such code under
`lib/windows_ui/` or `lib/windows_workspace/`, not in a shared page.

## Review Questions

- Can the change remain in a workspace tab without direct `Get.toNamed`?
- Is the route registered exactly once?
- Are identity, close/restore behavior, and split eligibility covered by a
  focused test?
- Does the change alter Neo styling only through Windows UI components?
