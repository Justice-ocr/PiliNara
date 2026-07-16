import 'package:PiliPlus/common/skeleton/video_card_h.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/view_sliver_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/sub/sub/list.dart';
import 'package:PiliPlus/pages/subscription/controller.dart';
import 'package:PiliPlus/pages/subscription/widgets/item.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SubPage extends StatefulWidget {
  const SubPage({super.key});

  @override
  State<SubPage> createState() => _SubPageState();
}

class _SubPageState extends State<SubPage> with GridMixin {
  final SubController _subController = Get.put(SubController());
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
      appBar: AppBar(title: const Text('我的订阅')),
      body: refreshIndicator(
        onRefresh: _subController.onRefresh,
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
                  () => _buildBody(_subController.loadingState.value),
                ),
              )
            else
              ViewSliverSafeArea(
                sliver: Obx(
                  () => _buildBody(_subController.loadingState.value),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<SubItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => SliverGrid.builder(
        gridDelegate: _effectiveGridDelegate,
        itemBuilder: (_, _) => const VideoCardHSkeleton(),
        itemCount: 10,
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: _effectiveGridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _subController.onLoadMore();
                  }
                  final item = response[index];
                  return SubItem(
                    item: item,
                    cancelSub: () => _subController.cancelSub(item),
                  );
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _subController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _subController.onReload,
      ),
    };
  }
}
