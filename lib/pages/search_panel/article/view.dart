import 'package:PiliPlus/common/widgets/sliver/sliver_floating_header.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/pages/search_panel/article/controller.dart';
import 'package:PiliPlus/pages/search_panel/article/widgets/item.dart';
import 'package:PiliPlus/pages/search_panel/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_search_skeletons.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchArticlePanel extends CommonSearchPanel {
  const SearchArticlePanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchArticlePanel> createState() => _SearchArticlePanelState();
}

class _SearchArticlePanelState
    extends
        CommonSearchPanelState<
          SearchArticlePanel,
          SearchArticleData,
          SearchArticleItemModel
        >
    with GridMixin {
  late final _windowsGridDelegate = SliverGridDelegateWithExtentAndRatio(
    maxCrossAxisExtent: 520,
    childAspectRatio: 4.2,
    minHeight: 112,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
  );

  @override
  late final SearchArticleController controller;

  @override
  String? getTitle(SearchArticleItemModel item) =>
      item.title.map((e) => e.text).join();

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchArticleController(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }

  @override
  Widget buildHeader(ThemeData theme) {
    return SliverFloatingHeaderWidget(
      backgroundColor: WindowsVideoTabService.enabled
          ? context.windowsNeo.surface
          : theme.colorScheme.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          WindowsVideoTabService.enabled ? 16 : 25,
          0,
          WindowsVideoTabService.enabled ? 16 : 12,
          4,
        ),
        child: Row(
          children: [
            Obx(
              () => Text(
                '排序: ${controller.articleOrderType.value.label}',
                maxLines: 1,
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            const Spacer(),
            Obx(
              () => Text(
                '分区: ${controller.articleZoneType!.value.label}',
                maxLines: 1,
                style: TextStyle(color: theme.colorScheme.outline),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                tooltip: '筛选',
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                onPressed: () => controller.onShowFilterDialog(context),
                icon: Obx(
                  () => Icon(
                    controller.includeKeywords.isNotEmpty ||
                            controller.excludeKeywords.isNotEmpty
                        ? Icons.filter_list
                        : Icons.filter_list_off,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildList(ThemeData theme, List<SearchArticleItemModel> list) {
    final grid = SliverGrid.builder(
      gridDelegate: WindowsVideoTabService.enabled
          ? _windowsGridDelegate
          : gridDelegate,
      itemBuilder: (context, index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        final child = SearchArticleItem(item: list[index]);
        return WindowsVideoTabService.enabled
            ? WindowsNeoStaggeredReveal(
                order: index,
                enabled: index < 8,
                child: child,
              )
            : child;
      },
      itemCount: list.length,
    );
    return WindowsVideoTabService.enabled
        ? SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: grid,
          )
        : grid;
  }

  @override
  Widget get buildLoading => WindowsVideoTabService.enabled
      ? SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: WindowsNeoSliverLoadingPulse(
            sliver: SliverGrid.builder(
              gridDelegate: _windowsGridDelegate,
              itemBuilder: (_, _) => const WindowsNeoSearchHorizontalSkeleton(),
              itemCount: 10,
            ),
          ),
        )
      : gridSkeleton;
}
