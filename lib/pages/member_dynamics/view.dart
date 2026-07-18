import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:PiliPlus/pages/member_dynamics/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/utils/waterfall.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart'
    hide SliverWaterfallFlowDelegateWithMaxCrossAxisExtent;

class MemberDynamicsPage extends StatefulWidget {
  const MemberDynamicsPage({super.key, this.mid});

  final int? mid;

  @override
  State<MemberDynamicsPage> createState() => _MemberDynamicsPageState();
}

class _MemberDynamicsPageState extends State<MemberDynamicsPage>
    with AutomaticKeepAliveClientMixin, DynMixin {
  late MemberDynamicsController _memberDynamicController;
  late int mid;
  final _windowsGridDelegate =
      SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 520,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      );

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    mid = widget.mid ?? int.parse(Get.parameters['mid']!);
    final String heroTag = Utils.makeHeroTag(mid);
    _memberDynamicController = Get.put(
      MemberDynamicsController(mid),
      tag: heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    return widget.mid == null
        ? Scaffold(
            backgroundColor: isWindowsNeo
                ? context.windowsNeo.background
                : null,
            resizeToAvoidBottomInset: false,
            appBar: AppBar(title: const Text('我的动态')),
            body: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                right: padding.right,
              ),
              child: _buildBody(padding),
            ),
          )
        : _buildBody(padding);
  }

  Widget _buildBody(EdgeInsets padding) => refreshIndicator(
    onRefresh: _memberDynamicController.onRefresh,
    child: CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.only(
            left: WindowsVideoTabService.enabled ? 18 : 0,
            top: WindowsVideoTabService.enabled && widget.mid == null ? 16 : 0,
            right: WindowsVideoTabService.enabled ? 18 : 0,
            bottom: padding.bottom + 100,
          ),
          sliver: buildPage(
            Obx(
              () => _buildContent(_memberDynamicController.loadingState.value),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildContent(LoadingState<List<DynamicItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => dynSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? GlobalData().dynamicsWaterfallFlow
                  ? SliverWaterfallFlow(
                      gridDelegate: WindowsVideoTabService.enabled
                          ? _windowsGridDelegate
                          : dynGridDelegate,
                      delegate: SliverChildBuilderDelegate(
                        (_, index) => _itemBuilder(response, index),
                        childCount: response.length,
                      ),
                    )
                  : SliverList.builder(
                      itemBuilder: (context, index) =>
                          _itemBuilder(response, index),
                      itemCount: response.length,
                    )
            : HttpError(onReload: _memberDynamicController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _memberDynamicController.onReload,
      ),
    };
  }

  Widget _itemBuilder(List<DynamicItemModel> list, int index) {
    if (index == list.length - 1) {
      _memberDynamicController.onLoadMore();
    }
    return DynamicPanel(
      item: list[index],
      onRemove: _memberDynamicController.onRemove,
      onSetTop: _memberDynamicController.onSetTop,
    );
  }
}
