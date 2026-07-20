import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/fav_type.dart';
import 'package:PiliPlus/pages/fav/article/controller.dart';
import 'package:PiliPlus/pages/fav/cheese/controller.dart';
import 'package:PiliPlus/pages/fav/topic/controller.dart';
import 'package:PiliPlus/pages/fav/video/controller.dart';
import 'package:PiliPlus/pages/fav_folder_sort/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_section_tabs.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class FavPage extends StatefulWidget {
  const FavPage({super.key});

  @override
  State<FavPage> createState() => _FavPageState();
}

class _FavPageState extends State<FavPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final FavController _favController = Get.put(FavController());
  late final RxBool _showVideoFavMenu;

  void listener() {
    _showVideoFavMenu.value = _tabController.index == 0;
  }

  @override
  void initState() {
    super.initState();
    int initialIndex = Get.arguments is int ? Get.arguments as int : 0;
    _showVideoFavMenu = (initialIndex == 0).obs;
    _tabController = TabController(
      length: FavTabType.values.length,
      vsync: this,
      initialIndex: initialIndex,
    );
    _tabController.addListener(listener);
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
    if (WindowsVideoTabService.enabled) {
      return _buildWindowsPage(context);
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: [
          Obx(
            () => _showVideoFavMenu.value
                ? IconButton(
                    onPressed: () => Get.toNamed('/createFav')?.then(
                      (data) {
                        if (data != null) {
                          final list =
                              _favController.loadingState.value.dataOrNull;
                          if (list != null && list.isNotEmpty) {
                            list.insert(1, data);
                            _favController.loadingState.refresh();
                          } else {
                            _favController.loadingState.value = Success([data]);
                          }
                        }
                      },
                    ),
                    icon: const Icon(Icons.add),
                    tooltip: '新建收藏夹',
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => _showVideoFavMenu.value
                ? IconButton(
                    onPressed: () {
                      if (_favController.loadingState.value.isSuccess) {
                        if (!_favController.isEnd) {
                          SmartDialog.showToast('加载全部收藏夹再排序');
                          return;
                        }
                        Get.to(
                          FavFolderSortPage(favController: _favController),
                        );
                      }
                    },
                    icon: const Icon(Icons.sort),
                    tooltip: '收藏夹排序',
                  )
                : const SizedBox.shrink(),
          ),
          Obx(
            () => _showVideoFavMenu.value
                ? IconButton(
                    onPressed: () {
                      if (_favController.loadingState.value case Success(
                        :final response,
                      )) {
                        try {
                          final item = response!.first;
                          Get.toNamed(
                            '/favSearch',
                            arguments: {
                              'type': 1,
                              'mediaId': item.id,
                              'title': item.title,
                              'count': item.mediaCount,
                              'isOwner': true,
                            },
                          );
                        } catch (_) {}
                      }
                    },
                    icon: const Icon(Icons.search_outlined),
                    tooltip: '搜索',
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 6),
        ],
        bottom: _buildTabs(),
      ),
      body: ViewSafeArea(
        child: tabBarView(
          controller: _tabController,
          children: FavTabType.values.map((item) => item.page).toList(),
        ),
      ),
    );
  }

  Widget _buildWindowsPage(BuildContext context) {
    return WindowsNeoPage(
      title: '\u6211\u7684\u6536\u85cf',
      subtitle:
          '\u7ba1\u7406\u89c6\u9891\u3001\u4e13\u680f\u4e0e\u5185\u5bb9\u5408\u96c6',
      leading: Icon(Icons.bookmarks_outlined, color: context.windowsNeo.accent),
      actions: [
        Obx(
          () => _showVideoFavMenu.value
              ? IconButton(
                  onPressed: () => Get.toNamed('/createFav')?.then((data) {
                    if (data != null) {
                      final list = _favController.loadingState.value.dataOrNull;
                      if (list != null && list.isNotEmpty) {
                        list.insert(1, data);
                        _favController.loadingState.refresh();
                      } else {
                        _favController.loadingState.value = Success([data]);
                      }
                    }
                  }),
                  icon: const Icon(Icons.create_new_folder_outlined),
                  tooltip: '\u65b0\u5efa\u6536\u85cf\u5939',
                )
              : const SizedBox.shrink(),
        ),
        Obx(
          () => _showVideoFavMenu.value
              ? IconButton(
                  onPressed: () {
                    if (_favController.loadingState.value.isSuccess) {
                      if (!_favController.isEnd) {
                        SmartDialog.showToast(
                          '\u52a0\u8f7d\u5b8c\u5168\u90e8\u6536\u85cf\u5939\u518d\u6392\u5e8f',
                        );
                        return;
                      }
                      Get.to(FavFolderSortPage(favController: _favController));
                    }
                  },
                  icon: const Icon(Icons.swap_vert_outlined),
                  tooltip: '\u6536\u85cf\u5939\u6392\u5e8f',
                )
              : const SizedBox.shrink(),
        ),
        Obx(
          () => _showVideoFavMenu.value
              ? IconButton(
                  onPressed: () {
                    if (_favController.loadingState.value case Success(
                      :final response,
                    )) {
                      try {
                        final item = response!.first;
                        Get.toNamed(
                          '/favSearch',
                          arguments: {
                            'type': 1,
                            'mediaId': item.id,
                            'title': item.title,
                            'count': item.mediaCount,
                            'isOwner': true,
                          },
                        );
                      } catch (_) {}
                    }
                  },
                  icon: const Icon(Icons.search_outlined),
                  tooltip: '\u641c\u7d22\u6536\u85cf',
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 6),
      ],
      commandBar: _buildTabs(),
      child: ViewSafeArea(
        child: tabBarView(
          controller: _tabController,
          children: FavTabType.values.map((item) => item.page).toList(),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildTabs() {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final tabs = FavTabType.values
        .map((item) => Tab(text: item.title))
        .toList();
    void onTap(int index) {
      try {
        if (!_tabController.indexIsChanging) {
          switch (FavTabType.values[index]) {
            case FavTabType.video:
              _favController.scrollController.animToTop();
            case FavTabType.article:
              Get.find<FavArticleController>().scrollController.animToTop();
            case FavTabType.topic:
              Get.find<FavTopicController>().scrollController.animToTop();
            case FavTabType.cheese:
              Get.find<FavCheeseController>().scrollController.animToTop();
            default:
          }
        }
      } catch (_) {}
    }

    if (isWindowsNeo) {
      return PreferredSize(
        preferredSize: Size.fromHeight(context.windowsNeo.sectionTabHeight),
        child: WindowsNeoSectionTabs(
          controller: _tabController,
          tabs: tabs,
          onTap: onTap,
        ),
      );
    }
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        tabs: tabs,
        onTap: onTap,
      ),
    );
  }
}
