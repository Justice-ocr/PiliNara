param(
    [string]$platform = ""
)

git config --global user.name "ci"
git config --global user.email "example@example.com"

# TODO: remove
# https://github.com/flutter/flutter/issues/182281
$NewOverScrollIndicator = "362b1de29974ffc1ed6faa826e1df870d7bec75f";

# set `gestureSettings`
$BottomSheetAndroidPatch = "lib/scripts/bottom_sheet_android.patch"

# https://github.com/bggRGjQaUbCoE/PiliPlus/issues/1906
$BottomSheetIOSFlutterPatch = "lib/scripts/bottom_sheet_ios_flutter.patch"
$BottomSheetIOSPiliPlusPatch = "lib/scripts/bottom_sheet_ios_piliplus.patch"

# https://github.com/bggRGjQaUbCoE/PiliPlus/issues/1662
# handle bottom scroll event
$ScrollViewPatch = "lib/scripts/scroll_view.patch"

# https://github.com/bggRGjQaUbCoE/PiliPlus/issues/2106
# use `TouchGestureRecognizer` on all platforms
$TextSelectionPatch = "lib/scripts/text_selection.patch"

# https://github.com/bggRGjQaUbCoE/PiliPlus/issues/1947
$NavigatorPatch = "lib/scripts/navigator.patch"

# fix predictive back direction after popping a nested route
# (route below mounts the transition with a null back event during another
#  route's gesture; direction tween is never recomputed on later gestures)
$PredictiveBackPatch = "lib/scripts/predictive_back_page_transitions_builder.patch"

# https://github.com/bggRGjQaUbCoE/PiliPlus/issues/2107
$ImageAnimPatch = "lib/scripts/image_anim.patch"

# remove `_scheduleRebuild`
$LayoutBuilderPatch = "lib/scripts/layout_builder.patch"

# https://github.com/bggRGjQaUbCoE/PiliPlus/issues/2308
$NavigationDrawerPatch = "lib/scripts/navigation_drawer.patch"

# apply text color to icon color
$PopupMenuPatch = "lib/scripts/popup_menu.patch"

# remove `Hero` effect
$FABPatch = "lib/scripts/fab.patch"

# https://github.com/flutter/flutter/issues/139890
# https://github.com/flutter/flutter/issues/174689
# separator support
# clamp handle offset
# widgetspan selection support
# clear selection when tapping outside
# free selection if there is only one text
# clamp dragging selection behavior on Android
# show selection menu if secondary tap position is in text region on desktop
$SelectableRegionPatch = "lib/scripts/selectable_region.patch"

# https://github.com/flutter/flutter/issues/132047
# https://github.com/flutter/flutter/issues/174689
$EditableTextPatch = "lib/scripts/editable_text.patch"

# set `selectAllOnFocus` to `false` by default
$TextFieldPatch = "lib/scripts/text_field.patch"

# notify `userScrollDirection` only if position is actually changing
$ScrollPositionPatch = "lib/scripts/scroll_position.patch"

# expose `_shouldIgnorePointer`
$ScrollablePatch = "lib/scripts/scrollable.patch"

# expose
$ScaffoldPatch = "lib/scripts/scaffold.patch"

# fix nested scrollable gesture
# custom `HorizontalDragGestureRecognizer` support
$ScrollableGesturePatch = "lib/scripts/scrollable_gesture.patch"

# expose
$DraggableScrollableSheetPatch = "lib/scripts/draggable_scrollable_sheet.patch"

# expose
$TextPatch = "lib/scripts/text.patch"

# expose
$TextPainterPatch = "lib/scripts/text_painter.patch"

$SliverPatch = "lib/scripts/sliver.patch"

$RefreshIndicatorPatch = "lib/scripts/refresh_indicator.patch"

# TODO: remove
# https://github.com/flutter/flutter/issues/124078
# https://github.com/flutter/flutter/pull/183261
$NullSafetySelectableRegionPatch = "lib/scripts/null_safety_for_selectable_region.patch"

# TODO: remove
# https://github.com/flutter/flutter/issues/90223
$ModalBarrierPatch = "lib/scripts/modal_barrier.patch"

