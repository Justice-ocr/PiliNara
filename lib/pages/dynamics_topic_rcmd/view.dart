import 'dart:math' show max;

import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/view_sliver_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/dynamic/dyn_topic_top/topic_item.dart';
import 'package:PiliPlus/pages/dynamics_select_topic/widgets/item.dart';
import 'package:PiliPlus/pages/dynamics_topic_rcmd/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DynTopicRcmdPage extends StatefulWidget {
  const DynTopicRcmdPage({super.key});

  @override
  State<DynTopicRcmdPage> createState() => _DynTopicRcmdPageState();
}

class _DynTopicRcmdPageState extends State<DynTopicRcmdPage> {
  final DynTopicRcmdController _controller = Get.put(DynTopicRcmdController());

  @override
  Widget build(BuildContext context) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final horizontalPadding = max(
      18.0,
      (MediaQuery.sizeOf(context).width - 820) / 2,
    );
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('话题')),
      body: refreshIndicator(
        onRefresh: _controller.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (isWindowsNeo)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  MediaQuery.viewPaddingOf(context).bottom + 100,
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

  Widget _buildBody(LoadingState<List<TopicItem>?> loadingState) {
    return switch (loadingState) {
      Loading() => linearLoading,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverList.separated(
                itemCount: response.length,
                itemBuilder: (context, index) {
                  return DynTopicItem(
                    item: response[index],
                    onTap: (item) => Get.toNamed(
                      '/dynTopic',
                      parameters: {
                        'id': item.id.toString(),
                        'name': item.name,
                      },
                    ),
                  );
                },
                separatorBuilder: (_, _) => WindowsVideoTabService.enabled
                    ? Divider(height: 1, color: context.windowsNeo.border)
                    : const SizedBox.shrink(),
              )
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }
}
