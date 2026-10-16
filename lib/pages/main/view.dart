import 'dart:io';

import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/floating_navigation_bar.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/flutter/tabs.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/route_aware_mixin.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/android/bindings.g.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/desktop/tray_controller.dart';
import 'package:PiliPlus/utils/desktop/window_controller.dart';
import 'package:PiliPlus/utils/extension/context_ext.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/mobile_observer.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:get/get.dart';
import 'package:nativeapi/nativeapi.dart' as nativeapi;

class MainApp extends StatefulWidget {
  const MainApp({
    super.key,
    this.controller,
    this.showNavigation = true,
  });

  final MainController? controller;
  final bool showNavigation;

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends PopScopeState<MainApp>
    with RouteAware, RouteAwareMixin, WidgetsBindingObserver {
  late final MainController _mainController;
  late EdgeInsets _padding;
  late ThemeData theme;
  Brightness? _brightness;

  @override
  bool get initCanPop => false;

  @override
  void initState() {
    _mainController =
        widget.controller ??
        (Get.isRegistered<MainController>()
            ? Get.find<MainController>()
            : Get.put(MainController()));
    super.initState();
    addObserverMobile(this);
    if (PlatformUtils.isDesktop) {
      WindowController.instance.init();
      TrayController.instance.init();
    }
    if (!Platform.isMacOS) {
      PiliScheme.init();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _padding = MediaQuery.viewPaddingOf(context);
    theme = Theme.of(context);
    final brightness = theme.brightness;
    NetworkImgLayer.reduce =
        NetworkImgLayer.reduceLuxColor != null && brightness.isDark;
    if (PlatformUtils.isDesktop) {
      if (_brightness != brightness) {
        _brightness = brightness;
        nativeapi.Application.instance.setBrightness(
          brightness == .dark ? .dark : .light,
        );
      }
    }
    if (!_mainController.useSideBar) {
      final size = MediaQuery.sizeOf(context);
      if (Pref.autoSideBar) {
        _mainController.useBottomNav = size.width < Pref.sideBarThreshold;
      } else {
        _mainController.useBottomNav = size.isPortrait;
      }
    }
  }

  @override
  void didPopNext() {
    addObserverMobile(this);
    _mainController
      ..checkUnreadDynamic()
      ..checkDefaultSearch(true)
      ..checkUnread(_mainController.useBottomNav);
    super.didPopNext();
  }

  @override
  void didPushNext() {
    removeObserverMobile(this);
    super.didPushNext();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _mainController
        ..checkUnreadDynamic()
        ..checkDefaultSearch(true)
        ..checkUnread(_mainController.useBottomNav);
    }
  }

  @override
  void dispose() {
    if (PlatformUtils.isDesktop) {
      WindowController.instance.dispose();
      TrayController.instance.dispose();
    }
    removeObserverMobile(this);
    PiliScheme.listener?.cancel();
    GStorage.close();
    super.dispose();
  }

  @pragma('vm:prefer-inline')
  static void _onBack() {
    if (Platform.isAndroid) {
      AndroidHelper.back();
    }
  }

  @override
  void onPopInvokedWithResult(bool didPop, Object? result) {
    if (_mainController.directExitOnBack) {
      _onBack();
    } else {
      if (_mainController.selectedIndex.value != 0) {
        _mainController
          ..setIndex(0)
          ..barOffset?.value = 0.0
          ..showBottomBar?.value = true
          ..setSearchBar();
      } else {
        _onBack();
      }
    }
  }

  Widget? get _bottomNav {
    Widget? bottomNav;
    if (_mainController.navigationBars.length > 1) {
      if (_mainController.floatingNavBar) {
        bottomNav = Obx(
          () => FloatingNavigationBar(
            onDestinationSelected: _mainController.setIndex,
            selectedIndex: _mainController.selectedIndex.value,
            destinations: _mainController.navigationBars
                .map(
                  (e) => FloatingNavigationDestination(
                    label: e.label,
                    icon: _buildIcon(type: e),
                    selectedIcon: _buildIcon(type: e, selected: true),
                  ),
                )
                .toList(),
          ),
        );
      } else if (_mainController.enableMYBar) {
        bottomNav = Obx(
          () => NavigationBar(
            maintainBottomViewPadding: true,
            onDestinationSelected: _mainController.setIndex,
            selectedIndex: _mainController.selectedIndex.value,
            destinations: _mainController.navigationBars
                .map(
                  (e) => NavigationDestination(
                    label: e.label,
                    icon: _buildIcon(type: e),
                    selectedIcon: _buildIcon(type: e, selected: true),
                  ),
                )
                .toList(),
          ),
        );
      } else {
        bottomNav = Obx(
          () => BottomNavigationBar(
            currentIndex: _mainController.selectedIndex.value,
            onTap: _mainController.setIndex,
            iconSize: 16,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: .fixed,
            items: _mainController.navigationBars
                .map(
                  (e) => BottomNavigationBarItem(
                    label: e.label,
                    icon: _buildIcon(type: e),
                    activeIcon: _buildIcon(type: e, selected: true),
                  ),
                )
                .toList(),
          ),
        );
      }

      if (_mainController.hideBottomBar) {
        if (_mainController.barOffset case final barOffset?) {
          return Obx(
            () => FractionalTranslation(
              translation: Offset(
                0.0,
                barOffset.value / Style.topBarHeight,
              ),
              child: bottomNav,
            ),
          );
        }
        if (_mainController.showBottomBar case final showBottomBar?) {
          return Obx(
            () => AnimatedSlide(
              curve: Curves.easeInOutCubicEmphasized,
              duration: const Duration(milliseconds: 500),
              offset: Offset(0, showBottomBar.value ? 0 : 1),
              child: bottomNav,
            ),
          );
        }
      }
    }

    return bottomNav;
  }

  Widget _sideBar(ThemeData theme) {
    return _mainController.navigationBars.length > 1
        ? context.isTablet && _mainController.optTabletNav
              ? Column(
                  children: [
                    const SizedBox(height: 25),
                    userAndSearchVertical(theme),
                    const Spacer(flex: 2),
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        width: 130,
                        child: Obx(
                          () => NavigationDrawer(
                            backgroundColor: Colors.transparent,
                            tilePadding: const .symmetric(
                              vertical: 5,
                              horizontal: 12,
                            ),
                            indicatorShape: const RoundedRectangleBorder(
                              borderRadius: .all(.circular(16)),
                            ),
                            onDestinationSelected: _mainController.setIndex,
                            selectedIndex: _mainController.selectedIndex.value,
                            children: _mainController.navigationBars
                                .map(
                                  (e) => NavigationDrawerDestination(
                                    label: Text(e.label),
                                    icon: _buildIcon(type: e),
                                    selectedIcon: _buildIcon(
                                      type: e,
                                      selected: true,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Obx(
                  () => NavigationRail(
                    groupAlignment: 0.5,
                    selectedIndex: _mainController.selectedIndex.value,
                    onDestinationSelected: _mainController.setIndex,
                    labelType: .selected,
                    leading: userAndSearchVertical(theme),
                    destinations: _mainController.navigationBars
                        .map(
                          (e) => NavigationRailDestination(
                            label: Text(e.label),
                            icon: _buildIcon(type: e),
                            selectedIcon: _buildIcon(type: e, selected: true),
                          ),
                        )
                        .toList(),
                  ),
                )
        : Container(
            width: 80,
            padding: const .only(top: 10),
            child: userAndSearchVertical(theme),
          );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (WindowsVideoTabService.enabled) {
      child = Obx(() {
        final activeIndex = _mainController.selectedIndex.value;
        return IndexedStack(
          index: activeIndex,
          children: [
            for (
              var index = 0;
              index < _mainController.navigationBars.length;
              index++
            )
              WindowsNeoPageStage(
                active: index == activeIndex,
                child: _mainController.navigationBars[index].page,
              ),
          ],
        );
      });
    } else if (_mainController.mainTabBarView) {
      child = CustomTabBarView(
        scrollDirection: _mainController.useBottomNav ? .horizontal : .vertical,
        physics: const NeverScrollableScrollPhysics(),
        controller: _mainController.controller,
        children: _mainController.navigationBars.map((i) => i.page).toList(),
      );
    } else {
      child = PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _mainController.controller,
        children: _mainController.navigationBars.map((i) => i.page).toList(),
      );
    }

    if (!widget.showNavigation) {
      return Scaffold(
        resizeToAvoidBottomInset: false,
        body: Padding(
          padding: EdgeInsets.only(right: _padding.right),
          child: child,
        ),
      );
    }

    Widget? bottomNav;
    if (_mainController.useBottomNav) {
      bottomNav = _bottomNav;
      child = Row(children: [Expanded(child: child)]);
    } else {
      child = Row(
        children: [
          _sideBar(theme),
          VerticalDivider(
            width: 1,
            endIndent: _padding.bottom,
            color: theme.colorScheme.outline.withValues(alpha: 0.06),
          ),
          Expanded(child: child),
        ],
      );
    }

    child = Scaffold(
      extendBody: true,
      backgroundColor: Pref.enableGradientBg ? Colors.transparent : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(toolbarHeight: 0),
      body: Padding(
        padding: EdgeInsets.only(
          left: _mainController.useBottomNav ? _padding.left : 0.0,
          right: _padding.right,
        ),
        child: child,
      ),
      bottomNavigationBar: bottomNav,
    );
    if (Pref.enableGradientBg) {
      child = Material(
        child: Stack(
          children: [
            Positioned.fill(child: _gradientBg()),
            child,
          ],
        ),
      );
    }

    if (PlatformUtils.isMobile) {
      child = AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: theme.brightness.reverse,
        ),
        child: child,
      );
    }

    return child;
  }

  Widget _gradientBg() {
    return Opacity(
      opacity: .6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary.withValues(alpha: .6),
              theme.colorScheme.primaryContainer.withValues(alpha: .6),
              theme.colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: const [.1, .4, .7],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon({required NavigationBarType type, bool selected = false}) {
    final icon = selected ? type.selectIcon : type.icon;
    return type == .dynamics
        ? Obx(
            () {
              final dynCount = _mainController.dynCount.value;
              return Badge(
                isLabelVisible: dynCount > 0,
                label: _mainController.dynamicBadgeMode == .number
                    ? Text(dynCount.toString())
                    : null,
                padding: const .symmetric(horizontal: 6),
                child: icon,
              );
            },
          )
        : icon;
  }

  Widget userAndSearchVertical(ThemeData theme) {
    return Column(
      children: [
        userAvatar(theme: theme, mainController: _mainController),
        const SizedBox(height: 8),
        msgBadge(_mainController),
        const IconButton(
          tooltip: '搜索',
          icon: Icon(
            Icons.search_outlined,
            semanticLabel: '搜索',
          ),
          onPressed: PageUtils.toSearch,
        ),
      ],
    );
  }
}