# TODO: remove
# https://github.com/flutter/flutter/issues/182466
$MouseCursorPatch = "lib/scripts/mouse_cursor.patch"

$GeetestIOSPatch = "lib/scripts/geetest_ios.patch"

if ($platform.ToLower() -eq "ios") {
    git apply $BottomSheetIOSPiliPlusPatch
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$BottomSheetIOSPiliPlusPatch applied"
    } else {
        throw "$LASTEXITCODE"
    }
    git apply $GeetestIOSPatch
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$GeetestIOSPatch applied"
    } else {
        throw "$LASTEXITCODE"
    }
}

Set-Location $env:FLUTTER_ROOT

$picks   = @()
$reverts = @()
$patches = @($PopupMenuPatch, $ModalBarrierPatch, $SelectableRegionPatch,
            $TextSelectionPatch, $MouseCursorPatch, $ImageAnimPatch,
            $LayoutBuilderPatch, $NavigationDrawerPatch,
            $FABPatch,
            $NullSafetySelectableRegionPatch, $EditableTextPatch, $TextFieldPatch,
            $ScrollPositionPatch, $ScrollablePatch, $ScrollableGesturePatch,
            $DraggableScrollableSheetPatch, $ScaffoldPatch, $TextPatch,
            $TextPainterPatch, $SliverPatch, $RefreshIndicatorPatch)

switch ($platform.ToLower()) {
    "android" {
        $patches += $BottomSheetAndroidPatch
        $patches += $ScrollViewPatch
        $patches += $NavigatorPatch
        $patches += $PredictiveBackPatch

        # Flutter is cached between CI runs; discard previously applied source patches.
        git reset --hard HEAD
        git clean -fd
    }
    "ios" {
        $patches += $ScrollViewPatch
        $patches += $BottomSheetIOSFlutterPatch
        $patches += $NavigatorPatch
    }
    "linux" {
        git reset --hard HEAD
    }
    "macos" {
    }
    "windows" {
    }
    default {}
}

foreach ($pick in $picks) {
    git stash
    git cherry-pick $pick --no-edit
    if ($LASTEXITCODE -eq 0) {
        git reset --soft HEAD~1
        Write-Host "$pick picked"
    } else {
        throw "$LASTEXITCODE"
    }
    git stash pop
}

foreach ($revert in $reverts) {
    git stash
    git revert $revert --no-edit
    if ($LASTEXITCODE -eq 0) {
        git reset --soft HEAD~1
        Write-Host "$revert reverted"
    } else {
        throw "$LASTEXITCODE"
    }
    git stash pop
}

function Test-PatchAlreadyApplied([string]$PatchPath) {
    git apply --reverse --check "$env:GITHUB_WORKSPACE/$PatchPath" 2>$null
    return $LASTEXITCODE -eq 0
}

foreach ($patch in $patches) {
    git apply "$env:GITHUB_WORKSPACE/$patch"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$patch applied"
    } elseif (Test-PatchAlreadyApplied $patch) {
        Write-Host "$patch already applied"
    } elseif ($patch -eq $PopupMenuPatch -or $patch -eq $ModalBarrierPatch -or $patch -eq $FABPatch -or $patch -eq $NullSafetySelectableRegionPatch) {
        Write-Warning "$patch is not applicable to this Flutter stable revision; continuing without optional patch"
    } else {
        throw "$LASTEXITCODE"
    }
}

Set-Location $env:GITHUB_WORKSPACE

$BottomSheetAndroidPatchMaterial = "lib/scripts/material/bottom_sheet_android.patch"

$BottomSheetIOSFlutterMaterialPatchMaterial = "lib/scripts/material/bottom_sheet_ios_flutter_material.patch"

$ModalBarrierPatchMaterial = "lib/scripts/material/modal_barrier_material.patch"

$NavigationDrawerPatchMaterial = "lib/scripts/material/navigation_drawer.patch"

$PopupMenuPatchMaterial = "lib/scripts/material/popup_menu.patch"

$FABPatchMaterial = "lib/scripts/material/fab.patch"

$TextFieldPatchMaterial = "lib/scripts/material/text_field.patch"

