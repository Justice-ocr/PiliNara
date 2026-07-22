import 'package:PiliPlus/pages/download/view.dart';
import 'package:PiliPlus/pages/article/view.dart';
import 'package:PiliPlus/pages/dynamics_detail/view.dart';
import 'package:PiliPlus/pages/live_room/view.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/main/view.dart';
import 'package:PiliPlus/pages/member/view.dart';
import 'package:PiliPlus/pages/search/view.dart';
import 'package:PiliPlus/pages/search_result/view.dart';
import 'package:PiliPlus/pages/setting/view.dart';
import 'package:PiliPlus/pages/video/view.dart';
import 'package:PiliPlus/pages/whisper/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/shell/windows_neo_shell.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class WindowsMediaTabsPage extends StatefulWidget {
  const WindowsMediaTabsPage({super.key});

  @override
  State<WindowsMediaTabsPage> createState() => _WindowsMediaTabsPageState();
}

class _WindowsMediaTabsPageState extends State<WindowsMediaTabsPage> {
  late final MainController _mainController;

  @override
  void initState() {
    super.initState();
    _mainController = Get.isRegistered<MainController>()
        ? Get.find<MainController>()
        : Get.put(MainController());
    WindowsVideoTabService.ensureHomeTab();
    WindowsVideoTabService.setHostMounted(true);
  }

  @override
  void dispose() {
    WindowsVideoTabService.setHostMounted(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabs = WindowsVideoTabService.tabs.toList(growable: false);
      if (tabs.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            WindowsVideoTabService.ensureHomeTab();
          }
        });
        return const Scaffold(body: SizedBox.shrink());
      }

      final ids = tabs.map((item) => item.id).toSet();
      WindowsVideoTabService.retainNavigatorKeys(ids);

      var activeIndex = tabs.indexWhere(
        (item) => item.id == WindowsVideoTabService.activeId.value,
      );
      if (activeIndex == -1) {
        activeIndex = tabs.length - 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && tabs.isNotEmpty) {
            WindowsVideoTabService.select(tabs[activeIndex].id);
          }
        });
      }

      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyW, control: true):
              WindowsVideoTabService.closeActiveTab,
          const SingleActivator(LogicalKeyboardKey.tab, control: true): () =>
              WindowsVideoTabService.selectRelative(1),
          const SingleActivator(
            LogicalKeyboardKey.tab,
            control: true,
            shift: true,
          ): () =>
              WindowsVideoTabService.selectRelative(-1),
          const SingleActivator(LogicalKeyboardKey.arrowLeft, alt: true):
              WindowsVideoTabService.popActiveTab,
        },
        child: Focus(
          // Active media pages own keyboard focus. Keeping a focusable shell
          // here prevents PlayerFocus from receiving video shortcuts.
          canRequestFocus: false,
          child: WindowsNeoShell(
            mainController: _mainController,
            tabs: tabs,
            activeTab: tabs[activeIndex],
            child: WindowsMediaTabStack(
              tabs: tabs,
              activeIndex: activeIndex,
              tabBuilder: _buildTabNavigator,
            ),
          ),
        ),
      );
    });
  }

  Widget _buildTabNavigator(WindowsVideoTabItem item) {
    final key = WindowsVideoTabService.navigatorKeyFor(item.id);
    return Navigator(
      key: key,
      onGenerateRoute: (settings) => _buildRoute(item, settings),
    );
  }

  Route<dynamic> _buildRoute(
    WindowsVideoTabItem item,
    RouteSettings settings,
  ) {
    if (settings.name != null && settings.name != '/') {
      final data = settings.arguments as WindowsTabRouteData?;
      return GetPageRoute(
        settings: settings,
        page: () => switch (settings.name) {
          '/search' => SearchPage(parameters: data?.parameters),
          '/member' => MemberPage(
            mid: int.tryParse(data?.parameters['mid'] ?? ''),
            fromViewAid: data?.parameters['from_view_aid'],
            controllerTag: '${item.id}:member:${data?.parameters['mid'] ?? ''}',
          ),
          '/dynamicDetail' => DynamicDetailPage(
            arguments: data?.arguments as Map?,
            controllerTag: '${item.id}:dynamic:${_dynamicId(data?.arguments)}',
          ),
          '/articlePage' => ArticlePage(
            parameters: data?.parameters,
            controllerTag:
                '${item.id}:article:${data?.parameters['type'] ?? ''}:'
                '${data?.parameters['id'] ?? ''}',
          ),
          _ => _UnknownWindowsTabRoute(routeName: settings.name!),
        },
      );
    }

    return GetPageRoute(
      settings: RouteSettings(
        name: _rootRouteName(item),
        arguments: item.arguments,
      ),
      page: () => _buildRootPage(item),
    );
  }

  String _rootRouteName(WindowsVideoTabItem item) => switch (item.type) {
    WindowsMediaTabType.home => '/',
    WindowsMediaTabType.search => '/searchResult',
    WindowsMediaTabType.live => '/liveRoom',
    WindowsMediaTabType.video => '/videoV',
    WindowsMediaTabType.member => '/member',
    WindowsMediaTabType.dynamic => '/dynamicDetail',
    WindowsMediaTabType.tool => item.arguments['tabRoute'] as String,
  };

  Widget _buildRootPage(WindowsVideoTabItem item) => switch (item.type) {
    WindowsMediaTabType.home => MainApp(
      controller: _mainController,
      showNavigation: false,
    ),
    WindowsMediaTabType.search => SearchResultPage(arguments: item.arguments),
    WindowsMediaTabType.live => LiveRoomPage(arguments: item.arguments),
    WindowsMediaTabType.video => VideoDetailPageV(arguments: item.arguments),
    WindowsMediaTabType.member => MemberPage(
      mid: int.tryParse(item.arguments['mid']?.toString() ?? ''),
      fromViewAid: item.arguments['from_view_aid']?.toString(),
      controllerTag: item.id,
    ),
    WindowsMediaTabType.dynamic => DynamicDetailPage(
      arguments: item.arguments,
      controllerTag: item.id,
    ),
    WindowsMediaTabType.tool => switch (item.arguments['tabRoute']) {
      '/download' => const DownloadPage(),
      '/whisper' => const WhisperPage(),
      '/setting' => const SettingPage(),
      final route => _UnknownWindowsTabRoute(
        routeName: route?.toString() ?? '',
      ),
    },
  };

  String _dynamicId(Object? arguments) {
    if (arguments is Map) {
      return arguments['item']?.idStr.toString() ?? '';
    }
    return '';
  }
}

class WindowsMediaTabStack extends StatelessWidget {
  const WindowsMediaTabStack({
    super.key,
    required this.tabs,
    required this.activeIndex,
    required this.tabBuilder,
  });

  final List<WindowsVideoTabItem> tabs;
  final int activeIndex;
  final Widget Function(WindowsVideoTabItem item) tabBuilder;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: activeIndex,
      children: [
        for (var index = 0; index < tabs.length; index++)
          WindowsNeoPageStage(
            key: ValueKey(tabs[index].id),
            active: index == activeIndex,
            child: ExcludeFocus(
              excluding: index != activeIndex,
              child: RepaintBoundary(child: tabBuilder(tabs[index])),
            ),
          ),
      ],
    );
  }
}

class _UnknownWindowsTabRoute extends StatelessWidget {
  const _UnknownWindowsTabRoute({required this.routeName});

  final String routeName;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('页面不可用')),
    body: Center(child: Text('未注册的标签页路由: $routeName')),
  );
}
