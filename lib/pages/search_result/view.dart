import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart' show tabBarView;
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:PiliPlus/pages/search/controller.dart';
import 'package:PiliPlus/pages/search_panel/article/view.dart';
import 'package:PiliPlus/pages/search_panel/live/view.dart';
import 'package:PiliPlus/pages/search_panel/pgc/view.dart';
import 'package:PiliPlus/pages/search_panel/user/view.dart';
import 'package:PiliPlus/pages/search_panel/video/view.dart';
import 'package:PiliPlus/pages/search_result/controller.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

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
    _args =
        widget.arguments ??
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
    return SimpleScaffold(
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
        PageUtils.toSearch(parameters: parameters, off: true);
      }
    }
  }

  Widget _buildTabBar(ThemeData theme, {bool desktop = false}) {
    final tabs = SearchType.values
        .map(
          (item) => Obx(() {
            final count = _searchResultController.count[item.index];
            final countLabel = count == -1
                ? ''
                : ' ${count > 99 ? '99+' : count}';
            return Tab(text: '${_labelForType(item)}$countLabel');
          }),
        )
        .toList();
    void onTap(int index) {
      if (!_tabController.indexIsChanging) {
        if (_searchResultController.toTopIndex.value == index) {
          _searchResultController.toTopIndex.refresh();
        } else {
          _searchResultController.toTopIndex.value = index;
        }
      }
    }

    if (desktop) {
      return WindowsNeoSectionTabs(
        controller: _tabController,
        tabs: tabs,
        horizontalPadding: 14,
        onTap: onTap,
      );
    }
    return TabBar(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      splashFactory: NoSplash.splashFactory,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      controller: _tabController,
      tabs: tabs,
      isScrollable: true,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 3, vertical: 8),
      indicator: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      labelColor: theme.colorScheme.onSecondaryContainer,
      labelStyle: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      dividerColor: Colors.transparent,
      dividerHeight: 0,
      unselectedLabelColor: theme.colorScheme.outline,
      tabAlignment: TabAlignment.start,
      onTap: onTap,
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
            SearchType.media_bangumi || SearchType.media_ft => SearchPgcPanel(
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
