import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_hover_halo.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  final List<WindowsVideoTabItem> tabs;
  final WindowsVideoTabItem activeTab;
  final Widget child;
  final VoidCallback onSplit;

  @override
  State<WindowsNeoShell> createState() => _WindowsNeoShellState();
}

class _WindowsNeoShellState extends State<WindowsNeoShell> with WindowListener {
  bool _navigationOpen = false;
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isMaximized().then((value) {
      if (mounted) setState(() => _isMaximized = value);
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
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() => setState(() => _isMaximized = true);

  @override
  void onWindowUnmaximize() => setState(() => _isMaximized = false);

  WindowsNeoLayoutMode _layoutMode(double width) {
    if (width < 760) return WindowsNeoLayoutMode.narrow;
    if (width < 1180) return WindowsNeoLayoutMode.compact;
    return WindowsNeoLayoutMode.expanded;
  }

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<WindowsNeoThemeFamily>(
        valueListenable: WindowsNeoThemeController.family,
        builder: (context, family, _) =>
            ValueListenableBuilder<WindowsNeoThemeDepth>(
          valueListenable: WindowsNeoThemeController.depth,
          builder: (context, depth, _) => _buildThemed(context, family, depth),
        ),
      );

  Widget _buildThemed(
    BuildContext context,
    WindowsNeoThemeFamily family,
    WindowsNeoThemeDepth depth,
  ) {
    final neoTheme = WindowsNeoTheme.apply(
      Theme.of(context),
      family: family,
      depth: depth,
    );
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
            final mode = _layoutMode(constraints.maxWidth);
            return Material(
              color: context.windowsNeo.background,
              child: Column(
                children: [
                  _WindowsNeoTitleBar(
                    mode: mode,
                    isMaximized: _isMaximized,
                    onToggleNavigation: () => setState(
                      () => _navigationOpen = !_navigationOpen,
                    ),
                    onSearch: _openSearch,
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
                            Expanded(
                              child: Column(
                                children: [
                                  _WindowsNeoTabStrip(
                                    tabs: widget.tabs,
                                    activeId: widget.activeTab.id,
                                    onSearch: _openSearch,
                                    onSplit: widget.onSplit,
                                  ),
                                  Expanded(child: widget.child),
                                ],
                              ),
                            ),
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
    windowManager.setTitle('${widget.activeTab.title} - ${Constants.appName}');
  }

  void _openSearch() {
    WindowsVideoTabService.select(WindowsVideoTabService.homeTabId);
    _closeNavigation();
    WidgetsBinding.instance.addPostFrameCallback((_) => PageUtils.toSearch());
  }
}

class _WindowsNeoTitleBar extends StatelessWidget {
  const _WindowsNeoTitleBar({
    required this.mode,
    required this.isMaximized,
    required this.onToggleNavigation,
    required this.onSearch,
  });

  final WindowsNeoLayoutMode mode;
  final bool isMaximized;
  final VoidCallback onToggleNavigation;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    return SizedBox(
      height: 44,
      child: ColoredBox(
        color: tokens.chromeSurface,
        child: Row(
          children: [
            SizedBox(
              width:
                  mode == WindowsNeoLayoutMode.narrow ? 48 : mode.sidebarWidth,
              child: Row(
                children: [
                  if (mode == WindowsNeoLayoutMode.narrow)
                    _TitleBarAction(
                      tooltip: '导航',
                      icon: Icons.menu,
                      onPressed: onToggleNavigation,
                    )
                  else ...[
                    const SizedBox(width: 14),
                    Icon(
                      Icons.layers_rounded,
                      size: 20,
                      color: tokens.accent,
                    ),
                    if (mode.showLabels) ...[
                      const SizedBox(width: 9),
                      Flexible(
                        child: Text(
                          Constants.appName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: tokens.chromeForeground,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            VerticalDivider(
              width: 2,
              thickness: 1,
              color: tokens.chromeForeground.withValues(alpha: 0.24),
            ),
            const _TitleBarAction(
              tooltip: '后退',
              icon: Icons.arrow_back,
              onPressed: WindowsVideoTabService.popActiveTab,
            ),
            if (mode != WindowsNeoLayoutMode.narrow)
              _TitleBarAction(
                tooltip: '搜索',
                icon: Icons.search,
                onPressed: onSearch,
              ),
            Expanded(
              child: DragToMoveArea(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: mode == WindowsNeoLayoutMode.expanded
                          ? Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Text(
                                'Windows 工作区',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: tokens.chromeMuted,
                                ),
                              ),
                            )
                          : const SizedBox.expand(),
                    ),
                    if (mode == WindowsNeoLayoutMode.expanded)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: IgnorePointer(
                            child: Text(
                              tokens.shellMark,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: tokens.accent.withValues(alpha: 0.20),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            WindowCaptionButton.minimize(
              brightness:
                  tokens.usesDarkChrome ? Brightness.dark : theme.brightness,
              onPressed: windowManager.minimize,
            ),
            isMaximized
                ? WindowCaptionButton.unmaximize(
                    brightness: tokens.usesDarkChrome
                        ? Brightness.dark
                        : theme.brightness,
                    onPressed: windowManager.unmaximize,
                  )
                : WindowCaptionButton.maximize(
                    brightness: tokens.usesDarkChrome
                        ? Brightness.dark
                        : theme.brightness,
                    onPressed: windowManager.maximize,
                  ),
            WindowCaptionButton.close(
              brightness:
                  tokens.usesDarkChrome ? Brightness.dark : theme.brightness,
              onPressed: windowManager.close,
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
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return WindowsNeoHoverHalo(
      borderRadius: tokens.actionRadius,
      child: SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          tooltip: tooltip,
          iconSize: 18,
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
  final WindowsVideoTabItem activeTab;
  final VoidCallback onNavigate;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.navigationSurface,
        boxShadow: [
          BoxShadow(
            color: tokens.accent.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: SizedBox(
        width: mode.sidebarWidth,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showArtwork =
                  mode.showLabels && constraints.maxHeight >= 680;
              return Column(
                children: [
                  Expanded(
                    child: Obx(
                      () => ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          for (var index = 0;
                              index < mainController.navigationBars.length;
                              index++)
                            _WindowsNeoNavItem(
                              label: _labelForNavigation(
                                mainController.navigationBars[index],
                              ),
                              icon: _iconForNavigation(
                                mainController.navigationBars[index],
                              ),
                              selected: activeTab.isHome &&
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
                          const SizedBox(height: 12),
                          Divider(
                            height: 1,
                            thickness: 1.2,
                            color: tokens.border.withValues(alpha: 0.95),
                          ),
                          const SizedBox(height: 12),
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
                    const SizedBox(height: 10),
                  ],
                  if (mode.showLabels) const _WindowsNeoSidebarSignature(),
                  if (mode.showLabels) const SizedBox(height: 8),
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
  }) =>
      _WindowsNeoNavItem(
        label: label,
        icon: icon,
        selected: activeTab.type == WindowsMediaTabType.tool &&
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
    final foreground =
        selected ? tokens.navigationForeground : tokens.navigationMuted;
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
                            style: Theme.of(
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
                      tokens.family == WindowsNeoThemeFamily.miku ? 2 : 0,
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
    final asset = tokens.family.backdropAsset;
    if (asset != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: 0.72,
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
                  tokens.chromeSurface.withValues(alpha: 0.84),
                  tokens.chromeSurface.withValues(alpha: 0.46),
                  tokens.chromeSurface.withValues(alpha: 0.12),
                ],
                stops: const [0, 0.46, 1],
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
                  ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 11,
            child: Text(
              tokens.shellWordmark,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                  ),
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
          height: 108,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: tokens.border.withValues(alpha: 0.78),
                ),
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 8,
                  top: 8,
                  child: Text(
                    '01',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: tokens.accent.withValues(alpha: 0.18),
                          fontWeight: FontWeight.w800,
                          height: 0.9,
                          letterSpacing: 1,
                        ),
                  ),
                ),
                Positioned(
                  left: 10,
                  bottom: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 3,
                        height: 28,
                        color: tokens.accent.withValues(alpha: 0.72),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tokens.shellWordmark,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  color: tokens.navigationForeground.withValues(
                                    alpha: 0.70,
                                  ),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.5,
                                ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            tokens.shellSubmark,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: tokens.navigationMuted,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowsNeoTabStrip extends StatelessWidget {
  const _WindowsNeoTabStrip({
    required this.tabs,
    required this.activeId,
    required this.onSearch,
    required this.onSplit,
  });

  final List<WindowsVideoTabItem> tabs;
  final String activeId;
  final VoidCallback onSearch;
  final VoidCallback onSplit;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background,
        boxShadow: [
          BoxShadow(
            color: tokens.accent.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SizedBox(
        height: 42,
        child: Stack(
          children: [
            const Positioned(
              left: 8,
              right: 48,
              bottom: 3,
              child: WindowsNeoRhythmRail(),
            ),
            Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
                    itemCount: tabs.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 4),
                    itemBuilder: (context, index) {
                      final item = tabs[index];
                      return _WindowsNeoTabPresence(
                        key: ValueKey(item.id),
                        item: item,
                        active: item.id == activeId,
                      );
                    },
                  ),
                ),
                const _WindowsNeoRecentTabsMenu(),
                WindowsNeoHoverHalo(
                  borderRadius: tokens.actionRadius,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      tooltip: '\u5206\u5c4f\u64ad\u653e',
                      iconSize: 18,
                      onPressed: onSplit,
                      icon: const Icon(Icons.splitscreen_outlined),
                    ),
                  ),
                ),
                WindowsNeoHoverHalo(
                  borderRadius: tokens.actionRadius,
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: IconButton(
                      tooltip: '新建搜索',
                      iconSize: 18,
                      onPressed: onSearch,
                      icon: const Icon(Icons.add),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowsNeoTabPresence extends StatefulWidget {
  const _WindowsNeoTabPresence({
    super.key,
    required this.item,
    required this.active,
  });

  final WindowsVideoTabItem item;
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
    if (widget.item.isHome || _closing) return;
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
  const _WindowsNeoRecentTabsMenu();

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final tabs = WindowsVideoTabService.recentlyClosedTabs.reversed
        .take(8)
        .toList(growable: false);
    return PopupMenuButton<String>(
      tooltip: '最近关闭的标签页',
      enabled: tabs.isNotEmpty,
      icon: Icon(
        Icons.history_rounded,
        size: 18,
        color:
            tabs.isEmpty ? tokens.muted.withValues(alpha: 0.42) : tokens.muted,
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

  final WindowsVideoTabItem item;
  final bool active;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final foreground = active ? tokens.ink : tokens.muted;
    return Listener(
      onPointerDown: (event) {
        if (event.buttons == kMiddleMouseButton && !item.isHome) {
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
              maxWidth: 240,
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
                      color: active
                          ? null
                          : tokens.surface.withValues(alpha: 0.34),
                      gradient: active ? tokens.workspaceTabGradient : null,
                      borderRadius: tokens.workspaceTabRadius,
                      border: Border.all(
                        color: active
                            ? tokens.accent.withValues(alpha: 0.58)
                            : tokens.border.withValues(alpha: 0.72),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: tokens.workspaceTabRadius,
                      child: InkWell(
                        borderRadius: tokens.workspaceTabRadius,
                        hoverColor: tokens.hover,
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
                                size: 16,
                                color: active ? tokens.accent : foreground,
                              ),
                              const SizedBox(width: 7),
                              if (WindowsVideoTabService.isPinned(item.id)) ...[
                                Icon(
                                  Icons.push_pin_rounded,
                                  size: 13,
                                  color: tokens.accent,
                                ),
                                const SizedBox(width: 5),
                              ],
                              Flexible(
                                child: Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                        color: foreground,
                                        fontWeight: active
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                      ),
                                ),
                              ),
                              if (item.isHeavyMedia)
                                Obx(
                                  () {
                                    final audible = WindowsVideoTabService
                                        .isTabAudioEnabled(item.id);
                                    return SizedBox(
                                      width: 28,
                                      height: 28,
                                      child: IconButton(
                                        tooltip: audible ? '移出混音' : '加入混音',
                                        padding: EdgeInsets.zero,
                                        iconSize: 14,
                                        color: audible
                                            ? tokens.accent
                                            : foreground,
                                        style: audible
                                            ? IconButton.styleFrom(
                                                backgroundColor: tokens.accent
                                                    .withValues(alpha: 0.12),
                                              )
                                            : null,
                                        onPressed: () => WindowsVideoTabService
                                            .setTabAudioEnabled(
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
                              if (!item.isHome)
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
        if (!item.isHome)
          PopupMenuItem(
            value: 'pin',
            child: Text(
              WindowsVideoTabService.isPinned(item.id) ? '取消固定' : '固定标签',
            ),
          ),
        if (item.isHeavyMedia)
          PopupMenuItem(
            value: 'audio',
            child: Text(
              WindowsVideoTabService.isTabAudioEnabled(item.id)
                  ? '移出混音'
                  : '加入混音',
            ),
          ),
        if (!item.isHome)
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

  static IconData _iconForItem(WindowsVideoTabItem item) => switch (item.type) {
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
