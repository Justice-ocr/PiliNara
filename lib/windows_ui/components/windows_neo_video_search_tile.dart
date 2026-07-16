import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/progress_bar/video_progress_indicator.dart';
import 'package:PiliPlus/common/widgets/stat/stat.dart';
import 'package:PiliPlus/common/widgets/video_popup_menu.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/models/search/result.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/duration_utils.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class WindowsNeoVideoSearchTile extends StatelessWidget {
  const WindowsNeoVideoSearchTile({
    super.key,
    required this.videoItem,
    this.onRemove,
  });

  final SearchVideoItemModel videoItem;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    return Material(
      color: tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: InkWell(
              hoverColor: tokens.hover,
              onTap: _openVideo,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCover(theme),
                    const SizedBox(width: 12),
                    Expanded(child: _buildContent(context)),
                    const SizedBox(width: 24),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            width: 30,
            height: 30,
            child: VideoPopupMenu(
              iconSize: 17,
              videoItem: videoItem,
              onRemove: onRemove,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCover(ThemeData theme) {
    const width = 168.0;
    const height = 94.5;
    final progress = videoItem.progress;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          const SizedBox.expand(),
          NetworkImgLayer(
            src: videoItem.cover,
            width: width,
            height: height,
            borderRadius: BorderRadius.circular(5),
          ),
          if (videoItem.badge case final badge?)
            PBadge(text: badge, top: 6, left: 6, type: PBadgeType.primary),
          if (progress != null && progress != 0) ...[
            PBadge(
              text: progress == -1
                  ? '已看完'
                  : '${DurationUtils.formatDuration(progress)}/'
                        '${DurationUtils.formatDuration(videoItem.duration)}',
              right: 6,
              bottom: 7,
              type: PBadgeType.gray,
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.secondaryContainer,
                progress: progress == -1 ? 1 : progress / videoItem.duration,
              ),
            ),
          ] else if (videoItem.duration > 0)
            PBadge(
              text: DurationUtils.formatDuration(videoItem.duration),
              right: 6,
              bottom: 6,
              type: PBadgeType.gray,
            ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    final pubdate = videoItem.pubdate == null
        ? ''
        : DateFormatUtils.dateFormat(videoItem.pubdate!);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (videoItem.titleList?.isNotEmpty == true)
          Text.rich(
            TextSpan(
              children: videoItem.titleList!
                  .map(
                    (part) => TextSpan(
                      text: part.text,
                      style: TextStyle(
                        color: part.isEm
                            ? tokens.accent
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  )
                  .toList(),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          )
        else
          Text(
            videoItem.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        const Spacer(),
        Text(
          [
            if (videoItem.owner.name?.isNotEmpty == true) videoItem.owner.name!,
            if (pubdate.isNotEmpty) pubdate,
          ].join('  ·  '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
        ),
        const SizedBox(height: 6),
        Row(
          spacing: 12,
          children: [
            StatWidget(type: StatType.play, value: videoItem.stat.view),
            StatWidget(type: StatType.danmaku, value: videoItem.stat.danmu),
          ],
        ),
      ],
    );
  }

  Future<void> _openVideo() async {
    if (videoItem.isPugv ?? false) {
      PageUtils.viewPugv(seasonId: videoItem.seasonId);
      return;
    }
    if (videoItem.isLive ?? false) {
      PageUtils.toLiveRoom(videoItem.roomId);
      return;
    }
    if (videoItem.redirectUrl?.isNotEmpty == true &&
        PageUtils.viewPgcFromUri(videoItem.redirectUrl!)) {
      return;
    }

    var cid = videoItem.cid;
    var dimension = videoItem.dimension;
    if (cid == null) {
      if (await SearchHttp.ab2cWithDimension(
            aid: videoItem.aid,
            bvid: videoItem.bvid,
          )
          case final response?) {
        cid = response.cid;
        dimension = response.dimension;
      }
    }
    if (cid != null) {
      PageUtils.toVideoPage(
        bvid: videoItem.bvid,
        cid: cid,
        cover: videoItem.cover,
        title: videoItem.title,
        dimension: dimension,
      );
    }
  }
}
