import 'package:PiliPlus/pages/article/view.dart';
import 'package:PiliPlus/pages/article_list/view.dart';
import 'package:PiliPlus/pages/blacklist/view.dart';
import 'package:PiliPlus/pages/dynamics_detail/view.dart';
import 'package:PiliPlus/pages/dynamics_topic/view.dart';
import 'package:PiliPlus/pages/download/view.dart';
import 'package:PiliPlus/pages/fan/view.dart';
import 'package:PiliPlus/pages/fav/view.dart';
import 'package:PiliPlus/pages/fav_detail/view.dart';
import 'package:PiliPlus/pages/fav_search/view.dart';
import 'package:PiliPlus/pages/follow/view.dart';
import 'package:PiliPlus/pages/follow_search/view.dart';
import 'package:PiliPlus/pages/follow_type/follow_same/view.dart';
import 'package:PiliPlus/pages/follow_type/followed/view.dart';
import 'package:PiliPlus/pages/history/view.dart';
import 'package:PiliPlus/pages/history_search/view.dart';
import 'package:PiliPlus/pages/later/view.dart';
import 'package:PiliPlus/pages/later_search/view.dart';
import 'package:PiliPlus/pages/live_area/view.dart';
import 'package:PiliPlus/pages/live_follow/view.dart';
import 'package:PiliPlus/pages/member/view.dart';
import 'package:PiliPlus/pages/member_dynamics/view.dart';
import 'package:PiliPlus/pages/member_guard/view.dart';
import 'package:PiliPlus/pages/member_profile/view.dart';
import 'package:PiliPlus/pages/member_search/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/at_me/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/like_detail/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/like_me/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/reply_me/view.dart';
import 'package:PiliPlus/pages/msg_feed_top/sys_msg/view.dart';
import 'package:PiliPlus/pages/my_reply/view.dart';
import 'package:PiliPlus/pages/popular_precious/view.dart';
import 'package:PiliPlus/pages/popular_series/view.dart';
import 'package:PiliPlus/pages/rank/view.dart';
import 'package:PiliPlus/pages/search/view.dart';
import 'package:PiliPlus/pages/search_trending/view.dart';
import 'package:PiliPlus/pages/setting/ai_setting/view.dart';
import 'package:PiliPlus/pages/setting/pages/bar_set.dart';
import 'package:PiliPlus/pages/setting/pages/color_select.dart';
import 'package:PiliPlus/pages/setting/pages/font_setting.dart';
import 'package:PiliPlus/pages/setting/pages/play_speed_set.dart';
import 'package:PiliPlus/pages/setting/view.dart';
import 'package:PiliPlus/pages/space_setting/view.dart';
import 'package:PiliPlus/pages/sponsor_block/view.dart';
import 'package:PiliPlus/pages/subscription/view.dart';
import 'package:PiliPlus/pages/subscription_detail/view.dart';
import 'package:PiliPlus/pages/webview/view.dart';
import 'package:PiliPlus/pages/whisper/view.dart';
import 'package:PiliPlus/pages/whisper_detail/view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

enum WindowsWorkspaceRouteKind { nested, toolTab }

class WindowsWorkspaceRouteDefinition {
  const WindowsWorkspaceRouteDefinition({
    required this.path,
    required this.kind,
    required this.pageBuilder,
    this.defaultTitle,
  });

  final String path;
  final WindowsWorkspaceRouteKind kind;
  final Widget Function() pageBuilder;
  final String? defaultTitle;

  bool get opensAsToolTab => kind == WindowsWorkspaceRouteKind.toolTab;
}

