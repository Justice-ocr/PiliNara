import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models_new/pgc/pgc_index_result/list.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

// 视频卡片 - 垂直布局
class PgcCardVPgcIndex extends StatelessWidget {
  const PgcCardVPgcIndex({
    super.key,
    required this.item,
  });

  final PgcIndexItem item;

  @override
  Widget build(BuildContext context) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final radius = BorderRadius.circular(isWindowsNeo ? 6 : 10);
    void onLongPress() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
    );
    return Card(
      clipBehavior: isWindowsNeo ? Clip.antiAlias : Clip.none,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: isWindowsNeo
            ? BorderSide(color: context.windowsNeo.border)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () => PageUtils.viewPgc(seasonId: item.seasonId),
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  final double maxWidth = boxConstraints.maxWidth;
                  final double maxHeight = boxConstraints.maxHeight;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      NetworkImgLayer(
                        src: item.cover,
                        width: maxWidth,
                        height: maxHeight,
                      ),
                      PBadge(
                        text: item.badge,
                        top: 6,
                        right: 6,
                        bottom: null,
                        left: null,
                      ),
                      PBadge(
                        text: item.order,
                        top: null,
                        right: null,
                        bottom: 6,
                        left: 6,
                        type: PBadgeType.gray,
                      ),
                    ],
                  );
                },
              ),
            ),
            content(context),
          ],
        ),
      ),
    );
  }

  Widget content(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.title!,
              textAlign: TextAlign.start,
              style: const TextStyle(
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 1),
            if (item.indexShow != null)
              Text(
                item.indexShow!,
                maxLines: 1,
                style: TextStyle(
                  fontSize: theme.textTheme.labelMedium!.fontSize,
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
