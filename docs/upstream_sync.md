# Upstream Sync Policy

This repository has two different responsibilities. `main` is the integration
branch for upstream changes and shared PiliNara behavior. The Windows Neo
branch owns the Windows workspace and its visual identity. Keeping those
responsibilities separate is what makes future upstream updates reviewable.

## Branch Flow

```text
upstream/main -> main -> feat/windows-eui-neo
```

- Do not merge `upstream/main` directly into `feat/windows-eui-neo`.
- Sync `main` first, review and validate shared behavior there, then merge
  `main` into the Windows branch in a separate pull request or commit series.
- Keep Windows-specific changes in small commits with an explicit scope, such
  as `feat(windows-workspace)` or `style(windows-neo)`. Do not bury them in an
  upstream sync commit.

## Sync Checklist

For every upstream sync, create a short note in the pull request description
or commit body with these three groups:

1. **Inherited**: changes accepted unchanged because they are shared behavior.
2. **Adapted**: changes integrated through `PageUtils`, the route registry, or
   a Windows UI adapter.
3. **Deferred**: changes intentionally not exposed on Windows, with a reason
   and a follow-up issue if one is needed.

Resolve conflicts in this order:

1. Preserve upstream page business logic and data models.
2. Restore the Windows boundary through `lib/windows_workspace/` or
   `lib/windows_ui/` rather than modifying upstream pages broadly.
3. Add the affected route to the registry and focused tests when it can appear
   inside the workspace.

## Required Checks

Before merging a Windows sync:

```powershell
flutter config --enable-native-assets
flutter pub get
flutter test test/windows_video_tab_service_test.dart test/windows_workspace_split_controller_test.dart test/windows_media_tab_stack_test.dart test/windows_neo_shell_test.dart
```

The GitHub `Windows Workspace Checks` workflow enforces the focused check.
The full Windows package workflow remains the build gate. Visual interaction
checks are manual and should be performed on a Windows build before release.

## Product Boundaries

See `docs/windows_product_boundary.md` before deciding whether an upstream
change should become a Windows-only adapter or a shared feature.
