import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/pages/search_panel/article/view.dart';
import 'package:PiliPlus/pages/search_panel/live/view.dart';
import 'package:PiliPlus/pages/search_panel/pgc/view.dart';
import 'package:PiliPlus/pages/search_panel/user/view.dart';
import 'package:PiliPlus/pages/search_panel/video/view.dart';
import 'package:PiliPlus/pages/search_result/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchResultPage extends StatefulWidget {
  const SearchResultPage({super.key, this.arguments});

  final Map? arguments;

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage>
    with SingleTickerProviderStateMixin {
  late SearchResultController _searchResultController;
  late TabController _tabController;
  final String _tag = DateTime.now().millisecondsSinceEpoch.toString();
  late final Map _args;
  late final bool _isFromSearch;
  SSearchController? sSearchController;

  @override
  void initState() {
    super.initState();
    _args = widget.arguments ??
        (Get.arguments is Map ? Get.arguments as Map : const {});
    _isFromSearch = _args['fromSearch'] ?? false;
    _searchResultController = Get.put(
      SearchResultController(arguments: _args),
      tag: _tag,
    );

    _tabController = TabController(
      vsync: this,
      initialIndex: _args['initIndex'] ?? 0,
      length: SearchType.values.length,
    );

    if (_isFromSearch) {
      try {
        sSearchController = Get.find<SSearchController>(
          tag: _args['tag'] ?? Get.parameters['tag'],
        );
        _tabController.addListener(listener);
      } catch (_) {}
    }
  }

  void listener() {
    sSearchController?.initIndex = _tabController.index;
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(listener)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (WindowsVideoTabService.enabled) {
      return WindowsNeoPage(
        title: '搜索结果',
        subtitle: _searchResultController.keyword,
        leading: Icon(
          Icons.manage_search,
          color: context.windowsNeo.accent,
        ),
        actions: [
          IconButton(
            tooltip: '修改搜索',
            onPressed: _openSearch,
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
        commandBar: _buildTabBar(theme, desktop: true),
        child: _buildTabView(),
      );
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        shape: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
        title: GestureDetector(
          onTap: _openSearch,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: double.infinity,
            child: Text(
              _searchResultController.keyword,
              style: theme.textTheme.titleMedium,
              maxLines: 1,
            ),
          ),
        ),
      ),
      body: ViewSafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTabBar(theme),
            Expanded(child: _buildTabView()),
          ],
        ),
      ),
    );
  }

  void _openSearch() {
    if (_isFromSearch) {
      Get.back();
    } else {
      final parameters = {'text': _searchResultController.keyword};
      if (WindowsVideoTabService.enabled) {
        PageUtils.toSearch(parameters: parameters);
      } else {
        Get.offNamed('/search', parameters: parameters);
      }
    }
  }

  Widget _buildTabBar(ThemeData theme, {bool desktop = false}) {
    return SizedBox(
      height: desktop ? 44 : null,
      child: TabBar(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        padding: EdgeInsets.symmetric(horizontal: desktop ? 14 : 8),
        controller: _tabController,
        tabs: SearchType.values
            .map(
              (item) => Obx(() {
                final count = _searchResultController.count[item.index];
                final countLabel = count == -1
                    ? ''
                    : ' ${count > 99 ? '99+' : count}';
                return Tab(text: '${_labelForType(item)}$countLabel');
              }),
            )
            .toList(),
        isScrollable: true,
        indicatorSize: desktop
            ? TabBarIndicatorSize.label
            : TabBarIndicatorSize.tab,
        indicatorPadding: desktop
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
        indicator: desktop
            ? UnderlineTabIndicator(
                borderSide: BorderSide(
                  color: context.windowsNeo.accent,
                  width: 2.5,
                ),
              )
            : BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(20)),
              ),
        labelColor: desktop
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSecondaryContainer,
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        unselectedLabelColor: desktop
            ? context.windowsNeo.muted
            : theme.colorScheme.outline,
        tabAlignment: TabAlignment.start,
        onTap: (index) {
          if (!_tabController.indexIsChanging) {
            if (_searchResultController.toTopIndex.value == index) {
              _searchResultController.toTopIndex.refresh();
            } else {
              _searchResultController.toTopIndex.value = index;
            }
          }
        },
      ),
    );
  }

  Widget _buildTabView() => tabBarView(
    controller: _tabController,
    children: SearchType.values
        .map(
          (item) => switch (item) {
                        // SearchType.all => SearchAllPanel(
                        //   tag: _tag,
                        //   searchType: item,
                        //   keyword: _searchResultController.keyword,
                        // ),
                        SearchType.video => SearchVideoPanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                        SearchType.media_bangumi ||
                        SearchType.media_ft => SearchPgcPanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                        SearchType.live_room => SearchLivePanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                        SearchType.bili_user => SearchUserPanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
                        SearchType.article => SearchArticlePanel(
                          tag: _tag,
                          searchType: item,
                          keyword: _searchResultController.keyword,
                        ),
          },
        )
        .toList(),
  );

  String _labelForType(SearchType type) => switch (type) {
    SearchType.video => '视频',
    SearchType.media_bangumi => '番剧',
    SearchType.media_ft => '影视',
    SearchType.live_room => '直播',
    SearchType.bili_user => '用户',
    SearchType.article => '专栏',
  };
}
