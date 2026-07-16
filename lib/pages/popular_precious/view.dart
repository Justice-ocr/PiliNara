import 'package:PiliPlus/common/skeleton/video_card_h.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/common/widgets/view_sliver_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/video/source_type.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/pages/popular_precious/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PopularPreciousPage extends StatefulWidget {
  const PopularPreciousPage({super.key});

  @override
  State<PopularPreciousPage> createState() => _PopularPreciousPageState();
}

class _PopularPreciousPageState extends State<PopularPreciousPage>
    with GridMixin {
  final _controller = Get.put(PopularPreciousController());
  late final _windowsGridDelegate = SliverGridDelegateWithExtentAndRatio(
    maxCrossAxisExtent: 520,
    childAspectRatio: 4.2,
    minHeight: 112,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
  );

  SliverGridDelegateWithExtentAndRatio get _effectiveGridDelegate =>
      WindowsVideoTabService.enabled ? _windowsGridDelegate : gridDelegate;

  @override
  Widget build(BuildContext context) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('入站必刷')),
      body: refreshIndicator(
        onRefresh: _controller.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                  () => _buildBody(_controller.loadingState.value),
                ),
              )
            else
              ViewSliverSafeArea(
                sliver: Obx(
                  () => _buildBody(_controller.loadingState.value),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<HotVideoItemModel>?> value) {
    switch (value) {
      case Loading():
        return SliverGrid.builder(
          gridDelegate: _effectiveGridDelegate,
          itemBuilder: (_, _) => const VideoCardHSkeleton(),
          itemCount: 10,
        );
      case Success<List<HotVideoItemModel>?>(:final response):
        return SliverGrid.builder(
          gridDelegate: _effectiveGridDelegate,
          itemCount: response!.length,
          itemBuilder: (context, index) {
            final item = response[index];
            return VideoCardH(
              videoItem: item,
              onTap: () {
                PageUtils.toVideoPage(
                  bvid: item.bvid,
                  cid: item.cid!,
                  dimension: item.dimension,
                  extraArguments: {
                    'sourceType': SourceType.playlist,
                    'favTitle': '入站必刷',
                    'mediaId': _controller.mediaId,
                    'desc': true,
                    'oid': item.aid,
                    'isContinuePlaying': index != 0,
                  },
                );
              },
            );
          },
        );
      case Error(:final errMsg):
        return HttpError(
          errMsg: errMsg,
          onReload: _controller.onReload,
        );
    }
  }
}
