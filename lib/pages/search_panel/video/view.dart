import 'package:PiliPlus/common/widgets/sliver/sliver_floating_header.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/models/common/search/video_search_type.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/search_panel/video/controller.dart';
import 'package:PiliPlus/pages/search_panel/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;
import 'package:PiliPlus/windows_ui/components/windows_neo_video_search_tile.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SearchVideoPanel extends CommonSearchPanel {
  const SearchVideoPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchVideoPanel> createState() => _SearchVideoPanelState();
}

class _SearchVideoPanelState
    extends
        CommonSearchPanelState<
          SearchVideoPanel,
          SearchVideoData,
          SearchVideoItemModel
        >
    with GridMixin {
  @override
  late final SearchVideoController controller;

  @override
  String? getTitle(SearchVideoItemModel item) => item.title;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchVideoController(
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
          WindowsVideoTabService.enabled ? 16 : 12,
          0,
          WindowsVideoTabService.enabled ? 16 : 12,
          4,
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Wrap(
                  children: [
                    for (final e in ArchiveFilterType.values)
                      Obx(
                        () => SearchText(
                          fontSize: 13,
                          text: e.desc,
                          bgColor: Colors.transparent,
                          textColor: controller.selectedType.value == e
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline,
                          onTap: (_) => controller
                            ..order = e.name
                            ..selectedType.value = e
                            ..onSortSearch(getBack: false),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const VerticalDivider(indent: 7, endIndent: 8),
            const SizedBox(width: 3),
            SizedBox(
              width: 32,
              height: 32,
              child: IconButton(
                tooltip: '筛选',
                style: const ButtonStyle(
                  padding: WidgetStatePropertyAll(EdgeInsets.zero),
                ),
                onPressed: () => controller.onShowFilterDialog(context),
                icon: Obx(() => Icon(
                  controller.includeKeywords.isNotEmpty ||
                          controller.excludeKeywords.isNotEmpty
                      ? Icons.filter_list
                      : Icons.filter_list_off,
                  size: 18,
                  color: theme.colorScheme.primary,
                )),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget buildList(ThemeData theme, List<SearchVideoItemModel> list) {
    if (WindowsVideoTabService.enabled) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 760,
            mainAxisExtent: 120,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            if (index == list.length - 1) controller.onLoadMore();
            return WindowsNeoVideoSearchTile(
              videoItem: list[index],
              onRemove: () => controller.loadingState
                ..value.data!.removeAt(index)
                ..refresh(),
            );
          },
          itemCount: list.length,
        ),
      );
    }
    return SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (context, index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        return VideoCardH(
          videoItem: list[index],
          onRemove: () => controller.loadingState
            ..value.data!.removeAt(index)
            ..refresh(),
        );
      },
      itemCount: list.length,
    );
  }

  @override
  Widget get buildLoading => WindowsVideoTabService.enabled
      ? SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: gridSkeleton,
        )
      : gridSkeleton;
}
