import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/models_new/download/download_collection.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/download/bili_download_entry_info.dart';
import 'package:PiliPlus/pages/common/search/common_search_page.dart';
import 'package:PiliPlus/pages/download/detail/widgets/item.dart';
import 'package:PiliPlus/pages/download/search/controller.dart';
import 'package:PiliPlus/services/download/download_service.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:flutter/material.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

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
        > {
  @override
  DownloadSearchController controller = Get.put(DownloadSearchController());
  final _downloadService = Get.find<DownloadService>();

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
  List<Widget>? get multiSelectActions => [
    TextButton(
      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
      onPressed: () async {
        final future = controller.allChecked
            .map(
              (e) => _downloadService.downloadDanmaku(
                entry: e,
                isUpdate: true,
              ),
            )
            .toList();
        controller.handleSelect();
        final res = await Future.wait(future);
        if (res.every((e) => e)) {
          SmartDialog.showToast('更新成功');
        } else {
          SmartDialog.showToast('更新失败');
        }
      },
      child: Text(
        '更新',
        style: TextStyle(color: ColorScheme.of(context).onSurface),
      ),
    ),
  ];

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
            downloadService: _downloadService,
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
