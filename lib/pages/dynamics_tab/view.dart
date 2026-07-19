import 'dart:async';

import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/dynamics/widgets/dynamic_panel.dart';
import 'package:PiliPlus/pages/dynamics_tab/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/waterfall.dart';
import 'package:PiliPlus/windows_ui/features/dynamics/windows_neo_dynamics_layout.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart'
    hide SliverWaterfallFlowDelegateWithMaxCrossAxisExtent;

class DynamicsTabPage extends StatefulWidget {
  const DynamicsTabPage({super.key, required this.dynamicsType});

  final DynamicsTabType dynamicsType;

  @override
  State<DynamicsTabPage> createState() => _DynamicsTabPageState();
}

class _DynamicsTabPageState extends State<DynamicsTabPage>
    with AutomaticKeepAliveClientMixin, DynMixin {
  StreamSubscription? _listener;

  DynamicsController dynamicsController = Get.putOrFind(DynamicsController.new);
  late final DynamicsTabController controller;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    controller = Get.putOrFind(
      () =>
          DynamicsTabController(dynamicsType: widget.dynamicsType)
            ..mid = dynamicsController.mid.value,
      tag: widget.dynamicsType.name,
    );
    super.initState();
    if (widget.dynamicsType == DynamicsTabType.up) {
      _listener = dynamicsController.mid.listen((mid) {
        if (mid != -1) {
          controller
            ..mid = mid
            ..onReload();
        }
      });
    }
  }

  @override
  void dispose() {
    _listener?.cancel();
    dynamicsController.mid.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return refreshIndicator(
      key: controller.refreshKey,
      onRefresh: () {
        dynamicsController.queryFollowUp();
        return controller.onRefresh();
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: controller.scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: WindowsVideoTabService.enabled
                ? _buildWindowsPage(
                    Obx(
                      () => WindowsNeoSliverContentTransition(
                        token: controller.loadingState.value,
                        sliver: _buildBody(controller.loadingState.value),
                      ),
                    ),
                  )
                : buildPage(
                    Obx(() => _buildBody(controller.loadingState.value)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsPage(Widget child) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.crossAxisExtent;
        final horizontal = WindowsNeoDynamicsLayout.horizontalPadding(
          available,
        );
        return SliverPadding(
          padding: EdgeInsets.only(
            left: horizontal,
            right: horizontal,
            top: 18,
          ),
          sliver: child,
        );
      },
    );
  }

  Widget _buildBody(LoadingState<List<DynamicItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => dynSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? _buildLoaded(response)
            : HttpError(onReload: controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: controller.onReload,
      ),
    };
  }

  Widget _buildLoaded(List<DynamicItemModel> response) {
    if (WindowsVideoTabService.enabled) {
      return SliverLayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.crossAxisExtent;
          final crossAxisCount = WindowsNeoDynamicsLayout.crossAxisCount(
            width,
          );
          return SliverWaterfallFlow(
            gridDelegate: SliverWaterfallFlowDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: WindowsNeoDynamicsLayout.gridSpacing,
              mainAxisSpacing: WindowsNeoDynamicsLayout.gridSpacing,
            ),
            delegate: _buildDelegate(response),
          );
        },
      );
    }
    if (GlobalData().dynamicsWaterfallFlow) {
      return SliverWaterfallFlow(
        gridDelegate: dynGridDelegate,
        delegate: _buildDelegate(response),
      );
    }
    return SliverList.builder(
      itemBuilder: (_, index) => _buildItem(response, index),
      itemCount: response.length,
    );
  }

  SliverChildBuilderDelegate _buildDelegate(
    List<DynamicItemModel> response,
  ) => SliverChildBuilderDelegate(
    (_, index) => _buildItem(response, index),
    childCount: response.length,
  );

  Widget _buildItem(List<DynamicItemModel> response, int index) {
    if (index == response.length - 1) {
      controller.onLoadMore();
    }
    final item = response[index];
    final panel = DynamicPanel(
      item: item,
      onRemove: (idStr) => controller.onRemove(index, idStr),
      onBlock: () => controller.onBlock(index),
      onUnfold: () => controller.onUnfold(item, index),
      onUpdate: (newItem) {
        response[index] = newItem;
        controller.loadingState.refresh();
      },
    );
    if (!WindowsVideoTabService.enabled) return panel;
    return WindowsNeoStaggeredReveal(
      order: index,
      enabled: index < 6,
      child: panel,
    );
  }
}
