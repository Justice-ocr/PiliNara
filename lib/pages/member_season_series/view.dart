import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/member/contribute_type.dart';
import 'package:PiliPlus/models_new/space/space_season_series/season.dart'
    show SpaceSsModel;
import 'package:PiliPlus/pages/member_season_series/controller.dart';
import 'package:PiliPlus/pages/member_season_series/widget/season_series_card.dart';
import 'package:PiliPlus/pages/member_video/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SeasonSeriesPage extends StatefulWidget {
  const SeasonSeriesPage({
    super.key,
    required this.mid,
    this.heroTag,
  });

  final int mid;
  final String? heroTag;

  @override
  State<SeasonSeriesPage> createState() => _SeasonSeriesPageState();
}

class _SeasonSeriesPageState extends State<SeasonSeriesPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final SeasonSeriesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      SeasonSeriesController(widget.mid),
      tag: widget.heroTag,
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            left: WindowsVideoTabService.enabled ? 18 : 0,
            top: WindowsVideoTabService.enabled ? 16 : 0,
            right: WindowsVideoTabService.enabled ? 18 : 0,
            bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
          ),
          sliver: Obx(
            () => _buildBody(_controller.loadingState.value),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(LoadingState<List<SpaceSsModel>?> loadingState) {
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
                  SpaceSsModel item = response[index];
                  return SeasonSeriesCard(
                    item: item,
                    onTap: () {
                      bool isSeason = item.meta!.seasonId != null;
                      dynamic id = isSeason
                          ? item.meta!.seasonId
                          : item.meta!.seriesId;
                      Get.to(
                        Scaffold(
                          backgroundColor: WindowsVideoTabService.enabled
                              ? context.windowsNeo.background
                              : null,
                          resizeToAvoidBottomInset: false,
                          appBar: AppBar(title: Text(item.meta!.name!)),
                          body: ViewSafeArea(
                            child: MemberVideo(
                              type: isSeason
                                  ? ContributeType.season
                                  : ContributeType.series,
                              heroTag: widget.heroTag,
                              mid: widget.mid,
                              seasonId: isSeason ? id : null,
                              seriesId: isSeason ? null : id,
                              title: item.meta!.name,
                            ),
                          ),
                        ),
                      );
                    },
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