abstract final class WindowsWorkspaceRouteRegistry {
  static final List<WindowsWorkspaceRouteDefinition> definitions =
      List.unmodifiable([
    const WindowsWorkspaceRouteDefinition(
      path: '/download',
      kind: WindowsWorkspaceRouteKind.toolTab,
      defaultTitle: '下载',
      pageBuilder: DownloadPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/fav',
      kind: WindowsWorkspaceRouteKind.toolTab,
      defaultTitle: '收藏',
      pageBuilder: FavPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/history',
      kind: WindowsWorkspaceRouteKind.toolTab,
      defaultTitle: '观看记录',
      pageBuilder: HistoryPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/later',
      kind: WindowsWorkspaceRouteKind.toolTab,
      defaultTitle: '稍后再看',
      pageBuilder: LaterPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/myReply',
      kind: WindowsWorkspaceRouteKind.toolTab,
      defaultTitle: '我的回复',
      pageBuilder: MyReply.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/setting',
      kind: WindowsWorkspaceRouteKind.toolTab,
      defaultTitle: '设置',
      pageBuilder: SettingPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/subscription',
      kind: WindowsWorkspaceRouteKind.toolTab,
      defaultTitle: '我的订阅',
      pageBuilder: SubPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/whisper',
      kind: WindowsWorkspaceRouteKind.toolTab,
      defaultTitle: '私信',
      pageBuilder: WhisperPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/search',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: SearchPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/searchTrending',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: SearchTrendingPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/member',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: MemberPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/memberSearch',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: MemberSearchPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/editProfile',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: EditProfilePage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/spaceSetting',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: SpaceSettingPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/dynamicDetail',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: DynamicDetailPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/articlePage',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: ArticlePage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/articleList',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: ArticleListPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/dynTopic',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: DynTopicPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/blockSetting',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: SettingPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/blackListPage',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: BlackListPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/sponsorBlock',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: SponsorBlockPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/aiSetting',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: AiSettingPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/playSpeedSet',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: PlaySpeedPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/colorSetting',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: ColorSelectPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/fontSizeSetting',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: FontSettingPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/fontSetting',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: FontSettingPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/barSetting',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: BarSetPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/historySearch',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: HistorySearchPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/laterSearch',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: LaterSearchPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/favDetail',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: FavDetailPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/favSearch',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: FavSearchPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/popularSeries',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: PopularSeriesPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/popularPrecious',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: PopularPreciousPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/rank',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: WindowsWorkspaceRankPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/whisperDetail',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: WhisperDetailPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/replyMe',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: ReplyMePage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/atMe',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: AtMePage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/likeMe',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: LikeMePage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/sysMsg',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: SysMsgPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/webview',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: WebviewPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/liveArea',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: LiveAreaPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/liveFollow',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: LiveFollowPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/memberGuard',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: MemberGuard.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/subDetail',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: SubDetailPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/msgLikeDetail',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: LikeDetailPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/memberDynamics',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: MemberDynamicsPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/follow',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: FollowPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/fan',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: FansPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/followSearch',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: FollowSearchPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/followed',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: FollowedPage.new,
    ),
    const WindowsWorkspaceRouteDefinition(
      path: '/sameFollowing',
      kind: WindowsWorkspaceRouteKind.nested,
      pageBuilder: FollowSamePage.new,
    ),
  ]);

  static final Map<String, WindowsWorkspaceRouteDefinition> _routesByPath =
      _indexDefinitions();

  static final Set<String> nestedPaths = Set.unmodifiable(
    definitions
        .where((route) => route.kind == WindowsWorkspaceRouteKind.nested)
        .map((route) => route.path),
  );

  static final Set<String> toolTabPaths = Set.unmodifiable(
    definitions
        .where((route) => route.opensAsToolTab)
        .map((route) => route.path),
  );

  static final List<GetPage<dynamic>> globalPages = List.unmodifiable(
    definitions
        .map(
          (route) => GetPage<dynamic>(
            name: route.path,
            page: route.pageBuilder,
          ),
        )
        .toList(growable: false),
  );

  static WindowsWorkspaceRouteDefinition? routeFor(String path) =>
      _routesByPath[path];

  static bool contains(String path) => _routesByPath.containsKey(path);

  static Widget? buildPage(String path) => routeFor(path)?.pageBuilder();

  static Map<String, WindowsWorkspaceRouteDefinition> _indexDefinitions() {
    final routes = <String, WindowsWorkspaceRouteDefinition>{};
    for (final route in definitions) {
      if (routes.containsKey(route.path)) {
        throw StateError('Duplicate Windows workspace route: ${route.path}');
      }
      routes[route.path] = route;
    }
    return Map.unmodifiable(routes);
  }
}

class WindowsWorkspaceRankPage extends StatelessWidget {
  const WindowsWorkspaceRankPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('排行榜')),
        body: const RankPage(),
      );
}
