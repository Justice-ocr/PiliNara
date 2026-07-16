import 'package:PiliPlus/common/skeleton/skeleton.dart';
import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_card/video_card_v.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/home/rcmd/result.dart';
import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_card_shell.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

/// Canonical vertical video card for Windows Neo grids (recommend/search-like).
class WindowsNeoVideoCardV extends StatefulWidget {
  const WindowsNeoVideoCardV({
    super.key,
    required this.videoItem,
    this.onRemove,
  });

  final BaseRcmdVideoItemModel videoItem;
  final VoidCallback? onRemove;

  @override
  State<WindowsNeoVideoCardV> createState() => _WindowsNeoVideoCardVState();
}

class _WindowsNeoVideoCardVState extends State<WindowsNeoVideoCardV> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    final item = widget.videoItem;
    final detailAction = VideoCardV(videoItem: item).onPushDetail;
    final metaHeight = MediaQuery.textScalerOf(
      context,
    ).scale(tokens.videoCardMetaHeight);

    void saveCover() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
      bvid: item.bvid,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: WindowsNeoCardShell(
        hovered: _hovered,
        onTap: detailAction,
        onLongPress: saveCover,
        onSecondaryTap: saveCover,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) => AnimatedScale(
                      scale: _hovered ? 1.02 : 1,
                      duration: tokens.motionFast,
                      curve: Curves.easeOut,
                      child: NetworkImgLayer(
                        src: item.cover,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                  ),
                  Positioned(
                    left: tokens.spaceSm,
                    right: tokens.spaceSm,
                    bottom: 7,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (item.duration > 0)
                          PBadge(
                            text: DurationUtils.formatDuration(item.duration),
                            isStack: false,
                            size: .small,
                            type: .gray,
                          ),
                        const Spacer(),
                        if (item case RcmdVideoItemAppModel(
                          :final canPlay,
                        ) when canPlay != 1)
                          const PBadge(
                            text: '\u5145\u7535\u4e13\u5c5e',
                            isStack: false,
                            size: .small,
                            type: .error,
                            fontSize: 10,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: metaHeight,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  tokens.spaceSm + 2,
                  tokens.spaceSm,
                  tokens.spaceXs,
                  tokens.spaceSm - 1,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 26),
                        child: Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: tokens.cardTitleStyle(theme.textTheme),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(child: _OwnerAndReason(item: item)),
                        if (item.goto == 'av')
                          SizedBox.square(
                            dimension: 28,
                            child: AnimatedOpacity(
                              opacity: _hovered ? 1 : 0.72,
                              duration: tokens.motionFast,
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
                    SizedBox(height: tokens.spaceXs - 1),
                    Row(
                      children: [
                        StatWidget(
                          type: StatType.play,
                          value: item.stat.view,
                        ),
                        if (item.goto != 'picture') ...[
                          SizedBox(width: tokens.spaceSm),
                          StatWidget(
                            type: StatType.danmaku,
                            value: item.stat.danmu,
                          ),
                        ],
                        const Spacer(),
                        if (item is RcmdVideoItemModel && item.pubdate != null)
                          Text(
                            DateFormatUtils.dateFormat(
                              item.pubdate,
                              short: VideoCardV.shortFormat,
                              long: VideoCardV.longFormat,
                            ),
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

class WindowsNeoVideoCardVSkeleton extends StatelessWidget {
  const WindowsNeoVideoCardVSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final metaHeight = MediaQuery.textScalerOf(
      context,
    ).scale(tokens.videoCardMetaHeight);
    return Skeleton(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          border: Border.all(color: tokens.border),
          borderRadius: tokens.cardRadius,
        ),
        child: Column(
          children: [
            Expanded(child: ColoredBox(color: tokens.hover)),
            SizedBox(
              height: metaHeight,
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceSm + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, color: tokens.hover),
                    SizedBox(height: tokens.spaceSm - 1),
                    FractionallySizedBox(
                      widthFactor: 0.72,
                      child: Container(height: 12, color: tokens.hover),
                    ),
                    const Spacer(),
                    FractionallySizedBox(
                      widthFactor: 0.48,
                      child: Container(height: 10, color: tokens.hover),
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

class _OwnerAndReason extends StatelessWidget {
  const _OwnerAndReason({required this.item});

  final BaseRcmdVideoItemModel item;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final reason = Pref.showRcmdReason ? item.rcmdReason : null;
    return Row(
      children: [
        if (item.goto == 'bangumi' && item.pgcBadge?.isNotEmpty == true) ...[
          PBadge(
            text: item.pgcBadge,
            isStack: false,
            size: .small,
            type: .line_primary,
            fontSize: 9,
          ),
          SizedBox(width: tokens.spaceXs + 1),
        ] else if (item.goto == 'picture') ...[
          const PBadge(
            text: '\u52a8\u6001',
            isStack: false,
            size: .small,
            type: .line_primary,
            fontSize: 9,
          ),
          SizedBox(width: tokens.spaceXs + 1),
        ] else if (reason?.isNotEmpty == true) ...[
          PBadge(
            text: reason,
            isStack: false,
            size: .small,
            type: .secondary,
          ),
          SizedBox(width: tokens.spaceXs + 1),
        ] else if (item.isFollowed) ...[
          const PBadge(
            text: '\u5df2\u5173\u6ce8',
            isStack: false,
            size: .small,
            type: .secondary,
          ),
          SizedBox(width: tokens.spaceXs + 1),
        ],
        Expanded(
          child: Text(
            item.owner.name ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: tokens.cardMetaStyle(Theme.of(context).textTheme),
          ),
        ),
      ],
    );
  }
}
