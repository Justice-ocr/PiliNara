import 'package:PiliPlus/common/skeleton/msg_feed_top.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/view_sliver_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/pages/follow/widgets/follow_item.dart';
import 'package:PiliPlus/pages/follow_type/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart'
    hide SliverGridDelegateWithMaxCrossAxisExtent;
import 'package:get/get.dart';

abstract class FollowTypePageState<T extends StatefulWidget> extends State<T> {
  FollowTypeController get controller;

  PreferredSizeWidget? get appBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).colorScheme;
    final isWindowsNeo = WindowsVideoTabService.enabled;
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: appBar,
      body: refreshIndicator(
        onRefresh: controller.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          // controller: controller.scrollController,
          slivers: [
            if (isWindowsNeo)
              SliverPadding(
                padding: EdgeInsets.only(
                  left: 18,
                  top: 16,
                  right: 18,
                  bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
                ),
                sliver: Obx(
                  () => _buildBody(theme, controller.loadingState.value),
                ),
              )
            else
              ViewSliverSafeArea(
                sliver: Obx(
                  () => _buildBody(theme, controller.loadingState.value),
                ),
              ),
          ],
        ),
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
    maxCrossAxisExtent: WindowsVideoTabService.enabled
        ? 520
        : Grid.smallCardWidth * 2,
    mainAxisExtent: WindowsVideoTabService.enabled ? 76 : 66,
    mainAxisSpacing: WindowsVideoTabService.enabled ? 12 : 0,
    crossAxisSpacing: WindowsVideoTabService.enabled ? 12 : 0,
  );

  Widget _buildBody(
    ColorScheme theme,
    LoadingState<List<FollowItemModel>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemBuilder: (context, index) => const MsgFeedTopSkeleton(),
        itemCount: 16,
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  return buildItem(index, response[index]);
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

  Widget buildItem(int index, FollowItemModel item) => FollowItem(item: item);
}
