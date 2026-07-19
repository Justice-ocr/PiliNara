import 'package:PiliPlus/common/skeleton/media_bangumi.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/pages/search_panel/controller.dart';
import 'package:PiliPlus/pages/search_panel/pgc/widgets/item.dart';
import 'package:PiliPlus/pages/search_panel/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_search_skeletons.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;
import 'package:get/get.dart';

class SearchPgcPanel extends CommonSearchPanel {
  const SearchPgcPanel({
    super.key,
    required super.keyword,
    required super.tag,
    required super.searchType,
  });

  @override
  State<SearchPgcPanel> createState() => _SearchPgcPanelState();
}

class _SearchPgcPanelState
    extends
        CommonSearchPanelState<
          SearchPgcPanel,
          SearchPgcData,
          SearchPgcItemModel
        > {
  @override
  late final SearchPanelController<SearchPgcData, SearchPgcItemModel>
  controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      SearchPanelController<SearchPgcData, SearchPgcItemModel>(
        keyword: widget.keyword,
        searchType: widget.searchType,
        tag: widget.tag,
      ),
      tag: widget.searchType.name + widget.tag,
    );
  }

  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: WindowsVideoTabService.enabled
        ? 620
        : Grid.smallCardWidth * 2,
    mainAxisExtent: WindowsVideoTabService.enabled ? 170 : 160,
    mainAxisSpacing: WindowsVideoTabService.enabled ? 12 : 0,
    crossAxisSpacing: WindowsVideoTabService.enabled ? 12 : 0,
  );

  @override
  Widget buildList(ThemeData theme, List<SearchPgcItemModel> list) {
    final grid = SliverGrid.builder(
      gridDelegate: gridDelegate,
      itemBuilder: (BuildContext context, int index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        final child = SearchPgcItem(item: list[index]);
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
              gridDelegate: gridDelegate,
              itemBuilder: (_, _) => const WindowsNeoSearchPgcSkeleton(),
              itemCount: 10,
            ),
          ),
        )
      : SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithExtentAndRatio(
            mainAxisSpacing: 2,
            maxCrossAxisExtent: Grid.smallCardWidth * 2,
            childAspectRatio: Style.aspectRatio * 1.5,
          ),
          itemBuilder: (_, _) => const MediaPgcSkeleton(),
          itemCount: 10,
        );
}
