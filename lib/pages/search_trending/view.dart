import 'dart:math';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/sliver/trending_header.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/search/search_trending/list.dart';
import 'package:PiliPlus/pages/search_trending/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/color_utils.dart';
import 'package:PiliPlus/utils/extension/context_ext.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_state.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_trending_kit.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class SearchTrendingPage extends StatefulWidget {
  const SearchTrendingPage({super.key, this.controllerTag});

  final String? controllerTag;

  @override
  State<SearchTrendingPage> createState() => _SearchTrendingPageState();
}

class _SearchTrendingPageState extends State<SearchTrendingPage> {
  late final SearchTrendingController _controller;
  late final String _controllerTag;

  late double _offset;
  final RxDouble _scrollRatio = 0.0.obs;

  @override
  void initState() {
    super.initState();
    _controllerTag = widget.controllerTag ?? Utils.generateRandomString(8);
    _controller = Get.put(
      SearchTrendingController(),
      tag: _controllerTag,
    );
  }

  @override
  void dispose() {
    Get.delete<SearchTrendingController>(tag: _controllerTag);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final size = context.mediaQuerySize;
    final maxWidth = size.width - padding.horizontal;
    final isWindowsNeo = WindowsVideoTabService.enabled;
    if (isWindowsNeo) {
      return _buildWindowsNeoPage(context, theme, padding);
    }
    final width = size.isPortrait ? maxWidth : min(640.0, maxWidth * 0.6);
    final height = width * 528 / 1125;
    _offset = height - 56 - padding.top;
    return Material(
      child: Stack(
        children: [
          Padding(
            padding: .only(left: padding.left, right: padding.right),
            child: Center(
              child: SizedBox(
                width: width,
                child: refreshIndicator(
                  onRefresh: _controller.onRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      TrendingHeader(
                        offset: _offset,
                        onScrollRatioChanged: _scrollRatio.call,
                        child: Image.asset(
                          width: width,
                          height: height,
                          gaplessPlayback: true,
                          cacheWidth: width.cacheSize(context),
                          Assets.trendingBanner,
                          filterQuality: .low,
                        ),
                      ),
                      SliverPadding(
                        padding: .only(bottom: padding.bottom + 100),
                        sliver: Obx(
                          () =>
                              _buildBody(theme, _controller.loadingState.value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: Obx(
              () {
                final scrollRatio = _scrollRatio.value;
                final flag = maxWidth > width || scrollRatio >= 0.5;
                return AppBar(
                  title: Opacity(
                    opacity: scrollRatio,
                    child: Text(
                      'bilibili热搜',
                      style: TextStyle(
                        color: flag ? null : Colors.white,
                      ),
                    ),
                  ),
                  backgroundColor: theme.colorScheme.surface.withValues(
                    alpha: scrollRatio,
                  ),
                  foregroundColor: flag ? null : Colors.white,
                  systemOverlayStyle: flag
                      ? null
                      : const SystemUiOverlayStyle(
                          statusBarBrightness: Brightness.dark,
                          statusBarIconBrightness: Brightness.light,
                        ),
                  shape: scrollRatio == 1
                      ? Border(
                          bottom: BorderSide(
                            color: theme.colorScheme.outline.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    ThemeData theme,
    LoadingState<List<SearchTrendingItemModel>?> loadingState,
  ) {
    switch (loadingState) {
      case Loading():
        return linearLoading;
      case Success(:final response):
        if (response != null && response.isNotEmpty) {
          final divider = Divider(
            height: 1,
            indent: 48,
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          );
          return SliverList.separated(
            itemCount: response.length,
            itemBuilder: (context, index) {
              final item = response[index];
              return ListTile(
                dense: true,
                onTap: () => PageUtils.toSearchResult(item.keyword),
                leading: index < _controller.topCount
                    ? const Icon(
                        size: 17,
                        Icons.vertical_align_top_outlined,
                        color: Color(0xFFd1403e),
                      )
                    : Text(
                        '${index + 1 - _controller.topCount}',
                        style: TextStyle(
                          fontWeight: .bold,
                          color: ColourUtils.index2Color(
                            index - _controller.topCount,
                            theme.colorScheme.outline,
                          ),
                          fontSize: 17,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                title: Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.showName,
                        maxLines: 1,
                        overflow: .ellipsis,
                        strutStyle: const StrutStyle(height: 1, leading: 0),
                        style: const TextStyle(height: 1, fontSize: 15),
                      ),
                    ),
                    if (item.icon?.isNotEmpty == true) ...[
                      const SizedBox(width: 4),
                      CachedNetworkImage(
                        height: 16,
                        memCacheHeight: 16.cacheSize(context),
                        imageUrl: ImageUtils.thumbnailUrl(item.icon!),
                        placeholder: (_, _) => const SizedBox.shrink(),
                      ),
                    ] else if (item.showLiveIcon == true) ...[
                      const SizedBox(width: 4),
                      Image.asset(
                        Assets.livingRect,
                        width: 51,
                        height: 16,
                        cacheHeight: 16.cacheSize(context),
                      ),
                    ],
                  ],
                ),
              );
            },
            separatorBuilder: (context, index) => divider,
          );
        }
        return HttpError(onReload: _controller.onReload);
      case Error(:final errMsg):
        return HttpError(
          errMsg: errMsg,
          onReload: _controller.onReload,
        );
    }
  }

  void _openTrendingKeyword(String keyword) {
    WindowsNeoSearchHistoryStore.record(keyword);
    PageUtils.toSearchResult(keyword);
  }

  Widget _buildWindowsNeoPage(
    BuildContext context,
    ThemeData theme,
    EdgeInsets padding,
  ) {
    final tokens = context.windowsNeo;
    return Scaffold(
      backgroundColor: tokens.background,
      body: WindowsNeoPage(
        title: '实时热搜榜',
        subtitle: 'Bilibili 全站实时热度榜单 · 点击词条直达搜索',
        leading: const Icon(
          Icons.local_fire_department_rounded,
          size: 20,
          color: Color(0xFFFF5A5F),
        ),
        actions: [
          IconButton(
            tooltip: '刷新榜单',
            onPressed: _controller.onRefresh,
            icon: const Icon(Icons.refresh_rounded, size: 19),
          ),
          IconButton(
            tooltip: '打开高级搜索页',
            onPressed: () => PageUtils.toSearch(),
            icon: const Icon(Icons.search_rounded, size: 19),
          ),
          const SizedBox(width: 4),
        ],
        child: refreshIndicator(
          onRefresh: _controller.onRefresh,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontal = constraints.maxWidth > 1160
                  ? (constraints.maxWidth - 1120) / 2
                  : 20.0;
              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      horizontal,
                      18,
                      horizontal,
                      padding.bottom + 48,
                    ),
                    sliver: Obx(
                      () => _buildWindowsNeoSliverBody(
                        context,
                        theme,
                        _controller.loadingState.value,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWindowsNeoSliverBody(
    BuildContext context,
    ThemeData theme,
    LoadingState<List<SearchTrendingItemModel>?> loadingState,
  ) {
    final tokens = context.windowsNeo;
    return switch (loadingState) {
      Loading() => SliverToBoxAdapter(
        child: Column(
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0) const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 112,
                      decoration: BoxDecoration(
                        color: tokens.hover.withValues(alpha: 0.55),
                        borderRadius: tokens.cardRadius,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < 8; i++) ...[
              Container(
                height: 48,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: tokens.hover.withValues(alpha: 0.42),
                  borderRadius: tokens.cardRadius,
                ),
              ),
            ],
          ],
        ),
      ),
      Error(:final errMsg) => WindowsNeoSliverState(
        icon: Icons.cloud_off_outlined,
        title: '热搜榜加载失败',
        message: errMsg ?? '请检查网络后重试',
        onRetry: _controller.onReload,
      ),
      Success(:final response) => () {
        if (response == null || response.isEmpty) {
          return WindowsNeoSliverState(
            icon: Icons.local_fire_department_outlined,
            title: '暂无实时热搜',
            message: '点击重试获取最新热度榜单',
            onRetry: _controller.onReload,
          );
        }
        final topCount = _controller.topCount.clamp(0, response.length);
        final pinned = response.take(topCount).toList(growable: false);
        final ranked = response.skip(topCount).toList(growable: false);
        final podium = ranked.take(3).toList(growable: false);
        final rest = ranked.skip(3).toList(growable: false);

        return SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (pinned.isNotEmpty) ...[
                for (final item in pinned)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _WindowsTrendingPinnedBanner(
                      item: item,
                      onTap: () => _openTrendingKeyword(item.keyword),
                    ),
                  ),
                const SizedBox(height: 6),
              ],
              if (podium.isNotEmpty) ...[
                Row(
                  children: [
                    Container(width: 3, height: 15, color: const Color(0xFFFF5A5F)),
                    const SizedBox(width: 8),
                    Text(
                      'TOP 3 焦点热度',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: tokens.ink,
                        fontWeight: FontWeight.w800,
                        fontFamilyFallback: tokens.displayFontFallback,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 680;
                    if (wide) {
                      return Row(
                        children: [
                          for (var i = 0; i < podium.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(
                              child: _WindowsTrendingPodiumCard(
                                item: podium[i],
                                rank: i + 1,
                                onTap: () =>
                                    _openTrendingKeyword(podium[i].keyword),
                              ),
                            ),
                          ],
                        ],
                      );
                    }
                    return Column(
                      children: [
                        for (var i = 0; i < podium.length; i++) ...[
                          if (i > 0) const SizedBox(height: 10),
                          _WindowsTrendingPodiumCard(
                            item: podium[i],
                            rank: i + 1,
                            onTap: () =>
                                _openTrendingKeyword(podium[i].keyword),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
              if (rest.isNotEmpty) ...[
                Row(
                  children: [
                    Container(width: 3, height: 15, color: tokens.accentInk),
                    const SizedBox(width: 8),
                    Text(
                      '实时飙升与全站排行',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: tokens.ink,
                        fontWeight: FontWeight.w800,
                        fontFamilyFallback: tokens.displayFontFallback,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '共 ${ranked.length} 条',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final twoCol = constraints.maxWidth >= 700;
                    const gap = 10.0;
                    final width = twoCol
                        ? (constraints.maxWidth - gap) / 2
                        : constraints.maxWidth;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        for (var i = 0; i < rest.length; i++)
                          SizedBox(
                            width: width,
                            child: _WindowsTrendingRowCard(
                              item: rest[i],
                              rank: i + 4,
                              onTap: () =>
                                  _openTrendingKeyword(rest[i].keyword),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ],
          ),
        );
      }(),
    };
  }
}

class _WindowsTrendingPinnedBanner extends StatefulWidget {
  const _WindowsTrendingPinnedBanner({
    required this.item,
    required this.onTap,
  });

  final SearchTrendingItemModel item;
  final VoidCallback onTap;

  @override
  State<_WindowsTrendingPinnedBanner> createState() =>
      _WindowsTrendingPinnedBannerState();
}

class _WindowsTrendingPinnedBannerState
    extends State<_WindowsTrendingPinnedBanner> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? tokens.accentSurface : tokens.surfaceRaised,
        borderRadius: tokens.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: tokens.cardRadius,
              border: Border.all(
                color: _hovered
                    ? const Color(0xFFFF5A5F).withValues(alpha: 0.72)
                    : tokens.border.withValues(alpha: 0.52),
              ),
            ),
            child: Row(
              children: [
                WindowsNeoTrendingTag(item: widget.item, isPinned: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.item.showName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: tokens.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: _hovered ? tokens.accentInk : tokens.muted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowsTrendingPodiumCard extends StatefulWidget {
  const _WindowsTrendingPodiumCard({
    required this.item,
    required this.rank,
    required this.onTap,
  });

  final SearchTrendingItemModel item;
  final int rank;
  final VoidCallback onTap;

  @override
  State<_WindowsTrendingPodiumCard> createState() =>
      _WindowsTrendingPodiumCardState();
}

class _WindowsTrendingPodiumCardState
    extends State<_WindowsTrendingPodiumCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final theme = Theme.of(context);
    final rankColor = WindowsNeoTrendingRank.colorForRank(widget.rank, tokens);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: context.windowsNeoDuration(tokens.motionFast),
        decoration: BoxDecoration(
          color: _hovered ? tokens.accentSurface : tokens.surfaceRaised,
          borderRadius: tokens.cardRadius,
          border: Border.all(
            color: _hovered
                ? rankColor.withValues(alpha: 0.78)
                : tokens.border.withValues(alpha: 0.56),
            width: _hovered ? 1.4 : 1,
          ),
          boxShadow: _hovered ? tokens.cardHoverShadow : tokens.cardShadow,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: tokens.cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: SizedBox(
              height: 112,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: Container(height: 3, color: rankColor),
                  ),
                  Positioned(
                    right: 12,
                    top: 6,
                    child: Text(
                      widget.rank.toString().padLeft(2, '0'),
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: rankColor.withValues(
                          alpha: tokens.isDarkSurface ? 0.16 : 0.13,
                        ),
                        fontWeight: FontWeight.w900,
                        fontFamilyFallback: tokens.displayFontFallback,
                        height: 1,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'TOP 0${widget.rank}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: rankColor,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.1,
                                fontFamilyFallback: tokens.displayFontFallback,
                              ),
                            ),
                            const SizedBox(width: 8),
                            WindowsNeoTrendingTag(item: widget.item),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Text(
                            widget.item.showName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: tokens.ink,
                              fontWeight: FontWeight.w700,
                              height: 1.32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WindowsTrendingRowCard extends StatefulWidget {
  const _WindowsTrendingRowCard({
    required this.item,
    required this.rank,
    required this.onTap,
  });

  final SearchTrendingItemModel item;
  final int rank;
  final VoidCallback onTap;

  @override
  State<_WindowsTrendingRowCard> createState() =>
      _WindowsTrendingRowCardState();
}

class _WindowsTrendingRowCardState extends State<_WindowsTrendingRowCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? tokens.accentSurface : tokens.surfaceRaised,
        borderRadius: tokens.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: context.windowsNeoDuration(tokens.motionFast),
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: tokens.cardRadius,
              border: Border.all(
                color: _hovered
                    ? tokens.accentBorder.withValues(alpha: 0.72)
                    : tokens.border.withValues(alpha: 0.46),
              ),
            ),
            child: Row(
              children: [
                WindowsNeoTrendingRank(
                  rank: widget.rank,
                  fontSize: 13.5,
                  width: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.item.showName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                WindowsNeoTrendingTag(item: widget.item),
                if (_hovered) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.north_east_rounded,
                    size: 14,
                    color: tokens.accentInk,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
