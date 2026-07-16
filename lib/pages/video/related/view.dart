import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/pages/video/related/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_horizontal_video_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RelatedVideoPanel extends StatefulWidget {
  const RelatedVideoPanel({super.key, required this.heroTag});
  final String heroTag;
  @override
  State<RelatedVideoPanel> createState() => _RelatedVideoPanelState();
}

class _RelatedVideoPanelState extends State<RelatedVideoPanel> with GridMixin {
  late final RelatedController _relatedController;

  @override
  void initState() {
    super.initState();
    _relatedController = Get.putOrFind(
      RelatedController.new,
      tag: widget.heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (WindowsVideoTabService.enabled) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
        sliver: Obx(
          () => _buildWindowsBody(_relatedController.loadingState.value),
        ),
      );
    }
    return SliverPadding(
      padding: const EdgeInsets.only(top: 7, bottom: 100),
      sliver: Obx(() => _buildBody(_relatedController.loadingState.value)),
    );
  }

  Widget _buildWindowsBody(
    LoadingState<List<HotVideoItemModel>?> loadingState,
  ) {
    const delegate = SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 1,
      mainAxisExtent: 132,
      mainAxisSpacing: 10,
    );
    return switch (loadingState) {
      Loading() => SliverGrid.builder(
        gridDelegate: delegate,
        itemCount: 6,
        itemBuilder: (_, _) => const WindowsNeoHorizontalTileSkeleton(),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: delegate,
                itemCount: response.length,
                itemBuilder: (context, index) => WindowsNeoHorizontalVideoTile(
                  videoItem: response[index],
                  onRemove: () => _relatedController.loadingState
                    ..value.data!.removeAt(index)
                    ..refresh(),
                ),
              )
            : const SliverToBoxAdapter(),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _relatedController.onReload,
      ),
    };
  }

  Widget _buildBody(LoadingState<List<HotVideoItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  return VideoCardH(
                    videoItem: response[index],
                    onRemove: () => _relatedController.loadingState
                      ..value.data!.removeAt(index)
                      ..refresh(),
                  );
                },
                itemCount: response.length,
              )
            : const SliverToBoxAdapter(),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _relatedController.onReload,
      ),
    };
  }
}
