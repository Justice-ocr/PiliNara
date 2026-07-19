import 'package:PiliPlus/common/constants.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_hover_halo.dart';
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
  });

  final MainController mainController;
  final List<WindowsVideoTabItem> tabs;
  final WindowsVideoTabItem activeTab;
  final Widget child;

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
  Widget build(BuildContext context) {
    final neoTheme = WindowsNeoTheme.apply(Theme.of(context));
    return Theme(
      data: neoTheme,
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
        color: tokens.sidebar,
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
              color: tokens.border.withValues(alpha: 0.95),
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
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: mode == WindowsNeoLayoutMode.expanded
                      ? Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Text(
                            'Windows 工作区',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: tokens.muted,
                            ),
                          ),
                        )
                      : const SizedBox.expand(),
                ),
              ),
            ),
            WindowCaptionButton.minimize(
              brightness: theme.brightness,
              onPressed: windowManager.minimize,
            ),
            isMaximized
                ? WindowCaptionButton.unmaximize(
                    brightness: theme.brightness,
                    onPressed: windowManager.unmaximize,
                  )
                : WindowCaptionButton.maximize(
                    brightness: theme.brightness,
                    onPressed: windowManager.maximize,
                  ),
            WindowCaptionButton.close(
              brightness: theme.brightness,
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
  Widget build(BuildContext context) => WindowsNeoHoverHalo(
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        tooltip: tooltip,
        iconSize: 18,
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    ),
  );
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
        color: tokens.sidebar,
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
  }) => _WindowsNeoNavItem(
    label: label,
    icon: icon,
    selected:
        activeTab.type == WindowsMediaTabType.tool &&
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
    final foreground = selected ? Colors.white : tokens.muted;
    final radius = BorderRadius.circular(tokens.radiusSm);
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
                        'MIKU',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.15),
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
                        ? Colors.white.withValues(alpha: 0.88)
                        : tokens.accent,
                    borderRadius: BorderRadius.circular(2),
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
    final radius = BorderRadius.circular(tokens.radiusSm);
    return IgnorePointer(
      child: SizedBox(
        height: 120,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: tokens.accentBannerGradient,
            borderRadius: radius,
            border: Border.all(
              color: tokens.accent.withValues(alpha: 0.34),
            ),
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
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
                    '39',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0,
                    ),
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
                            'MIKU',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: tokens.ink.withValues(alpha: 0.64),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.5,
                                ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '39',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: tokens.muted,
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
  });

  final List<WindowsVideoTabItem> tabs;
  final String activeId;
  final VoidCallback onSearch;

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
        child: Row(
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
            WindowsNeoHoverHalo(
              borderRadius: BorderRadius.circular(8),
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
        child: _WindowsNeoTab(
          item: widget.item,
          active: widget.active,
          onClose: _close,
        ),
      ),
    );
  }
}

class _WindowsNeoTab extends StatelessWidget {
  const _WindowsNeoTab({
    required this.item,
    required this.active,
    required this.onClose,
  });

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
            constraints: const BoxConstraints(minWidth: 116, maxWidth: 240),
            child: WindowsNeoHoverHalo(
              borderRadius: BorderRadius.circular(6),
              enabled: !active,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  AnimatedContainer(
                    duration: context.windowsNeoDuration(tokens.motionFast),
                    curve: Curves.easeOutCubic,
                    decoration: BoxDecoration(
                      color: active
                          ? tokens.surface
                          : tokens.surface.withValues(alpha: 0.34),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: active
                            ? tokens.accent.withValues(alpha: 0.58)
                            : tokens.border.withValues(alpha: 0.72),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(6),
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
                    child: AnimatedContainer(
                      duration: context.windowsNeoDuration(tokens.motionFast),
                      curve: Curves.easeOutCubic,
                      width: active ? 34 : 0,
                      height: 2,
                      decoration: BoxDecoration(
                        color: tokens.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
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
          const PopupMenuItem(value: 'close', child: Text('关闭标签页')),
        const PopupMenuItem(value: 'others', child: Text('关闭其他标签页')),
      ],
    );
    if (action == 'close') {
      await onClose();
    } else if (action == 'others') {
      final ids = WindowsVideoTabService.tabs
          .where((tab) => !tab.isHome && tab.id != item.id)
          .map((tab) => tab.id)
          .toList(growable: false);
      for (final id in ids) {
        WindowsVideoTabService.close(id);
      }
      WindowsVideoTabService.select(item.id);
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
