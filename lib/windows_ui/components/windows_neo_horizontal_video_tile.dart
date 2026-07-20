import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/progress_bar/video_progress_indicator.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_h.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/horizontal_video_model.dart';
import 'package:PiliPlus/models_new/pgc/pgc_rank/pgc_rank_item_model.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_card_shell.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_media_meta.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

typedef WindowsNeoVideoCardH = WindowsNeoHorizontalVideoTile;

class WindowsNeoHorizontalVideoTile extends StatefulWidget {
  const WindowsNeoHorizontalVideoTile({
    super.key,
    required this.videoItem,
    this.onRemove,
  });

  final HorizontalVideoModel videoItem;
  final VoidCallback? onRemove;

  @override
  State<WindowsNeoHorizontalVideoTile> createState() =>
      _WindowsNeoHorizontalVideoTileState();
}

class _WindowsNeoHorizontalVideoTileState
    extends State<WindowsNeoHorizontalVideoTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.videoItem;
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;

    void saveCover() => imageSaveDialog(
      bvid: item.bvid,
      title: item.title,
      cover: item.cover,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: WindowsNeoCardShell(
        hovered: _hovered,
        onTap: () => VideoCardH.openDetail(item),
        onLongPress: saveCover,
        onSecondaryTap: saveCover,
        child: Row(
          children: [
            LayoutBuilder(
              builder: (context, outer) {
                final height = outer.maxHeight.isFinite && outer.maxHeight > 0
                    ? outer.maxHeight
                    : tokens.horizontalCardHeight;
                final idealW = height * 16 / 9;
                final maxW = outer.maxWidth.isFinite
                    ? outer.maxWidth * 0.52
                    : idealW;
                final width = idealW.clamp(0.0, maxW).toDouble();
                return SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimatedScale(
                        scale: _hovered ? 1.02 : 1,
                        duration: context.windowsNeoDuration(
                          tokens.motionFast,
                        ),
                        curve: Curves.easeOut,
                        child: NetworkImgLayer(
                          src: item.cover,
                          width: width,
                          height: height,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      if (item.badge case final badge?)
                        PBadge(text: badge, top: 8, left: 8),
                      if (item.progress case final progress?
                          when progress != 0) ...[
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: WindowsNeoMediaBadge(
                            text: progress == -1
                                ? '\u5df2\u770b\u5b8c'
                                : '${DurationUtils.formatDuration(progress)}/${DurationUtils.formatDuration(item.duration)}',
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: VideoProgressIndicator(
                            color: tokens.accent,
                            backgroundColor: tokens.border,
                            progress: progress == -1
                                ? 1
                                : item.duration > 0
                                ? progress / item.duration
                                : 0,
                          ),
                        ),
                      ] else if (item.duration > 0)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: WindowsNeoMediaBadge(
                            text: DurationUtils.formatDuration(item.duration),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const WindowsNeoMediaDivider(axis: Axis.vertical),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceMd,
                  tokens.spaceSm + 2,
                  tokens.spaceXs,
                  tokens.spaceSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Obx(() {
                        final key = item.bvid ?? item.aid?.toString();
                        final clicked =
                            key != null &&
                            VideoCardH.clickedBvids.contains(key);
                        return Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tokens
                              .cardTitleStyle(theme.textTheme)
                              .copyWith(
                                color: clicked ? tokens.muted : tokens.ink,
                              ),
                        );
                      }),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.owner.name ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tokens.cardMetaStyle(theme.textTheme),
                          ),
                        ),
                        SizedBox.square(
                          dimension: 28,
                          child: AnimatedOpacity(
                            opacity: _hovered ? 1 : 0.7,
                            duration: context.windowsNeoDuration(
                              tokens.motionFast,
                            ),
                            curve: Curves.easeOut,
                            child: VideoPopupMenu(
                              iconSize: 17,
                              menuItemHeight: 38,
                              videoItem: item,
                              onRemove: widget.onRemove,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spaceXs),
                    Row(
                      children: [
                        WindowsNeoStat(
                          type: StatType.play,
                          value: item.stat.view,
                        ),
                        SizedBox(width: tokens.spaceSm),
                        WindowsNeoStat(
                          type: StatType.danmaku,
                          value: item.stat.danmu,
                        ),
                        const Spacer(),
                        if (item.pubdate != null)
                          Text(
                            DateFormatUtils.dateFormat(item.pubdate),
                            style: tokens.cardCaptionStyle(theme.textTheme),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WindowsNeoPgcRankTile extends StatefulWidget {
  const WindowsNeoPgcRankTile({super.key, required this.item});

  final PgcRankItemModel item;

  @override
  State<WindowsNeoPgcRankTile> createState() => _WindowsNeoPgcRankTileState();
}

class WindowsNeoHorizontalTileSkeleton extends StatelessWidget {
  const WindowsNeoHorizontalTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border.all(color: tokens.border),
        borderRadius: tokens.cardRadius,
        boxShadow: tokens.cardShadow,
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final height =
                  constraints.maxHeight.isFinite && constraints.maxHeight > 0
                  ? constraints.maxHeight
                  : tokens.horizontalCardHeight;
              final width = (height * 16 / 9)
                  .clamp(0.0, constraints.maxWidth * 0.52)
                  .toDouble();
              return Row(
                children: [
                  SizedBox(
                    width: width,
                    height: height,
                    child: ColoredBox(color: tokens.hover),
                  ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.all(tokens.spaceMd),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(height: 13, color: tokens.hover),
                          SizedBox(height: tokens.spaceSm - 1),
                          FractionallySizedBox(
                            widthFactor: 0.72,
                            child: Container(height: 13, color: tokens.hover),
                          ),
                          const Spacer(),
                          FractionallySizedBox(
                            widthFactor: 0.48,
                            child: Container(height: 11, color: tokens.hover),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const Positioned(
            top: 0,
            left: 14,
            right: 14,
            child: WindowsNeoLoadingMarker(),
          ),
        ],
      ),
    );
  }
}

class _WindowsNeoPgcRankTileState extends State<WindowsNeoPgcRankTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tokens = context.windowsNeo;
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: WindowsNeoCardShell(
        hovered: _hovered,
        onTap: () {
          if (item.url != null) PiliScheme.routePushFromUrl(item.url!);
        },
        onLongPress: () => imageSaveDialog(
          title: item.title,
          cover: item.cover,
        ),
        onSecondaryTap: () => imageSaveDialog(
          title: item.title,
          cover: item.cover,
        ),
        child: Row(
          children: [
            LayoutBuilder(
              builder: (context, outer) {
                final height = outer.maxHeight.isFinite && outer.maxHeight > 0
                    ? outer.maxHeight
                    : tokens.horizontalCardHeight;
                final width = (height * 3 / 4)
                    .clamp(
                      0.0,
                      outer.maxWidth * 0.42,
                    )
                    .toDouble();
                return SizedBox(
                  width: width,
                  height: height,
                  child: NetworkImgLayer(
                    width: width,
                    height: height,
                    src: item.cover,
                    borderRadius: BorderRadius.zero,
                  ),
                );
              },
            ),
            const WindowsNeoMediaDivider(axis: Axis.vertical),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceMd),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.cardTitleStyle(theme.textTheme),
                      ),
                    ),
                    if (item.newEp?.indexShow?.isNotEmpty == true)
                      Text(
                        item.newEp!.indexShow!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tokens.cardMetaStyle(theme.textTheme),
                      ),
                    SizedBox(height: tokens.spaceSm),
                    Row(
                      children: [
                        WindowsNeoStat(
                          type: StatType.play,
                          value: item.stat?.view,
                        ),
                        SizedBox(width: tokens.spaceMd - 2),
                        WindowsNeoStat(
                          type: StatType.follow,
                          value: item.stat?.follow,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
