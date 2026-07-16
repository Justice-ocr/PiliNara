import 'package:PiliPlus/common/skeleton/video_card_v.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/live/live_follow/item.dart';
import 'package:PiliPlus/pages/live_follow/controller.dart';
import 'package:PiliPlus/pages/live_follow/widgets/live_item_follow.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveFollowPage extends StatefulWidget {
  const LiveFollowPage({super.key});

  @override
  State<LiveFollowPage> createState() => _LiveFollowPageState();
}

class _LiveFollowPageState extends State<LiveFollowPage> {
  final _controller = Get.put(LiveFollowController());

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Obx(
          () {
            final count = _controller.count.value;
            return Text(count != null ? '$count人正在直播' : '关注直播');
          },
        ),
      ),
      body: refreshIndicator(
        onRefresh: _controller.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                left: isWindowsNeo ? 18 : Style.safeSpace + padding.left,
                top: isWindowsNeo ? 16 : 0,
                right: isWindowsNeo ? 18 : Style.safeSpace + padding.right,
                bottom: padding.bottom + 100,
              ),
              sliver: Obx(() => _buildBody(_controller.loadingState.value)),
            ),
          ],
        ),
      ),
    );
  }

  late final gridDelegate = SliverGridDelegateWithExtentAndRatio(
    mainAxisSpacing: WindowsVideoTabService.enabled ? 14 : Style.cardSpace,
    crossAxisSpacing: WindowsVideoTabService.enabled ? 14 : Style.cardSpace,
    maxCrossAxisExtent: WindowsVideoTabService.enabled
        ? 300
        : Grid.smallCardWidth,
    childAspectRatio: WindowsVideoTabService.enabled
        ? Style.aspectRatio16x9
        : Style.aspectRatio,
    mainAxisExtent: MediaQuery.textScalerOf(
      context,
    ).scale(WindowsVideoTabService.enabled ? 92 : 90),
  );

  Widget _buildBody(LoadingState<List<LiveFollowItem>?> loadingState) {
    return switch (loadingState) {
      Loading() => SliverGrid.builder(
        gridDelegate: gridDelegate,
        itemBuilder: (context, index) => const VideoCardVSkeleton(),
        itemCount: 10,
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _controller.onLoadMore();
                  }
                  return LiveCardVFollow(
                    liveItem: response[index],
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }
}
