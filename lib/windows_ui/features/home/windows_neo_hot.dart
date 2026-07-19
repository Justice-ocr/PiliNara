import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/home_tab_type.dart';
import 'package:PiliPlus/models/model_hot_video_item.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/hot/controller.dart';
import 'package:PiliPlus/pages/rank/view.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_horizontal_video_tile.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_state.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WindowsNeoHot extends StatelessWidget {
  const WindowsNeoHot({super.key, required this.controller});

  final HotController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return refreshIndicator(
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _HotDestinations(onRank: _openRank)),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              tokens.pagePadding,
              tokens.spaceMd,
              tokens.pagePadding,
              100,
            ),
            sliver: Obx(
              () => _buildBody(context, controller.loadingState.value),
            ),
          ),
        ],
      ),
    );
  }

  void _openRank() {
    try {
      final homeController = Get.find<HomeController>();
      final index = homeController.tabs.indexOf(HomeTabType.rank);
      if (index != -1) {
        homeController.tabController.animateTo(index);
        return;
      }
    } catch (_) {}
    Get.to(const Scaffold(body: RankPage()));
  }

  Widget _buildBody(
    BuildContext context,
    LoadingState<List<HotVideoItemModel>?> loadingState,
  ) {
    final tokens = context.windowsNeo;
    final delegate = SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 680,
      mainAxisExtent: tokens.horizontalCardHeight,
      mainAxisSpacing: tokens.gridGap,
      crossAxisSpacing: tokens.gridGap,
    );
    return switch (loadingState) {
      Loading() => WindowsNeoSliverLoadingPulse(
        sliver: SliverGrid.builder(
          gridDelegate: delegate,
          itemCount: 10,
          itemBuilder: (_, _) => const WindowsNeoHorizontalTileSkeleton(),
        ),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: delegate,
                itemCount: response.length,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) controller.onLoadMore();
                  return WindowsNeoStaggeredReveal(
                    order: index,
                    enabled: index < 8,
                    child: WindowsNeoHorizontalVideoTile(
                      videoItem: response[index],
                      onRemove: () => controller.loadingState
                        ..value.data!.removeAt(index)
                        ..refresh(),
                    ),
                  );
                },
              )
            : WindowsNeoSliverState(
                icon: Icons.inbox_outlined,
                title: '\u6682\u65f6\u6ca1\u6709\u70ed\u95e8\u5185\u5bb9',
                onRetry: controller.onReload,
              ),
      Error(:final errMsg) => WindowsNeoSliverState(
        icon: Icons.cloud_off_outlined,
        title: '\u70ed\u95e8\u52a0\u8f7d\u5931\u8d25',
        message: errMsg,
        onRetry: controller.onReload,
      ),
    };
  }
}

class _HotDestinations extends StatelessWidget {
  const _HotDestinations({required this.onRank});

  final VoidCallback onRank;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return ColoredBox(
      color: tokens.surface,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          tokens.pagePadding,
          tokens.spaceMd - 2,
          tokens.pagePadding,
          tokens.spaceMd - 2,
        ),
        child: Wrap(
          spacing: tokens.spaceSm,
          runSpacing: tokens.spaceSm,
          children: [
            _DestinationButton(
              icon: Icons.emoji_events_outlined,
              label: '\u6392\u884c\u699c',
              onPressed: onRank,
            ),
            _DestinationButton(
              icon: Icons.calendar_month_outlined,
              label: '\u6bcf\u5468\u5fc5\u770b',
              onPressed: () => Get.toNamed('/popularSeries'),
            ),
            _DestinationButton(
              icon: Icons.workspace_premium_outlined,
              label: '\u5165\u7ad9\u5fc5\u5237',
              onPressed: () => Get.toNamed('/popularPrecious'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18, color: tokens.accent),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: tokens.ink,
        backgroundColor: tokens.accentSoft,
        minimumSize: const Size(0, 36),
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
        shape: RoundedRectangleBorder(borderRadius: tokens.chipRadius),
        side: BorderSide(color: tokens.border),
      ),
    );
  }
}
