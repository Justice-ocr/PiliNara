import 'dart:io' show File;

import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/desktop/windows_dwm_bridge.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_command_palette.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_hover_halo.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

enum WindowsNeoLayoutMode { narrow, compact, expanded }

extension on WindowsNeoLayoutMode {
  double get sidebarWidth => switch (this) {
    WindowsNeoLayoutMode.narrow => 0,
    WindowsNeoLayoutMode.compact => 64,
    WindowsNeoLayoutMode.expanded => 216,
  };

  bool get showLabels => this == WindowsNeoLayoutMode.expanded;
}

class WindowsNeoShell extends StatefulWidget {
  const WindowsNeoShell({
    super.key,
    required this.mainController,
    required this.tabs,
    required this.activeTab,
    required this.child,
    required this.onSplit,
  });

  final MainController mainController;
  final List<WindowsWorkspaceTab> tabs;
  final WindowsWorkspaceTab activeTab;
  final Widget child;
  final VoidCallback onSplit;

  @override
  State<WindowsNeoShell> createState() => _WindowsNeoShellState();
}

class _WindowsNeoShellState extends State<WindowsNeoShell> {
  bool _navigationOpen = false;
  bool _sidebarCollapsed = false;
  bool _isMaximized = false;
  Window? _window;
  int? _windowListener;

  @override
  void initState() {
    super.initState();
    _window = WindowManager.instance.getCurrent();
    _isMaximized = _window?.isMaximized ?? false;
    _windowListener = _window?.addListener((event) {
      if (event is WindowMaximizedEvent || event is WindowRestoredEvent) {
        if (mounted) {
          setState(() => _isMaximized = _window?.isMaximized ?? false);
        }
      }
    });
    _syncWindowTitle();
  }

