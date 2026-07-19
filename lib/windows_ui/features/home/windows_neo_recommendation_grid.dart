import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/rcmd/controller.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_video_card_v.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_state.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WindowsNeoRecommendationGrid extends StatelessWidget {
  const WindowsNeoRecommendationGrid({
    super.key,
    required this.controller,
  });

  final RcmdController controller;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final meta = MediaQuery.textScalerOf(
      context,
    ).scale(tokens.videoCardMetaHeight);
    final gridDelegate = SliverGridDelegateWithExtentAndRatio(
      maxCrossAxisExtent: 300,
      mainAxisSpacing: tokens.gridGap,
      crossAxisSpacing: tokens.gridGap,
      childAspectRatio: Style.aspectRatio16x9,
      mainAxisExtent: meta,
    );

    return refreshIndicator(
      key: controller.refreshKey,
      onRefresh: controller.onRefresh,
      child: CustomScrollView(
        controller: controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              tokens.pagePadding,
              tokens.spaceMd,
              tokens.pagePadding,
              100,
            ),
            sliver: Obx(
              () => _buildBody(
                context,
                gridDelegate,
                controller.loadingState.value,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    SliverGridDelegate gridDelegate,
    LoadingState<List<dynamic>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => WindowsNeoSliverLoadingPulse(
        sliver: SliverGrid.builder(
          gridDelegate: gridDelegate,
          itemCount: 12,
          itemBuilder: (_, _) => const WindowsNeoVideoCardVSkeleton(),
        ),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: gridDelegate,
                itemCount: controller.lastRefreshAt == null
                    ? response.length
                    : response.length + 1,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    controller.onLoadMore();
                  }
                  final markerIndex = controller.lastRefreshAt;
                  if (markerIndex != null && index == markerIndex) {
                    return _LastRefreshMarker(
                      onPressed: () => controller
                        ..animateToTop()
                        ..onRefresh(),
                    );
                  }
                  final actualIndex = markerIndex != null && index > markerIndex
                      ? index - 1
                      : index;
                  return WindowsNeoStaggeredReveal(
                    order: index,
                    enabled: index < 10,
                    child: WindowsNeoVideoCardV(
                      videoItem: response[actualIndex],
                      onRemove: () {
                        if (controller.lastRefreshAt != null &&
                            actualIndex < controller.lastRefreshAt!) {
                          controller.lastRefreshAt =
                              controller.lastRefreshAt! - 1;
                        }
                        controller.loadingState
                          ..value.data!.removeAt(actualIndex)
                          ..refresh();
                      },
                    ),
                  );
                },
              )
            : WindowsNeoSliverState(
                icon: Icons.inbox_outlined,
                title: '\u6682\u65f6\u6ca1\u6709\u63a8\u8350\u5185\u5bb9',
                onRetry: controller.onReload,
              ),
      Error(:final errMsg) => WindowsNeoSliverState(
        icon: Icons.cloud_off_outlined,
        title: '\u63a8\u8350\u52a0\u8f7d\u5931\u8d25',
        message: errMsg,
        onRetry: controller.onReload,
      ),
    };
  }
}

class _LastRefreshMarker extends StatelessWidget {
  const _LastRefreshMarker({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return Material(
      color: tokens.accentSurface,
      borderRadius: tokens.cardRadius,
      child: InkWell(
        borderRadius: tokens.cardRadius,
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: tokens.cardRadius,
            border: Border.all(color: tokens.accent.withValues(alpha: 0.18)),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.refresh_outlined, color: tokens.accent),
                SizedBox(height: tokens.spaceSm),
                Text(
                  '\u4e0a\u6b21\u770b\u5230\u8fd9\u91cc',
                  style: tokens.cardTitleStyle(Theme.of(context).textTheme),
                ),
                SizedBox(height: tokens.spaceXs),
                Text(
                  '\u70b9\u51fb\u5237\u65b0',
                  style: tokens.cardCaptionStyle(Theme.of(context).textTheme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward-compatible alias.
typedef WindowsNeoRecommendationCard = WindowsNeoVideoCardV;
