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
import 'package:material_ui/material_ui.dart';
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
      final activeId = tabs[activeIndex].id;
      final splitTabs = WindowsVideoTabService.splitTabs;
      final maximizedSplitTab = WindowsVideoTabService.maximizedSplitTab;
      final splitHorizontalRatio =
          WindowsVideoTabService.splitHorizontalRatio.value;
      final splitVerticalRatio = WindowsVideoTabService.splitVerticalRatio.value;

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
              child: WindowsMediaTabStack(
                tabs: tabs,
                activeId: activeId,
                splitTabs: splitTabs,
                maximizedSplitTab: maximizedSplitTab,
                splitHorizontalRatio: splitHorizontalRatio,
                splitVerticalRatio: splitVerticalRatio,
                tabBuilder: _buildTabNavigator,
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
    required this.activeId,
    required this.splitTabs,
    required this.maximizedSplitTab,
    required this.splitHorizontalRatio,
    required this.splitVerticalRatio,
    required this.tabBuilder,
  });

  final List<WindowsVideoTabItem> tabs;
  final String activeId;
  final List<WindowsVideoTabItem> splitTabs;
  final String? maximizedSplitTab;
  final double splitHorizontalRatio;
  final double splitVerticalRatio;
  final Widget Function(WindowsVideoTabItem item) tabBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final isSplit = splitTabs.length >= 2;
      final geometry = isSplit ? _splitGeometry(constraints) : null;
      final splitBounds = geometry?.bounds ?? const <String, Rect>{};
      final isMaximized =
          isSplit && maximizedSplitTab != null && splitBounds.containsKey(maximizedSplitTab);
      return Stack(
        fit: StackFit.expand,
        children: [
          for (final item in tabs)
            _buildTabSlot(
              context,
              item,
              bounds: isMaximized && item.id == maximizedSplitTab
                  ? Rect.fromLTWH(0, 0, constraints.maxWidth, constraints.maxHeight)
                  : splitBounds[item.id],
              layoutVisible: isSplit
                  ? splitBounds.containsKey(item.id) &&
                        (!isMaximized || item.id == maximizedSplitTab)
                  : item.id == activeId,
              stageVisible: isSplit
                  ? splitBounds.containsKey(item.id)
                  : item.id == activeId,
              focused: item.id == activeId,
              split: isSplit,
              maximized: isMaximized && item.id == maximizedSplitTab,
            ),
          if (isSplit && !isMaximized)
            for (final divider in geometry!.dividers)
              _buildSplitDivider(context, constraints, divider),
        ],
      );
    },
  );

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

  Widget _buildTabSlot(
    BuildContext context,
    WindowsVideoTabItem item, {
    required Rect? bounds,
    required bool layoutVisible,
    required bool stageVisible,
    required bool focused,
    required bool split,
    required bool maximized,
  }) {
    final child = Offstage(
      offstage: !layoutVisible,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: split && layoutVisible
            ? (_) => WindowsVideoTabService.focusSplitTab(item.id)
            : null,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTap: split && layoutVisible
              ? () => WindowsVideoTabService.toggleSplitMaximized(item.id)
              : null,
          child: DecoratedBox(
            decoration: split && layoutVisible
              ? BoxDecoration(
                  border: Border.all(
                    color: focused
                        ? Theme.of(context).colorScheme.primary.withValues(
                            alpha: 0.72,
                          )
                        : Theme.of(context).colorScheme.outline.withValues(
                            alpha: 0.28,
                          ),
                    width: focused ? 2 : 1,
                  ),
                )
              : const BoxDecoration(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildStage(
                  item,
                  visible: stageVisible,
                  focused: focused,
                ),
                if (split && layoutVisible)
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: _buildSplitTitleBar(
                      context,
                      item,
                      focused: focused,
                      maximized: maximized,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (bounds == null) {
      return Positioned.fill(key: ValueKey(item.id), child: child);
    }
    return Positioned(
      key: ValueKey(item.id),
      left: bounds.left,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
      child: child,
    );
  }

  Widget _buildSplitTitleBar(
    BuildContext context,
    WindowsVideoTabItem item, {
    required bool focused,
    required bool maximized,
  }) {
    final colors = Theme.of(context).colorScheme;
    final muted = WindowsVideoTabService.muteStateFor(item.id);
    return Material(
      color: colors.surface.withValues(alpha: 0.94),
      child: Container(
        height: 32,
        padding: const EdgeInsets.only(left: 10, right: 2),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colors.outline.withValues(alpha: 0.24)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            Obx(
              () {
                final isMuted = muted?.value ?? false;
                return _buildSplitAction(
                  tooltip: isMuted ? '\u53d6\u6d88\u9759\u97f3' : '\u9759\u97f3',
                  icon: isMuted ? Icons.volume_off_outlined : Icons.volume_up_outlined,
                  selected: isMuted,
                  onPressed: muted == null
                      ? null
                      : () => WindowsVideoTabService.setSplitTabMuted(
                          item.id,
                          !isMuted,
                        ),
                );
              },
            ),
            Obx(
              () {
                final isAudible = WindowsVideoTabService.isSplitAudioEnabled(
                  item.id,
                );
                return _buildSplitAction(
                  tooltip: isAudible ? '移出混音' : '加入混音',
                  icon: isAudible
                      ? Icons.volume_up_rounded
                      : Icons.volume_off_outlined,
                  selected: isAudible,
                  onPressed: () =>
                      WindowsVideoTabService.setSplitTabAudioEnabled(
                        item.id,
                        !isAudible,
                      ),
                );
              },
            ),
            _buildSplitAction(
              tooltip: '\u8bbe\u4e3a\u4e3b\u97f3\u8f68',
              icon: Icons.volume_up_rounded,
              selected: focused,
              onPressed: () => WindowsVideoTabService.setSplitPrimaryAudio(item.id),
            ),
            _buildSplitAction(
              tooltip: maximized ? '\u6062\u590d\u5206\u5c4f' : '\u6700\u5927\u5316\u5f53\u524d\u7a97\u683c',
              icon: maximized ? Icons.close_fullscreen : Icons.open_in_full,
              selected: maximized,
              onPressed: () => WindowsVideoTabService.toggleSplitMaximized(item.id),
            ),
            _buildSplitAction(
              tooltip: '\u4ece\u5206\u5c4f\u79fb\u9664',
              icon: Icons.grid_view_outlined,
              onPressed: () => WindowsVideoTabService.removeFromSplit(item.id),
            ),
            _buildSplitAction(
              tooltip: '\u5173\u95ed\u6807\u7b7e',
              icon: Icons.close,
              destructive: true,
              onPressed: () => WindowsVideoTabService.close(item.id),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSplitAction({
    required String tooltip,
    required IconData icon,
    VoidCallback? onPressed,
    bool selected = false,
    bool destructive = false,
  }) => SizedBox(
    width: 28,
    height: 28,
    child: IconButton(
      tooltip: tooltip,
      iconSize: 16,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 28, height: 28),
      color: destructive ? Colors.redAccent : null,
      style: selected
          ? IconButton.styleFrom(backgroundColor: Colors.white24)
          : null,
      onPressed: onPressed,
      icon: Icon(icon),
    ),
  );

  _SplitGeometry _splitGeometry(BoxConstraints constraints) {
    const gap = 1.0;
    const minimumPaneWidth = 280.0;
    const minimumPaneHeight = 160.0;
    final width = constraints.maxWidth;
    final height = constraints.maxHeight;
    final minHorizontal = width <= 0 ? 0.5 : minimumPaneWidth / width;
    final minVertical = height <= 0 ? 0.5 : minimumPaneHeight / height;
    final horizontal = _clampRatio(
      splitHorizontalRatio,
      minHorizontal,
      1 - minHorizontal,
    );
    final vertical = _clampRatio(
      splitVerticalRatio,
      minVertical,
      1 - minVertical,
    );
    final dividerX = (width - gap) * horizontal;
    final dividerY = (height - gap) * vertical;
    final leftWidth = dividerX;
    final rightWidth = width - dividerX - gap;
    final topHeight = dividerY;
    final bottomHeight = height - dividerY - gap;
    final panes = switch (splitTabs.length) {
      2 => [
          Rect.fromLTWH(0, 0, leftWidth, height),
          Rect.fromLTWH(dividerX + gap, 0, rightWidth, height),
        ],
      3 => [
          Rect.fromLTWH(0, 0, leftWidth, height),
          Rect.fromLTWH(dividerX + gap, 0, rightWidth, topHeight),
          Rect.fromLTWH(
            dividerX + gap,
            dividerY + gap,
            rightWidth,
            bottomHeight,
          ),
        ],
      _ => [
          Rect.fromLTWH(0, 0, leftWidth, topHeight),
          Rect.fromLTWH(dividerX + gap, 0, rightWidth, topHeight),
          Rect.fromLTWH(0, dividerY + gap, leftWidth, bottomHeight),
          Rect.fromLTWH(
            dividerX + gap,
            dividerY + gap,
            rightWidth,
            bottomHeight,
          ),
        ],
    };
    final dividers = <_SplitDivider>[
      _SplitDivider.vertical(
        offset: dividerX + gap / 2,
        length: height,
        ratio: horizontal,
      ),
      if (splitTabs.length >= 3)
        _SplitDivider.horizontal(
          offset: dividerY + gap / 2,
          start: splitTabs.length == 3 ? dividerX + gap : 0,
          length: splitTabs.length == 3 ? rightWidth : width,
          ratio: vertical,
        ),
    ];
    return _SplitGeometry(
      bounds: {
        for (var index = 0; index < splitTabs.length; index++)
          splitTabs[index].id: panes[index],
      },
      dividers: dividers,
    );
  }

  double _clampRatio(double value, double min, double max) {
    if (min > max) return 0.5;
    return value.clamp(min, max).toDouble();
  }

  Widget _buildSplitDivider(
    BuildContext context,
    BoxConstraints constraints,
    _SplitDivider divider,
  ) {
    final vertical = divider.axis == Axis.vertical;
    return Positioned(
      left: vertical ? divider.offset - 4 : divider.start,
      top: vertical ? 0 : divider.offset - 4,
      width: vertical ? 8 : divider.length,
      height: vertical ? divider.length : 8,
      child: MouseRegion(
        cursor: vertical
            ? SystemMouseCursors.resizeColumn
            : SystemMouseCursors.resizeRow,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: WindowsVideoTabService.resetSplitBounds,
          onHorizontalDragUpdate: vertical
              ? (details) => WindowsVideoTabService.setSplitHorizontalRatio(
                  splitHorizontalRatio + details.delta.dx / constraints.maxWidth,
                )
              : null,
          onVerticalDragUpdate: vertical
              ? null
              : (details) => WindowsVideoTabService.setSplitVerticalRatio(
                  splitVerticalRatio + details.delta.dy / constraints.maxHeight,
                ),
          child: Center(
            child: Container(
              width: vertical ? 1 : double.infinity,
              height: vertical ? double.infinity : 1,
              color: Theme.of(context).colorScheme.outline.withValues(
                alpha: 0.42,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitGeometry {
  const _SplitGeometry({required this.bounds, required this.dividers});

  final Map<String, Rect> bounds;
  final List<_SplitDivider> dividers;
}

class _SplitDivider {
  const _SplitDivider.vertical({
    required this.offset,
    required this.length,
    required this.ratio,
  })  : axis = Axis.vertical,
        start = 0;

  const _SplitDivider.horizontal({
    required this.offset,
    required this.start,
    required this.length,
    required this.ratio,
  }) : axis = Axis.horizontal;

  final Axis axis;
  final double offset;
  final double start;
  final double length;
  final double ratio;
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
