import 'package:PiliPlus/models_new/history/data.dart';
import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/pages/common/search/common_search_page.dart';
import 'package:PiliPlus/pages/history/widgets/item.dart';
import 'package:PiliPlus/pages/history_search/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HistorySearchPage extends StatefulWidget {
  const HistorySearchPage({super.key});

  @override
  State<HistorySearchPage> createState() => _HistorySearchPageState();
}

class _HistorySearchPageState
    extends
        CommonSearchPageState<
          HistorySearchPage,
          HistoryData,
          HistoryItemModel
        > {
  @override
  final HistorySearchController controller = Get.put(
    HistorySearchController(),
    tag: Utils.generateRandomString(8),
  );

  late final gridDelegate = Grid.videoCardHDelegate(context, minHeight: 110);

  @override
  Widget buildList(List<HistoryItemModel> list) {
    final grid = SliverGrid.builder(
      gridDelegate: WindowsVideoTabService.enabled
          ? SliverGridDelegateWithExtentAndRatio(
              maxCrossAxisExtent: 520,
              childAspectRatio: 4.2,
              minHeight: 112,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            )
          : gridDelegate,
      itemBuilder: (context, index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        final item = list[index];
        return HistoryItem(
          item: item,
          ctr: controller,
          onDelete: (kid, business) =>
              controller.onDelHistory(index, kid, business),
        );
      },
      itemCount: list.length,
    );
    if (!WindowsVideoTabService.enabled) return grid;
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 100),
      sliver: grid,
    );
  }
}