  @override
  void didUpdateWidget(covariant WindowsNeoShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeTab.id != widget.activeTab.id ||
        oldWidget.activeTab.title != widget.activeTab.title) {
      _syncWindowTitle();
    }
  }

  @override
  void dispose() {
    if (_windowListener case final listener?) {
      _window?.removeListener(listener);
    }
    super.dispose();
  }

  WindowsNeoLayoutMode _layoutMode(double width) {
    if (width < 760) return WindowsNeoLayoutMode.narrow;
    if (width < 1180 || _sidebarCollapsed) return WindowsNeoLayoutMode.compact;
    return WindowsNeoLayoutMode.expanded;
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<WindowsNeoThemeFamily>(
        valueListenable: WindowsNeoThemeController.family,
        builder: (context, family, _) =>
            ValueListenableBuilder<WindowsNeoThemeDepth>(
              valueListenable: WindowsNeoThemeController.depth,
              builder: (context, depth, _) => ValueListenableBuilder<int>(
                valueListenable: WindowsNeoThemeController.customVersion,
                builder: (context, _, _) =>
                    _buildThemed(context, family, depth),
              ),
            ),
      );

  Widget _buildThemed(
    BuildContext context,
    WindowsNeoThemeFamily family,
    WindowsNeoThemeDepth depth,
  ) {
    final baseTheme = Theme.of(context);
    final neoTheme = WindowsNeoTheme.apply(
      baseTheme,
      family: family,
      depth: depth,
    );
    final neoTokens = neoTheme.extension<WindowsNeoTokens>();
    if (neoTokens != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        WindowsDwmBridge.sync(neoTokens, baseTheme.brightness);
      });
    }
    return AnimatedTheme(
      data: neoTheme,
      duration: MediaQuery.maybeOf(context)?.disableAnimations == true
          ? Duration.zero
          : (neoTheme.extension<WindowsNeoTokens>()?.motionStandard ??
                const Duration(milliseconds: 200)),
      curve: Curves.easeOutCubic,
      child: Builder(
        builder: (context) => LayoutBuilder(
          builder: (context, constraints) {
            final canToggleSidebar = constraints.maxWidth >= 1180;
            final mode = _layoutMode(constraints.maxWidth);
            return Material(
              color: context.windowsNeo.background,
              child: Column(
                children: [
                  _WindowsNeoTitleBar(
                    mode: mode,
                    canToggleSidebar: canToggleSidebar,
                    sidebarCollapsed: _sidebarCollapsed,
                    isMaximized: _isMaximized,
                    tabs: widget.tabs,
                    activeId: widget.activeTab.id,
                    onToggleNavigation: () => setState(
                      () => _navigationOpen = !_navigationOpen,
                    ),
                    onToggleSidebarCollapse: () => setState(
                      () => _sidebarCollapsed = !_sidebarCollapsed,
                    ),
                    onSearch: _openSearch,
                    onSplit: widget.onSplit,
                  ),
                  Expanded(
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            if (mode != WindowsNeoLayoutMode.narrow)
                              _WindowsNeoSidebar(
                                mode: mode,
                                mainController: widget.mainController,
                                activeTab: widget.activeTab,
                                onNavigate: _closeNavigation,
                                onSearch: _openSearch,
                              ),
                            Expanded(child: widget.child),
                          ],
                        ),
                        if (mode == WindowsNeoLayoutMode.narrow)
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: !_navigationOpen,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: AnimatedOpacity(
                                      opacity: _navigationOpen ? 1 : 0,
                                      duration: context.windowsNeoDuration(
                                        context.windowsNeo.motionStandard,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: GestureDetector(
                                        behavior: HitTestBehavior.opaque,
                                        onTap: _closeNavigation,
                                        child: ColoredBox(
                                          color: Colors.black.withValues(
                                            alpha: 0.34,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: AnimatedSlide(
                                      offset: _navigationOpen
                                          ? Offset.zero
                                          : const Offset(-1.04, 0),
                                      duration: context.windowsNeoDuration(
                                        context.windowsNeo.motionPage,
                                      ),
                                      curve: Curves.easeOutCubic,
                                      child: SizedBox(
                                        width: 240,
                                        child: _WindowsNeoSidebar(
                                          mode: WindowsNeoLayoutMode.expanded,
                                          mainController: widget.mainController,
                                          activeTab: widget.activeTab,
                                          onNavigate: _closeNavigation,
                                          onSearch: _openSearch,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _closeNavigation() {
    if (_navigationOpen) setState(() => _navigationOpen = false);
  }

  void _syncWindowTitle() {
    _window?.title = '${widget.activeTab.title} - ${Constants.appName}';
  }

  void _openSearch() {
    _closeNavigation();
    WindowsNeoCommandPalette.show(
      context,
      onSplit: widget.onSplit,
      onToggleSidebar: () =>
          setState(() => _sidebarCollapsed = !_sidebarCollapsed),
    );
  }
}

class _WindowsNeoTitleBar extends StatelessWidget {
  const _WindowsNeoTitleBar({
    required this.mode,
    required this.canToggleSidebar,
    required this.sidebarCollapsed,
    required this.isMaximized,
    required this.tabs,
    required this.activeId,
    required this.onToggleNavigation,
    required this.onToggleSidebarCollapse,
    required this.onSearch,
    required this.onSplit,
  });

  final WindowsNeoLayoutMode mode;
  final bool canToggleSidebar;
  final bool sidebarCollapsed;
  final bool isMaximized;
  final List<WindowsWorkspaceTab> tabs;
  final String activeId;
  final VoidCallback onToggleNavigation;
  final VoidCallback onToggleSidebarCollapse;
  final VoidCallback onSearch;
  final VoidCallback onSplit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    final captionBrightness = tokens.usesDarkChrome
        ? Brightness.dark
        : theme.brightness;
    final dividerColor = tokens.usesDarkChrome
        ? Colors.white.withValues(alpha: 0.14)
        : tokens.border.withValues(alpha: 0.65);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.chromeSurface,
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            SizedBox(
              width: mode == WindowsNeoLayoutMode.narrow
                  ? 48
                  : mode.sidebarWidth,
              child: Row(
                children: [
                  if (mode == WindowsNeoLayoutMode.narrow)
                    _TitleBarAction(
                      tooltip: '导航',
                      icon: Icons.menu,
                      onPressed: onToggleNavigation,
                    )
                  else ...[
                    SizedBox(width: mode.showLabels ? 12 : 10),
                    ClipRRect(
                      borderRadius: tokens.mediaBadgeRadius,
                      child: Image.asset(
                        'assets/images/logo/logo.png',
                        width: 20,
                        height: 20,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.layers_rounded,
                          size: 20,
                          color: tokens.chromeAccent,
                        ),
                      ),
                    ),
                    if (mode.showLabels) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Constants.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: tokens.chromeForeground,
                            fontWeight: FontWeight.w700,
                            fontFamilyFallback: tokens.displayFontFallback,
                          ),
                        ),
                      ),
                    ],
                    if (canToggleSidebar)
                      _TitleBarAction(
                        tooltip: sidebarCollapsed ? '展开侧栏' : '收起侧栏',
                        icon: sidebarCollapsed
                            ? Icons.menu_open_rounded
                            : Icons.chevron_left_rounded,
                        size: 32,
                        iconSize: 17,
                        onPressed: onToggleSidebarCollapse,
                      ),
                    if (mode.showLabels) const SizedBox(width: 4),
                  ],
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 9,
              endIndent: 9,
              color: dividerColor,
            ),
            const SizedBox(width: 2),
            const _TitleBarAction(
              tooltip: '后退 (Alt+Left)',
              icon: Icons.arrow_back,
              size: 34,
              iconSize: 17,
              onPressed: WindowsVideoTabService.popActiveTab,
            ),
            const SizedBox(width: 2),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const minDragWidth = 48.0;
                  final maxTabsWidth =
                      (constraints.maxWidth - minDragWidth).clamp(
                        0.0,
                        constraints.maxWidth,
                      );
                  return Row(
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: maxTabsWidth),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 5,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (var index = 0; index < tabs.length; index++) ...[
                                if (index > 0) const SizedBox(width: 4),
                                _WindowsNeoTabPresence(
                                  key: ValueKey(tabs[index].id),
                                  item: tabs[index],
                                  active: tabs[index].id == activeId,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Expanded(
                        child: DragToMoveArea(child: SizedBox.expand()),
                      ),
                    ],
                  );
                },
              ),
            ),
            _WindowsNeoRecentTabsMenu(foreground: tokens.chromeMuted),
            _TitleBarAction(
              tooltip: '分屏播放',
              icon: Icons.splitscreen_outlined,
              size: 34,
              iconSize: 17,
              onPressed: onSplit,
            ),
            _TitleBarAction(
              tooltip: '新建搜索 (Ctrl+K)',
              icon: Icons.add,
              size: 34,
              iconSize: 18,
              onPressed: onSearch,
            ),
            const SizedBox(width: 4),
            VerticalDivider(
              width: 1,
              thickness: 1,
              indent: 10,
              endIndent: 10,
              color: dividerColor,
            ),
            WindowCaptionButton.minimize(
              brightness: captionBrightness,
              onPressed: () => WindowManager.instance.getCurrent()?.minimize(),
            ),
            isMaximized
                ? WindowCaptionButton.unmaximize(
                    brightness: captionBrightness,
                    onPressed: () =>
                        WindowManager.instance.getCurrent()?.restore(),
                  )
                : WindowCaptionButton.maximize(
                    brightness: captionBrightness,
                    onPressed: () =>
                        WindowManager.instance.getCurrent()?.maximize(),
                  ),
            WindowCaptionButton.close(
              brightness: captionBrightness,
              onPressed: () => WindowManager.instance.getCurrent()?.close(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBarAction extends StatelessWidget {
  const _TitleBarAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.size = 38,
    this.iconSize = 18,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return WindowsNeoHoverHalo(
      borderRadius: tokens.actionRadius,
      child: SizedBox(
        width: size,
        height: size,
        child: IconButton(
          tooltip: tooltip,
          padding: EdgeInsets.zero,
          iconSize: iconSize,
          onPressed: onPressed,
          icon: Icon(icon, color: context.windowsNeo.chromeForeground),
        ),
      ),
    );
  }
}

class _WindowsNeoSidebar extends StatelessWidget {
  const _WindowsNeoSidebar({
    required this.mode,
    required this.mainController,
    required this.activeTab,
    required this.onNavigate,
    required this.onSearch,
  });

  final WindowsNeoLayoutMode mode;
  final MainController mainController;
  final WindowsWorkspaceTab activeTab;
  final VoidCallback onNavigate;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final darkNav = tokens.navigationSurface.computeLuminance() < 0.12;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.navigationSurface,
        border: Border(
          right: BorderSide(
            color: darkNav
                ? Colors.white.withValues(alpha: 0.10)
                : tokens.border.withValues(alpha: 0.56),
          ),
        ),
      ),
      child: SizedBox(
        width: mode.sidebarWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showArtwork =
                  mode.showLabels &&
                  constraints.maxHeight >= 560 &&
                  tokens.depth != WindowsNeoThemeDepth.minimal;
              return Column(
                children: [
                  Expanded(
                    child: Obx(
                      () => ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          for (
                            var index = 0;
                            index < mainController.navigationBars.length;
                            index++
                          )
                            _WindowsNeoNavItem(
                              label: _labelForNavigation(
                                mainController.navigationBars[index],
                              ),
                              icon: _iconForNavigation(
                                mainController.navigationBars[index],
                              ),
                              selected:
                                  activeTab.isHome &&
                                  mainController.selectedIndex.value == index,
                              showLabel: mode.showLabels,
                              onTap: () {
                                WindowsVideoTabService.select(
                                  WindowsVideoTabService.homeTabId,
                                );
                                mainController.setIndex(index);
                                onNavigate();
                              },
                            ),
                          const SizedBox(height: 10),
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: darkNav
                                ? Colors.white.withValues(alpha: 0.12)
                                : tokens.border.withValues(alpha: 0.65),
                          ),
                          const SizedBox(height: 10),
                          _WindowsNeoNavItem(
                            label: '搜索',
                            icon: Icons.search,
                            selected: false,
                            showLabel: mode.showLabels,
                            onTap: onSearch,
                          ),
                          _toolItem(
                            label: '下载',
                            icon: Icons.download_outlined,
                            route: '/download',
                          ),
                          _toolItem(
                            label: '消息',
                            icon: Icons.chat_bubble_outline,
                            route: '/whisper',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (showArtwork) ...[
                    const _WindowsNeoSidebarArtwork(),
                    const SizedBox(height: 8),
                  ] else if (mode.showLabels) ...[
                    const _WindowsNeoSidebarSignature(),
                    const SizedBox(height: 6),
                  ],
                  _WindowsNeoThemeQuickBar(showLabel: mode.showLabels),
                  const SizedBox(height: 4),
                  _toolItem(
                    label: '设置',
                    icon: Icons.settings_outlined,
                    route: '/setting',
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _toolItem({
    required String label,
    required IconData icon,
    required String route,
  }) => _WindowsNeoNavItem(
    label: label,
    icon: icon,
    selected:
        activeTab.type == WindowsWorkspaceTabType.tool &&
        activeTab.arguments['tabRoute'] == route,
    showLabel: mode.showLabels,
    onTap: () {
      PageUtils.openToolTab(route: route, title: label);
      onNavigate();
    },
  );

  static String _labelForNavigation(NavigationBarType type) => switch (type) {
    NavigationBarType.home => '首页',
    NavigationBarType.dynamics => '动态',
    NavigationBarType.mine => '我的',
  };

  static IconData _iconForNavigation(NavigationBarType type) => switch (type) {
    NavigationBarType.home => Icons.home_outlined,
    NavigationBarType.dynamics => Icons.motion_photos_on_outlined,
    NavigationBarType.mine => Icons.person_outline,
  };
}

class _WindowsNeoNavItem extends StatelessWidget {
  const _WindowsNeoNavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.showLabel,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool showLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final foreground = selected
        ? tokens.navigationForeground
        : tokens.navigationMuted;
    final radius = tokens.navigationItemRadius;
    final item = WindowsNeoHoverHalo(
      borderRadius: radius,
      enabled: !selected,
      child: AnimatedContainer(
        duration: context.windowsNeoDuration(tokens.motionFast),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? null : Colors.transparent,
          gradient: selected ? tokens.sidebarSelectionGradient : null,
          borderRadius: radius,
        ),
        child: Stack(
          children: [
            if (showLabel)
              Positioned(
                right: 7,
                top: -4,
                bottom: -4,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: selected ? 1 : 0,
                      duration: context.windowsNeoDuration(tokens.motionFast),
                      curve: Curves.easeOutCubic,
                      child: Text(
                        tokens.shellWordmark,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: tokens.navigationForeground.withValues(
                            alpha: 0.13,
                          ),
                          fontSize: 25,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Material(
              color: Colors.transparent,
              borderRadius: radius,
              child: InkWell(
                borderRadius: radius,
                hoverColor: selected
                    ? Colors.white.withValues(alpha: 0.10)
                    : tokens.hover,
                onTap: onTap,
                child: SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: showLabel
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.center,
                    children: [
                      if (showLabel) const SizedBox(width: 11),
                      TweenAnimationBuilder<Color?>(
                        tween: ColorTween(begin: foreground, end: foreground),
                        duration: context.windowsNeoDuration(tokens.motionFast),
                        curve: Curves.easeOutCubic,
                        builder: (context, color, _) => Icon(
                          icon,
                          size: 19,
                          color: color,
                        ),
                      ),
                      if (showLabel) ...[
                        const SizedBox(width: 11),
                        Expanded(
                          child: AnimatedDefaultTextStyle(
                            duration: context.windowsNeoDuration(
                              tokens.motionFast,
                            ),
                            curve: Curves.easeOutCubic,
                            style:
                                Theme.of(
                                  context,
                                ).textTheme.bodyMedium?.copyWith(
                                  color: foreground,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ) ??
                                TextStyle(color: foreground),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            if (showLabel)
              Positioned(
                left: 0,
                top: 10,
                bottom: 10,
                child: AnimatedContainer(
                  duration: context.windowsNeoDuration(tokens.motionFast),
                  curve: Curves.easeOutCubic,
                  width: selected ? 3 : 0,
                  decoration: BoxDecoration(
                    color: selected
                        ? tokens.navigationForeground.withValues(alpha: 0.78)
                        : tokens.accent,
                    borderRadius: BorderRadius.circular(
                      tokens.usesRoundedGeometry ? 2 : 0,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: showLabel ? item : Tooltip(message: label, child: item),
    );
  }
}

class _WindowsNeoSidebarArtwork extends StatelessWidget {
  const _WindowsNeoSidebarArtwork();

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final radius = tokens.sidebarArtworkRadius;
    return IgnorePointer(
      child: SizedBox(
        height: 132,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: tokens.surface,
            borderRadius: radius,
            border: Border.all(
              color: tokens.border.withValues(alpha: 0.72),
            ),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: _WindowsNeoSidebarArtworkLayer(
              artwork: tokens.identity.sidebarArtwork,
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowsNeoSidebarArtworkLayer extends StatelessWidget {
  const _WindowsNeoSidebarArtworkLayer({required this.artwork});

  final WindowsNeoSidebarArtwork artwork;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    if (artwork == WindowsNeoSidebarArtwork.portrait) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.90,
            child: Image.asset(
              'assets/images/windows_neo_miku_sidebar.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              filterQuality: FilterQuality.medium,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  tokens.accent.withValues(alpha: 0.46),
                  tokens.accent.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
                stops: const [0, 0.42, 0.72],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 11,
            child: Text(
              tokens.shellMark,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
        ],
      );
    }
    if (tokens.family == WindowsNeoThemeFamily.custom) {
      final path = WindowsNeoThemeController.customWallpaper.value;
      final file = path.isNotEmpty ? File(path) : null;
      final hasFile = file != null && file.existsSync();
      return Stack(
        fit: StackFit.expand,
        children: [
          if (hasFile)
            Opacity(
              opacity: 0.84,
              child: Image.file(
                file,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    tokens.accent.withValues(alpha: 0.85),
                    tokens.secondaryAccent.withValues(alpha: 0.55),
                    tokens.surfaceRaised,
                  ],
                ),
              ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  const Color(0xFF101317).withValues(alpha: 0.72),
                  const Color(0xFF101317).withValues(alpha: 0.28),
                  Colors.transparent,
                ],
                stops: const [0, 0.55, 1],
              ),
            ),
          ),
          Positioned(
            left: 12,
            top: 10,
            child: Text(
              tokens.shellMark,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w900,
                height: .9,
                fontFamilyFallback: tokens.displayFontFallback,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 11,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 2.5, height: 14, color: tokens.accent),
                const SizedBox(width: 6),
                Text(
                  '${tokens.shellWordmark} · ${tokens.shellSubmark}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    fontFamilyFallback: tokens.displayFontFallback,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final asset = tokens.family.backdropAsset;
    if (asset != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.78,
            child: Image.asset(
              asset,
              fit: BoxFit.cover,
              alignment: Alignment.centerRight,
              filterQuality: FilterQuality.medium,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  tokens.chromeSurface.withValues(alpha: 0.86),
                  tokens.chromeSurface.withValues(alpha: 0.44),
                  tokens.chromeSurface.withValues(alpha: 0.14),
                ],
                stops: const [0, 0.48, 1],
              ),
            ),
          ),
          if (tokens.depth == WindowsNeoThemeDepth.complex ||
              tokens.depth == WindowsNeoThemeDepth.maximal)
            Positioned.fill(
              child: Opacity(
                opacity: 0.65,
                child: switch (artwork) {
                  WindowsNeoSidebarArtwork.instrumentPanel => CustomPaint(
                    painter: _WindowsNeoEndfieldStagePainter(
                      ruleColor: Colors.white.withValues(alpha: 0.22),
                      signalColor: tokens.accent.withValues(alpha: 0.85),
                    ),
                  ),
                  WindowsNeoSidebarArtwork.archivePanel => CustomPaint(
                    painter: _WindowsNeoOrbitStagePainter(
                      lineColor: tokens.accent.withValues(alpha: 0.48),
                      pointColor: tokens.secondaryAccent.withValues(alpha: 0.68),
                    ),
                  ),
                  _ => const SizedBox.shrink(),
                },
              ),
            ),
          Positioned(
            left: 12,
            top: 10,
            child: Text(
              tokens.shellMark,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.92),
                fontWeight: FontWeight.w900,
                height: .9,
                fontFamilyFallback: tokens.displayFontFallback,
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 11,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 2.5, height: 14, color: tokens.accent),
                const SizedBox(width: 6),
                Text(
                  '${tokens.shellWordmark} · ${tokens.shellSubmark}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamilyFallback: tokens.displayFontFallback,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    return _WindowsNeoSidebarPanel(artwork: artwork);
  }
}

class _WindowsNeoArkStage extends StatelessWidget {
  const _WindowsNeoArkStage();

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/windows_neo_sidebar_sunflower.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0, -0.04),
          filterQuality: FilterQuality.medium,
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF080A0B).withValues(alpha: 0.04),
                const Color(0xFF080A0B).withValues(alpha: 0.02),
                const Color(0xFF080A0B).withValues(alpha: 0.40),
              ],
              stops: const [0, 0.60, 1],
            ),
          ),
        ),
        Positioned(
          left: 8,
          top: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF080A0B).withValues(alpha: 0.72),
              border: Border(
                left: BorderSide(color: tokens.accent, width: 2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 4, 8, 4),
              child: Text(
                'MEDIA / ${tokens.shellMark}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.90),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF080A0B).withValues(alpha: 0.72),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(7, 4, 9, 4),
              child: Text(
                tokens.shellWordmark,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _WindowsNeoSidebarPanel extends StatelessWidget {
  const _WindowsNeoSidebarPanel({required this.artwork});

  final WindowsNeoSidebarArtwork artwork;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return switch (artwork) {
      WindowsNeoSidebarArtwork.instrumentPanel => _WindowsNeoEndfieldStage(
        tokens: tokens,
      ),
      WindowsNeoSidebarArtwork.archivePanel => _WindowsNeoExAstrisStage(
        tokens: tokens,
      ),
      WindowsNeoSidebarArtwork.playfulPanel => _WindowsNeoPopucomStage(
        tokens: tokens,
      ),
      WindowsNeoSidebarArtwork.studioPanel => _WindowsNeoCorporateStage(
        tokens: tokens,
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _WindowsNeoEndfieldStage extends StatelessWidget {
  const _WindowsNeoEndfieldStage({required this.tokens});

  final WindowsNeoTokens tokens;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: tokens.surfaceRaised),
      Positioned(
        left: 0,
        top: 0,
        bottom: 0,
        child: Container(width: 38, color: tokens.ink),
      ),
      Positioned(
        left: 12,
        top: 12,
        child: Text(
          '01',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: tokens.accent,
            fontWeight: FontWeight.w900,
            height: .8,
          ),
        ),
      ),
      Positioned(
        left: 50,
        top: 16,
        child: Text(
          'FIELD / WORKSPACE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tokens.ink,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
      ),
      Positioned.fill(
        child: CustomPaint(
          painter: _WindowsNeoEndfieldStagePainter(
            ruleColor: tokens.ink.withValues(alpha: 0.18),
            signalColor: tokens.accent,
          ),
        ),
      ),
      Positioned(
        left: 50,
        right: 12,
        bottom: 11,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: tokens.ink.withValues(alpha: 0.28)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              'ROUTE // WORKSPACE',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.muted,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.25,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _WindowsNeoExAstrisStage extends StatelessWidget {
  const _WindowsNeoExAstrisStage({required this.tokens});

  final WindowsNeoTokens tokens;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: tokens.background),
      Positioned.fill(
        child: CustomPaint(
          painter: _WindowsNeoOrbitStagePainter(
            lineColor: tokens.accent.withValues(alpha: 0.44),
            pointColor: tokens.secondaryAccent.withValues(alpha: 0.54),
          ),
        ),
      ),
      Positioned(
        right: 14,
        top: 16,
        child: Text(
          '03',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.16),
            fontFamilyFallback: tokens.displayFontFallback,
            fontWeight: FontWeight.w500,
            height: .82,
          ),
        ),
      ),
      Positioned(
        left: 12,
        top: 12,
        child: Text(
          'ARCHIVE',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.88),
            fontWeight: FontWeight.w700,
            letterSpacing: 2.2,
          ),
        ),
      ),
      Positioned(
        left: 12,
        bottom: 12,
        child: Text(
          'ORBIT / 03',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: tokens.accent,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
      ),
    ],
  );
}

class _WindowsNeoPopucomStage extends StatelessWidget {
  const _WindowsNeoPopucomStage({required this.tokens});

  final WindowsNeoTokens tokens;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      const ColoredBox(color: Color(0xFF3994FF)),
      Positioned(
        left: 0,
        right: 0,
        top: 0,
        child: SizedBox(
          height: 35,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF252B35),
              border: Border(
                bottom: BorderSide(
                  color: tokens.accent.withValues(alpha: 0.72),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(
        right: 12,
        top: 12,
        child: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: tokens.accent,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF141414), width: 2),
          ),
        ),
      ),
      Positioned(
        right: 35,
        bottom: 14,
        child: Transform.rotate(
          angle: .18,
          child: Container(
            width: 74,
            height: 30,
            decoration: BoxDecoration(
              color: tokens.tertiaryAccent,
              borderRadius: BorderRadius.zero,
              border: Border.all(color: const Color(0xFF141414), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xFF141414), offset: Offset(4, 4)),
              ],
            ),
          ),
        ),
      ),
      Positioned(
        left: 14,
        top: 10,
        child: Text(
          'PLAY',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
      ),
      Positioned(
        left: 14,
        bottom: 15,
        child: Text(
          'CO-OP / 04',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
      ),
    ],
  );
}

class _WindowsNeoCorporateStage extends StatelessWidget {
  const _WindowsNeoCorporateStage({required this.tokens});

  final WindowsNeoTokens tokens;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      ColoredBox(color: tokens.ink),
      Positioned(
        right: 16,
        top: 12,
        child: Text(
          '05',
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.14),
            fontWeight: FontWeight.w800,
            height: .82,
          ),
        ),
      ),
      Positioned(
        left: 14,
        top: 16,
        child: Text(
          'STUDIO',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
      ),
      Positioned(
        left: 14,
        right: 14,
        bottom: 24,
        child: Container(
          height: 1,
          color: Colors.white.withValues(alpha: 0.78),
        ),
      ),
      Positioned(
        right: 14,
        top: 14,
        bottom: 14,
        child: Container(width: 3, color: tokens.accent),
      ),
      Positioned(
        left: 14,
        bottom: 10,
        child: Row(
          children: [
            Text(
              'PILI NARA',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              'WORK / 05',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

class _WindowsNeoEndfieldStagePainter extends CustomPainter {
  const _WindowsNeoEndfieldStagePainter({
    required this.ruleColor,
    required this.signalColor,
  });

  final Color ruleColor;
  final Color signalColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rule = Paint()
      ..color = ruleColor
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index++) {
      final y = 50.0 + index * 18;
      canvas.drawLine(Offset(50, y), Offset(size.width - 12, y), rule);
    }
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 42, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, 36)
        ..close(),
      Paint()..color = signalColor,
    );
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoEndfieldStagePainter oldDelegate) =>
      oldDelegate.ruleColor != ruleColor ||
      oldDelegate.signalColor != signalColor;
}

class _WindowsNeoOrbitStagePainter extends CustomPainter {
  const _WindowsNeoOrbitStagePainter({
    required this.lineColor,
    required this.pointColor,
  });

  final Color lineColor;
  final Color pointColor;

  @override
  void paint(Canvas canvas, Size size) {
    final orbit = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * .68, size.height * .52);
    canvas
      ..drawOval(Rect.fromCenter(center: center, width: 152, height: 60), orbit)
      ..drawOval(Rect.fromCenter(center: center, width: 96, height: 128), orbit)
      ..drawCircle(center, 3, Paint()..color = pointColor);
    for (final point in const [
      Offset(.22, .68),
      Offset(.84, .26),
      Offset(.86, .74),
    ]) {
      canvas.drawCircle(
        Offset(size.width * point.dx, size.height * point.dy),
        1.8,
        Paint()..color = pointColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoOrbitStagePainter oldDelegate) =>
      oldDelegate.lineColor != lineColor ||
      oldDelegate.pointColor != pointColor;
}

class _WindowsNeoSidebarSignature extends StatelessWidget {
  const _WindowsNeoSidebarSignature();

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: SizedBox(
          height: 44,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: tokens.border.withValues(alpha: 0.52),
                ),
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 6),
                Container(
                  width: 3,
                  height: 22,
                  color: tokens.chromeAccent.withValues(alpha: 0.84),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tokens.shellWordmark,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: tokens.navigationForeground.withValues(
                                alpha: 0.82,
                              ),
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2.0,
                              fontFamilyFallback: tokens.displayFontFallback,
                            ),
                      ),
                      Text(
                        tokens.shellSubmark,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tokens.navigationMuted,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          fontFamilyFallback: tokens.displayFontFallback,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  tokens.shellMark,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: tokens.chromeAccent.withValues(alpha: 0.42),
                    fontWeight: FontWeight.w900,
                    fontFamilyFallback: tokens.displayFontFallback,
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowsNeoThemeQuickBar extends StatefulWidget {
  const _WindowsNeoThemeQuickBar({required this.showLabel});

  final bool showLabel;

  @override
  State<_WindowsNeoThemeQuickBar> createState() =>
      _WindowsNeoThemeQuickBarState();
}

class _WindowsNeoThemeQuickBarState extends State<_WindowsNeoThemeQuickBar> {
  Future<void> _cycleBrightness() async {
    final current = Pref.themeType;
    final next = switch (current) {
      ThemeType.system => ThemeType.light,
      ThemeType.light => ThemeType.dark,
      ThemeType.dark => ThemeType.system,
    };
    await GStorage.setting.put(SettingBoxKey.themeMode, next.index);
    Get.changeThemeMode(ThemeUtils.themeMode = next.toThemeMode);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final darkNav = tokens.navigationSurface.computeLuminance() < 0.12;
    final fg = tokens.navigationMuted;
    final chipBg = darkNav
        ? Colors.white.withValues(alpha: 0.06)
        : tokens.surface.withValues(alpha: 0.65);
    final chipBorder = darkNav
        ? Colors.white.withValues(alpha: 0.12)
        : tokens.border.withValues(alpha: 0.55);

    ThemeType currentMode;
    try {
      currentMode = Pref.themeType;
    } catch (_) {
      currentMode = ThemeType.system;
    }
    final brightnessTooltip = switch (currentMode) {
      ThemeType.light => '当前：浅色模式（点击切换深色）',
      ThemeType.dark => '当前：深色模式（点击跟随系统）',
      ThemeType.system => '当前：跟随系统（点击切换浅色）',
    };
    final brightnessIcon = switch (currentMode) {
      ThemeType.light => Icons.light_mode_outlined,
      ThemeType.dark => Icons.dark_mode_outlined,
      ThemeType.system => Icons.brightness_auto_outlined,
    };

    final themePicker = PopupMenuButton<WindowsNeoThemeFamily>(
      tooltip: '快速切换 Windows Neo 主题',
      initialValue: tokens.family,
      onSelected: WindowsNeoThemeController.select,
      itemBuilder: (context) => [
        for (final def in WindowsNeoThemeRegistry.values)
          PopupMenuItem(
            value: def.family,
            child: Row(
              children: [
                Builder(
                  builder: (context) {
                    final preview = def.buildTokens(
                      Theme.of(context),
                      def.defaultDepth,
                    );
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: preview.accent,
                        shape: preview.usesRoundedGeometry
                            ? BoxShape.circle
                            : BoxShape.rectangle,
                        border: Border.all(
                          color: tokens.border.withValues(alpha: 0.7),
                          width: 0.8,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${def.label} · ${def.description}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (def.family == tokens.family)
                  Icon(Icons.check, size: 16, color: tokens.accentInk),
              ],
            ),
          ),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: tokens.navigationItemRadius,
          border: Border.all(color: chipBorder),
        ),
        child: SizedBox(
          height: 34,
          child: Row(
            mainAxisAlignment: widget.showLabel
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              if (widget.showLabel) const SizedBox(width: 10),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: tokens.accent,
                  shape: tokens.usesRoundedGeometry
                      ? BoxShape.circle
                      : BoxShape.rectangle,
                  border: Border.all(
                    color: tokens.navigationForeground.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
              ),
              if (widget.showLabel) ...[
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    tokens.definition.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: tokens.navigationForeground.withValues(
                        alpha: 0.88,
                      ),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.unfold_more_rounded, size: 15, color: fg),
                const SizedBox(width: 6),
              ],
            ],
          ),
        ),
      ),
    );

    final brightnessBtn = Tooltip(
      message: brightnessTooltip,
      child: Material(
        color: chipBg,
        borderRadius: tokens.navigationItemRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _cycleBrightness,
          hoverColor: darkNav
              ? Colors.white.withValues(alpha: 0.12)
              : tokens.hover,
          child: Container(
            width: widget.showLabel ? 34 : double.infinity,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: tokens.navigationItemRadius,
              border: Border.all(color: chipBorder),
            ),
            alignment: Alignment.center,
            child: Icon(
              brightnessIcon,
              size: 16,
              color: tokens.navigationForeground.withValues(alpha: 0.84),
            ),
          ),
        ),
      ),
    );

    if (!widget.showLabel) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          themePicker,
          const SizedBox(height: 6),
          brightnessBtn,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: themePicker),
        const SizedBox(width: 6),
        brightnessBtn,
      ],
    );
  }
}

class _WindowsNeoTabPresence extends StatefulWidget {
  const _WindowsNeoTabPresence({
    super.key,
    required this.item,
    required this.active,
  });

  final WindowsWorkspaceTab item;
  final bool active;

  @override
  State<_WindowsNeoTabPresence> createState() => _WindowsNeoTabPresenceState();
}

class _WindowsNeoTabPresenceState extends State<_WindowsNeoTabPresence>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  bool _entered = false;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.windowsNeo.motionStandard;
    if (_entered) return;
    _entered = true;
    if (context.windowsNeoReduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (!widget.item.canClose || _closing) return;
    _closing = true;
    if (!context.windowsNeoReduceMotion) {
      await _controller.reverse();
    }
    if (mounted) WindowsVideoTabService.close(widget.item.id);
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      axis: Axis.horizontal,
      alignment: AlignmentDirectional.centerStart,
      sizeFactor: _animation,
      child: FadeTransition(
        opacity: _animation,
        child: WindowsNeoWorkspaceTab(
          item: widget.item,
          active: widget.active,
          onClose: _close,
        ),
      ),
    );
  }
}

class _WindowsNeoRecentTabsMenu extends StatelessWidget {
  const _WindowsNeoRecentTabsMenu({this.foreground});

  final Color? foreground;

  @override
  Widget build(BuildContext context) => Obx(() => _buildMenu(context));

  Widget _buildMenu(BuildContext context) {
    final tokens = context.windowsNeo;
    final baseColor = foreground ?? tokens.muted;
    final tabs = WindowsVideoTabService.recentlyClosedTabs.reversed
        .take(8)
        .toList(growable: false);
    return PopupMenuButton<String>(
      tooltip: '最近关闭的标签页',
      enabled: tabs.isNotEmpty,
      icon: Icon(
        Icons.history_rounded,
        size: 17,
        color: tabs.isEmpty
            ? baseColor.withValues(alpha: 0.38)
            : baseColor,
      ),
      itemBuilder: (context) => [
        for (final item in tabs)
          PopupMenuItem(
            value: item.id,
            child: SizedBox(
              width: 220,
              child: Row(
                children: [
                  Icon(
                    WindowsNeoWorkspaceTab._iconForItem(item),
                    size: 17,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(item.title, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          ),
      ],
      onSelected: WindowsVideoTabService.restoreClosedTab,
    );
  }
}

class WindowsNeoWorkspaceTab extends StatelessWidget {
  const WindowsNeoWorkspaceTab({
    super.key,
    required this.item,
    required this.active,
    required this.onClose,
  });

  static const double height = 32;

  final WindowsWorkspaceTab item;
  final bool active;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final darkChrome = tokens.usesDarkChrome;
    final foreground = active
        ? tokens.ink
        : (darkChrome ? Colors.white.withValues(alpha: 0.76) : tokens.muted);
    final inactiveBg = darkChrome
        ? Colors.white.withValues(alpha: 0.08)
        : tokens.surface.withValues(alpha: 0.42);
    final inactiveBorder = darkChrome
        ? Colors.white.withValues(alpha: 0.16)
        : tokens.border.withValues(alpha: 0.65);
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kMiddleMouseButton && item.canClose) {
          onClose();
        }
      },
      child: GestureDetector(
        onSecondaryTapDown: (details) => _showMenu(
          context,
          details.globalPosition,
        ),
        child: IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 116,
              maxWidth: 232,
              minHeight: height,
              maxHeight: height,
            ),
            child: WindowsNeoHoverHalo(
              borderRadius: tokens.workspaceTabRadius,
              enabled: !active,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  AnimatedContainer(
                    duration: context.windowsNeoDuration(tokens.motionFast),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: active ? null : inactiveBg,
                      gradient: active ? tokens.workspaceTabGradient : null,
                      borderRadius: tokens.workspaceTabRadius,
                      border: Border.all(
                        color: active
                            ? tokens.accentBorder.withValues(alpha: 0.65)
                            : inactiveBorder,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: tokens.workspaceTabRadius,
                      child: InkWell(
                        borderRadius: tokens.workspaceTabRadius,
                        hoverColor: darkChrome
                            ? Colors.white.withValues(alpha: 0.12)
                            : tokens.hover,
                        onTap: active
                            ? null
                            : () => WindowsVideoTabService.select(item.id),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 9, right: 3),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _iconForItem(item),
                                size: 15.5,
                                color: active ? tokens.accentInk : foreground,
                              ),
                              const SizedBox(width: 7),
                              if (WindowsVideoTabService.isPinned(item.id)) ...[
                                Icon(
                                  Icons.push_pin_rounded,
                                  size: 13,
                                  color: tokens.accentInk,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Flexible(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: foreground,
                                        fontWeight: active
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                              if (item.supportsAudio)
                                Obx(
                                  () {
                                    final audible =
                                        WindowsVideoTabService.isTabAudioEnabled(
                                          item.id,
                                        );
                                    return SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: IconButton(
                                        tooltip: audible ? '移出混音' : '加入混音',
                                        padding: EdgeInsets.zero,
                                        iconSize: 14,
                                        color: audible
                                            ? tokens.accentInk
                                            : foreground,
                                        style: audible
                                            ? IconButton.styleFrom(
                                                backgroundColor: tokens
                                                    .accentSurface,
                                              )
                                            : null,
                                        onPressed: () =>
                                            WindowsVideoTabService.setTabAudioEnabled(
                                              item.id,
                                              !audible,
                                            ),
                                        icon: Icon(
                                          audible
                                              ? Icons.volume_up_rounded
                                              : Icons.volume_off_outlined,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              if (item.canClose)
                                SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: IconButton(
                                    tooltip: '关闭标签页',
                                    padding: EdgeInsets.zero,
                                    iconSize: 14,
                                    color: foreground,
                                    onPressed: onClose,
                                    icon: const Icon(Icons.close),
                                  ),
                                )
                              else
                                const SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: WindowsNeoActiveBeat(active: active, width: 38),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMenu(BuildContext context, Offset position) async {
    final size = MediaQuery.sizeOf(context);
    final action = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        size.width - position.dx,
        size.height - position.dy,
      ),
      items: [
        if (item.canPin)
          PopupMenuItem(
            value: 'pin',
            child: Text(
              WindowsVideoTabService.isPinned(item.id) ? '取消固定' : '固定标签',
            ),
          ),
        if (item.supportsAudio)
          PopupMenuItem(
            value: 'audio',
            child: Text(
              WindowsVideoTabService.isTabAudioEnabled(item.id)
                  ? '移出混音'
                  : '加入混音',
            ),
          ),
        if (item.canClose)
          const PopupMenuItem(value: 'close', child: Text('关闭标签页')),
        if (WindowsVideoTabService.tabs.indexOf(item) > 1)
          const PopupMenuItem(value: 'left', child: Text('关闭左侧标签页')),
        if (WindowsVideoTabService.tabs.indexOf(item) <
            WindowsVideoTabService.tabs.length - 1)
          const PopupMenuItem(value: 'right', child: Text('关闭右侧标签页')),
        const PopupMenuItem(value: 'others', child: Text('关闭其他标签页')),
      ],
    );
    if (action == 'pin') {
      WindowsVideoTabService.togglePinned(item.id);
    } else if (action == 'audio') {
      await WindowsVideoTabService.setTabAudioEnabled(
        item.id,
        !WindowsVideoTabService.isTabAudioEnabled(item.id),
      );
    } else if (action == 'close') {
      await onClose();
    } else if (action == 'left') {
      WindowsVideoTabService.closeTabsToLeft(item.id);
    } else if (action == 'right') {
      WindowsVideoTabService.closeTabsToRight(item.id);
    } else if (action == 'others') {
      WindowsVideoTabService.closeOthers(item.id);
    }
  }

  static IconData _iconForItem(WindowsWorkspaceTab item) => switch (item.type) {
    WindowsWorkspaceTabType.home => Icons.home_outlined,
    WindowsWorkspaceTabType.search => Icons.search,
    WindowsWorkspaceTabType.live => Icons.sensors,
    WindowsWorkspaceTabType.video => Icons.play_circle_outline,
    WindowsWorkspaceTabType.member => Icons.person_outline,
    WindowsWorkspaceTabType.dynamic => Icons.motion_photos_on_outlined,
    WindowsWorkspaceTabType.tool => switch (item.arguments['tabRoute']) {
      '/setting' => Icons.settings_outlined,
      '/download' => Icons.download_outlined,
      '/whisper' => Icons.chat_bubble_outline,
      '/searchTrending' => Icons.local_fire_department_rounded,
      _ => Icons.apps_outlined,
    },
  };
}
