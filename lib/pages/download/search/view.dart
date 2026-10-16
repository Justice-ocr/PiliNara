import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/models_new/download/download_collection.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/download/bili_download_entry_info.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/pages/common/search/common_search_page.dart';
import 'package:PiliPlus/pages/download/detail/widgets/item.dart';
import 'package:PiliPlus/pages/download/download_action_mixin.dart';
import 'package:PiliPlus/pages/download/search/controller.dart';
import 'package:PiliPlus/services/download/download_service.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;

class DownloadSearchPage extends StatefulWidget {
  const DownloadSearchPage({
    super.key,
    required this.progress,
  });

  final ChangeNotifier progress;

  @override
  State<DownloadSearchPage> createState() => _DownloadSearchPageState();
}

class _DownloadSearchPageState
    extends
        CommonSearchPageState<
          DownloadSearchPage,
          List<BiliDownloadEntryInfo>,
          BiliDownloadEntryInfo
        >
    with
        GridMixin,
        BaseDownloadActionMixin<DownloadSearchPage, BiliDownloadEntryInfo>,
        CommonDownloadActionMixin<DownloadSearchPage> {
  @override
  DownloadSearchController controller = Get.put(DownloadSearchController());

  @override
  final downloadService = Get.find<DownloadService>();

  @override
  BaseMultiSelectMixin<BiliDownloadEntryInfo> get multiSelectCtr => controller;

  @override
  List<Widget>? get extraActions => [
    IconButton(
      tooltip: '多选',
      onPressed: () {
        if (controller.loadingState.value is! Success) {
          return;
        }
        if (controller.enableMultiSelect.value) {
          controller.handleSelect();
        } else {
          controller.enableMultiSelect.value = true;
        }
      },
      icon: const Icon(Icons.edit_note),
    ),
  ];

  @override
  List<Widget>? get multiSelectActions => [updateBtn()];

  @override
  Widget buildList(List<BiliDownloadEntryInfo> list) {
    if (list.isNotEmpty) {
      final grid = SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          mainAxisSpacing: WindowsVideoTabService.enabled ? 12 : 2,
          crossAxisSpacing: WindowsVideoTabService.enabled ? 12 : 0,
          mainAxisExtent: WindowsVideoTabService.enabled ? 112 : 100,
          maxCrossAxisExtent: WindowsVideoTabService.enabled
              ? 520
              : Grid.smallCardWidth * 2,
        ),
        itemBuilder: (context, index) {
          final entry = list[index];
          return DetailItem(
            entry: entry,
            progress: widget.progress,
            downloadService: downloadService,
            showTitle: true,
            onDelete: () => controller.onRemoveSingle(index, entry),
            controller: controller,
            playContext: const DownloadVideoPlayContext.all(),
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
    return const HttpError();
  }
}
