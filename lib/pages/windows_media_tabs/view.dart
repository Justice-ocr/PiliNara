import 'package:PiliPlus/pages/download/view.dart';
import 'package:PiliPlus/pages/fav/view.dart';
import 'package:PiliPlus/pages/fav_detail/view.dart';
import 'package:PiliPlus/pages/fav_search/view.dart';
import 'package:PiliPlus/pages/history/view.dart';
import 'package:PiliPlus/pages/history_search/view.dart';
import 'package:PiliPlus/pages/later/view.dart';
import 'package:PiliPlus/pages/later_search/view.dart';
import 'package:PiliPlus/pages/article/view.dart';
import 'package:PiliPlus/pages/article_list/view.dart';
import 'package:PiliPlus/pages/blacklist/view.dart';
import 'package:PiliPlus/pages/dynamics_detail/view.dart';
import 'package:PiliPlus/pages/dynamics_topic/view.dart';
import 'package:PiliPlus/pages/live_room/view.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/main/view.dart';
import 'package:PiliPlus/pages/member/view.dart';
import 'package:PiliPlus/pages/member_dynamics/view.dart';
import 'package:PiliPlus/pages/fan/view.dart';
import 'package:PiliPlus/pages/follow/view.dart';
import 'package:PiliPlus/pages/follow_search/view.dart';
import 'package:PiliPlus/pages/follow_type/followed/view.dart';
import 'package:PiliPlus/pages/follow_type/follow_same/view.dart';
import 'package:PiliPlus/pages/member_profile/view.dart';
import 'package:PiliPlus/pages/member_search/view.dart';
import 'package:PiliPlus/pages/my_reply/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/at_me/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/like_me/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/like_detail/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/reply_me/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/sys_msg/view.dart';
import 'package:PiliPlus/pages/popular_precious/view.dart';
import 'package:PiliPlus/pages/popular_series/view.dart';
import 'package:PiliPlus/pages/rank/view.dart';
import 'package:PiliPlus/pages/search/view.dart';
import 'package:PiliPlus/pages/search_result/view.dart';
import 'package:PiliPlus/pages/search_trending/view.dart';
import 'package:PiliPlus/pages/setting/ai_setting/view.dart';
import 'package:PiliPlus/pages/setting/block_setting.dart';
import 'package:PiliPlus/pages/setting/pages/bar_set.dart';
import 'package:PiliPlus/pages/setting/pages/color_select.dart';
import 'package:PiliPlus/pages/setting/pages/font_size_select.dart';
import 'package:PiliPlus/pages/setting/pages/play_speed_set.dart';
import 'package:PiliPlus/pages/setting/view.dart';
import 'package:PiliPlus/pages/space_setting/view.dart';
import 'package:PiliPlus/pages/sponsor_block/view.dart';
import 'package:PiliPlus/pages/subscription/view.dart';
import 'package:PiliPlus/pages/subscription_detail/view.dart';
import 'package:PiliPlus/pages/video/view.dart';
import 'package:PiliPlus/pages/webview/view.dart';
import 'package:PiliPlus/pages/whisper/view.dart';
import 'package:PiliPlus/pages/whisper_detail/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_back_shortcut_listener.dart';
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

      return WindowsBackShortcutListener(
        onBack: WindowsVideoTabService.popActiveTab,
        onCloseTab: WindowsVideoTabService.closeActiveTab,
        onNextTab: () => WindowsVideoTabService.selectRelative(1),
        onPreviousTab: () => WindowsVideoTabService.selectRelative(-1),
        onRestoreTab: WindowsVideoTabService.restoreLastClosedTab,
        onSearch: () {
          WindowsVideoTabService.select(WindowsVideoTabService.homeTabId);
          PageUtils.toSearch();
        },
        child: CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.escape):
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
              onSplit: _showSplitSelection,
              child: Obx(
                () => WindowsMediaTabStack(
                  tabs: tabs,
                  activeIndex: activeIndex,
                  tabBuilder: _buildTabNavigator,
                ),
              ),
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

  void _showSplitSelection() {
    WindowsVideoTabService.beginSplitSelection();
    var applied = false;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Obx(() {
        final candidates = WindowsVideoTabService.tabs
            .where(WindowsVideoTabService.isSplitCandidate)
            .toList(growable: false);
        final canApply = WindowsVideoTabService.canApplySplitSelection;
        return AlertDialog(
          title: const Text('选择分屏标签'),
          content: SizedBox(
            width: 440,
            child: candidates.isEmpty
                ? const Center(child: Text('请先打开视频或直播标签'))
                : ListView(
                    shrinkWrap: true,
                    children: [
                      for (final item in candidates)
                        CheckboxListTile(
                          value: WindowsVideoTabService.splitDraftTabIds
                              .contains(item.id),
                          dense: true,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(item.type == WindowsMediaTabType.live
                              ? '直播'
                              : '视频'),
                          onChanged: (value) {
                            if (value != null) {
                              WindowsVideoTabService.toggleSplitDraft(item.id);
                            }
                          },
                        ),
                    ],
                  ),
          ),
          actions: [
            if (WindowsVideoTabService.isSplitActive)
              TextButton(
                onPressed: () {
                  WindowsVideoTabService.exitSplit();
                  applied = true;
                  Navigator.of(context).pop();
                },
                child: const Text('退出分屏'),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: canApply
                  ? () {
                      applied = WindowsVideoTabService.applySplitSelection();
                      if (applied) Navigator.of(context).pop();
                    }
                  : null,
              child: Text(
                '开始分屏${WindowsVideoTabService.splitDraftTabIds.length}/4',
              ),
            ),
          ],
        );
      }),
    ).whenComplete(() {
      if (!applied) WindowsVideoTabService.cancelSplitSelection();
    });
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
          '/searchTrending' => SearchTrendingPage(
            controllerTag: '${item.id}:searchTrending',
          ),
          '/member' => MemberPage(
            mid: int.tryParse(data?.parameters['mid'] ?? ''),
            fromViewAid: data?.parameters['from_view_aid'],
            controllerTag: '${item.id}:member:${data?.parameters['mid'] ?? ''}',
          ),
          '/memberSearch' => MemberSearchPage(parameters: data?.parameters),
          '/editProfile' => const EditProfilePage(),
          '/spaceSetting' => const SpaceSettingPage(),
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
          '/articleList' => ArticleListPage(parameters: data?.parameters),
          '/dynTopic' => DynTopicPage(parameters: data?.parameters),
          '/blockSetting' => const BlockSetting(),
          '/blackListPage' => const BlackListPage(),
          '/sponsorBlock' => const SponsorBlockPage(),
          '/aiSetting' => const AiSettingPage(),
          '/playSpeedSet' => const PlaySpeedPage(),
          '/colorSetting' => const ColorSelectPage(),
          '/fontSizeSetting' => const FontSizeSelectPage(),
          '/barSetting' => BarSetPage(arguments: data?.arguments as Map?),
          '/historySearch' => const HistorySearchPage(),
          '/laterSearch' => LaterSearchPage(
            arguments: data?.arguments as Map?,
          ),
          '/favDetail' => FavDetailPage(
            parameters: data?.parameters,
            controllerTag:
                '${item.id}:favDetail:${data?.parameters['mediaId'] ?? ''}',
          ),
          '/favSearch' => FavSearchPage(
            arguments: data?.arguments as Map?,
          ),
          '/popularSeries' => const PopularSeriesPage(),
          '/popularPrecious' => const PopularPreciousPage(),
          '/rank' => const _WindowsRankRoute(),
          '/whisperDetail' => WhisperDetailPage(
            arguments: data?.arguments as Map?,
            controllerTag:
                '${item.id}:whisper:${(data?.arguments as Map?)?['talkerId'] ?? ''}',
          ),
          '/replyMe' => const ReplyMePage(),
          '/atMe' => const AtMePage(),
          '/likeMe' => const LikeMePage(),
          '/sysMsg' => const SysMsgPage(),
          '/webview' => WebviewPage(
            parameters: data?.parameters,
            arguments: data?.arguments as Map?,
          ),
          '/subDetail' => SubDetailPage(
            arguments: data?.arguments as Map?,
            controllerTag:
                '${item.id}:subscription:${(data?.arguments as Map?)?['id'] ?? ''}',
          ),
          '/msgLikeDetail' => LikeDetailPage(
            arguments: data?.arguments as Map?,
          ),
          '/memberDynamics' => MemberDynamicsPage(
            mid: int.tryParse(data?.parameters['mid'] ?? ''),
            controllerTag: '${item.id}:memberDynamics',
          ),
          '/follow' => FollowPage(
            arguments: data?.arguments as Map?,
            controllerTag: '${item.id}:follow',
          ),
          '/fan' => FansPage(
            arguments: data?.arguments as Map?,
            controllerTag: '${item.id}:fan',
          ),
          '/followSearch' => FollowSearchPage(
            mid: int.tryParse(
              data?.parameters['mid'] ??
                  (data?.arguments as Map?)?['mid']?.toString() ??
                  '',
            ),
            controllerTag: '${item.id}:followSearch',
          ),
          '/followed' => FollowedPage(
            arguments: data?.arguments as Map?,
            controllerTag: '${item.id}:followed',
          ),
          '/sameFollowing' => FollowSamePage(
            arguments: data?.arguments as Map?,
            controllerTag: '${item.id}:sameFollowing',
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
      '/fav' => FavPage(arguments: item.arguments['workspaceArguments']),
      '/history' => const HistoryPage(),
      '/later' => const LaterPage(),
      '/myReply' => const MyReply(),
      '/whisper' => const WhisperPage(),
      '/setting' => const SettingPage(),
      '/subscription' => const SubPage(),
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

class _WindowsRankRoute extends StatelessWidget {
  const _WindowsRankRoute();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('\u6392\u884c\u699c')),
    body: const RankPage(),
  );
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
    if (WindowsVideoTabService.isSplitActive) {
      final splitTabs = WindowsVideoTabService.splitTabs;
      final selectedIds = splitTabs.map((item) => item.id).toSet();
      final panes = [
        for (final item in splitTabs) _buildSplitPane(context, item),
      ];
      return Stack(
        fit: StackFit.expand,
        children: [
          _buildSplitLayout(panes),
          for (final item in tabs)
            if (!selectedIds.contains(item.id))
              Offstage(
                offstage: true,
                child: _buildStage(item, visible: false, focused: false),
              ),
        ],
      );
    }
    return IndexedStack(
      index: activeIndex,
      children: [
        for (var index = 0; index < tabs.length; index++)
          _buildStage(
            tabs[index],
            visible: index == activeIndex,
            focused: index == activeIndex,
          ),
      ],
    );
  }

  Widget _buildStage(
    WindowsVideoTabItem item, {
    required bool visible,
    required bool focused,
  }) => WindowsNeoPageStage(
    key: ValueKey(item.id),
    active: focused,
    visible: visible,
    focused: focused,
    child: RepaintBoundary(child: tabBuilder(item)),
  );

  Widget _buildSplitPane(BuildContext context, WindowsVideoTabItem item) {
    final focused = item.id == WindowsVideoTabService.activeId.value;
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => WindowsVideoTabService.focusSplitTab(item.id),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: focused
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.72)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.28),
            width: focused ? 2 : 1,
          ),
        ),
        child: _buildStage(item, visible: true, focused: focused),
      ),
    );
  }

  Widget _buildSplitLayout(List<Widget> panes) {
    return switch (panes.length) {
      2 => Row(
          children: [
            Expanded(child: panes[0]),
            const VerticalDivider(width: 1),
            Expanded(child: panes[1]),
          ],
        ),
      3 => Row(
          children: [
            Expanded(child: panes[0]),
            const VerticalDivider(width: 1),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: panes[1]),
                  const Divider(height: 1),
                  Expanded(child: panes[2]),
                ],
              ),
            ),
          ],
        ),
      _ => Column(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(child: panes[0]),
                  const VerticalDivider(width: 1),
                  Expanded(child: panes[1]),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Row(
                children: [
                  Expanded(child: panes[2]),
                  const VerticalDivider(width: 1),
                  Expanded(child: panes[3]),
                ],
              ),
            ),
          ],
        ),
    };
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
