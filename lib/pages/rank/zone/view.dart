import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/pages/rank/zone/controller.dart';
import 'package:PiliPlus/pages/rank/zone/widget/pgc_rank_item.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_horizontal_video_tile.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;
import 'package:get/get.dart';

class ZonePage extends StatefulWidget {
  const ZonePage({super.key, this.rid, this.seasonType});

  final int? rid;
  final int? seasonType;

  @override
  State<ZonePage> createState() => _ZonePageState();
}

class _ZonePageState extends State<ZonePage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final ZoneController controller;

  @override
  void initState() {
    controller = Get.put(
      ZoneController(rid: widget.rid, seasonType: widget.seasonType),
      tag: '${widget.rid}${widget.seasonType}',
    );
    super.initState();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (WindowsVideoTabService.enabled) {
      return refreshIndicator(
        onRefresh: controller.onRefresh,
        child: CustomScrollView(
          controller: controller.scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                context.windowsNeo.pagePadding,
                context.windowsNeo.spaceMd,
                context.windowsNeo.pagePadding,
                100,
              ),
              sliver: Obx(
                () => _buildDesktopBody(controller.loadingState.value),
              ),
            ),
          ],
        ),
      );
    }
    return refreshIndicator(
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(top: 7, bottom: 100),
            sliver: Obx(() => _buildBody(controller.loadingState.value)),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopBody(LoadingState<List<dynamic>?> loadingState) {
    final tokens = context.windowsNeo;
    final delegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 680,
      mainAxisExtent: tokens.horizontalCardHeight,
      mainAxisSpacing: tokens.gridGap,
      crossAxisSpacing: tokens.gridGap,
    );
    return switch (loadingState) {
      Loading() => SliverGrid.builder(
        gridDelegate: delegate,
        itemCount: 10,
        itemBuilder: (_, _) => const WindowsNeoHorizontalTileSkeleton(),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: delegate,
                itemCount: response.length,
                itemBuilder: (context, index) {
                  final item = response[index];
                  if (item is HotVideoItemModel) {
                    return WindowsNeoHorizontalVideoTile(
                      videoItem: item,
                      onRemove: () => controller.loadingState
                        ..value.data!.removeAt(index)
                        ..refresh(),
                    );
                  }
                  return WindowsNeoPgcRankTile(item: item);
                },
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _buildBody(LoadingState<List<dynamic>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  final item = response[index];
                  if (item is HotVideoItemModel) {
                    return VideoCardH(
                      videoItem: item,
                      onRemove: () => controller.loadingState
                        ..value.data!.removeAt(index)
                        ..refresh(),
                    );
                  }
                  return PgcRankItem(item: item);
                },
                itemCount: response.length,
              )
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }
}
