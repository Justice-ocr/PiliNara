import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/space/space_article/item.dart';
import 'package:PiliPlus/pages/member_article/controller.dart';
import 'package:PiliPlus/pages/member_article/widget/item.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MemberArticle extends StatefulWidget {
  const MemberArticle({
    super.key,
    required this.heroTag,
    required this.mid,
  });

  final String? heroTag;
  final int mid;

  @override
  State<MemberArticle> createState() => _MemberArticleState();
}

class _MemberArticleState extends State<MemberArticle>
    with AutomaticKeepAliveClientMixin, GridMixin {
  @override
  bool get wantKeepAlive => true;

  late final MemberArticleCtr _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      MemberArticleCtr(mid: widget.mid),
      tag: widget.heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: WindowsVideoTabService.enabled ? 18 : 0,
              top: WindowsVideoTabService.enabled ? 16 : 7,
              right: WindowsVideoTabService.enabled ? 18 : 0,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
            ),
            sliver: Obx(() => _buildBody(_controller.loadingState.value)),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(LoadingState<List<SpaceArticleItem>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
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
                  if (index == response.length - 1) {
                    _controller.onLoadMore();
                  }
                  return MemberArticleItem(
                    item: response[index],
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