$ScaffoldPatchMaterial = "lib/scripts/material/scaffold.patch"

$RefreshIndicatorPatchMaterial = "lib/scripts/material/refresh_indicator.patch"

$TabsPatchMaterial = "lib/scripts/material/tabs.patch"

$patches_material = @($ModalBarrierPatchMaterial, $NavigationDrawerPatchMaterial, $PopupMenuPatchMaterial,
                    $FABPatchMaterial, $TextFieldPatchMaterial, $ScaffoldPatchMaterial, $RefreshIndicatorPatchMaterial,
                    $TabsPatchMaterial)

$PubCacheDir = Join-Path $HOME ".pub-cache"

switch ($platform.ToLower()) {
    "android" {
        $patches_material += $BottomSheetAndroidPatchMaterial
    }
    "ios" {
        $patches_material += $BottomSheetIOSFlutterMaterialPatchMaterial
    }
    "linux" {
    }
    "macos" {
    }
    "windows" {
        $PubCacheDir = "$env:LOCALAPPDATA/Pub/Cache"
    }
    default {}
}

# Patch files are checked out with CRLF in this fork. Normalize the Flutter
# source patches before applying them on Linux/macOS runners.
Get-ChildItem -Path "$env:GITHUB_WORKSPACE/lib/scripts" -Filter *.patch | ForEach-Object {
    (Get-Content $_.FullName -Raw) -replace "`r`n", "`n" |
        Set-Content -NoNewline $_.FullName
}

try {
    $MaterialUiDir = Get-ChildItem "$PubCacheDir/hosted/pub.dev" -Directory |
        Where-Object { $_.Name -like "material_ui-*" } |
        Select-Object -Last 1

    if ($MaterialUiDir) {
        Remove-Item -Path $MaterialUiDir.FullName -Recurse -Force
    }
} catch {
}

flutter pub get

# material_ui replaces Flutter's material library in the application. The
# pinned GetX fork still imports Flutter material directly, which creates
# incompatible ThemeData/ThemeMode types. Keep the dependency patch local to
# the build so pub cache sources remain untouched in the repository.
$GetPackageDir = Get-ChildItem "$PubCacheDir/git" -Directory |
    Where-Object { $_.Name -like "getx-*" } |
    Select-Object -First 1
if ($GetPackageDir) {
    Get-ChildItem "$($GetPackageDir.FullName)/lib" -Recurse -Filter *.dart |
        ForEach-Object {
            (Get-Content $_.FullName -Raw) -replace
                "package:flutter/material.dart", "package:material_ui/material_ui.dart" |
                Set-Content -NoNewline $_.FullName
        }
}

$MaterialUiDir = Get-ChildItem "$PubCacheDir/hosted/pub.dev" -Directory |
    Where-Object { $_.Name -like "material_ui-*" } |
    Select-Object -Last 1

if (-not $MaterialUiDir) {
    throw "material_ui package not found in pub cache"
}

Write-Host "material_ui dir: $($MaterialUiDir.FullName)"

Get-ChildItem -Path "$env:GITHUB_WORKSPACE/lib/scripts/material" -Filter *.patch | ForEach-Object {
    (Get-Content $_.FullName -Raw) -replace "`r`n", "`n" | 
        Set-Content -NoNewline $_.FullName
}

cd $MaterialUiDir.FullName

foreach ($patch in $patches_material) {
    git apply "$env:GITHUB_WORKSPACE/$patch"
    if ($LASTEXITCODE -eq 0) {
        Write-Host "$patch applied"
    } elseif (Test-PatchAlreadyApplied $patch) {
        Write-Host "$patch already applied"
    } else {
        throw "$LASTEXITCODE"
    }
}

# Flutter 3.47 removed LocalHistoryEntry.popGestureEnabled. material_ui 1.0.0
# still passes it while constructing a persistent bottom sheet entry.
$MaterialScaffold = Join-Path $MaterialUiDir.FullName "lib/src/scaffold.dart"
(Get-Content $MaterialScaffold -Raw) -replace "(?m)^\s*popGestureEnabled:\s*true,\r?\n", "" |
    Set-Content -NoNewline $MaterialScaffold
