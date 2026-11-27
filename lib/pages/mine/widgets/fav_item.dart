import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/fav/fav_folder/list.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_media_meta.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:material_ui/material_ui.dart';

class FavFolderItem extends StatelessWidget {
  const FavFolderItem({
    super.key,
    required this.item,
    required this.onPop,
  });

  final FavFolderInfo item;
  final VoidCallback onPop;

  @override
  Widget build(BuildContext context) {
    final heroTag = 'fav-folder-${item.id}';
    final theme = Theme.of(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    void openDetail() {
      PageUtils.toDupNamed(
        '/favDetail',
        arguments: item,
        parameters: {
          'mediaId': item.id.toString(),
          'heroTag': heroTag,
        },
      )?.whenComplete(onPop);
    }

    if (isWindowsNeo) {
      final tokens = context.windowsNeo;
      return GestureDetector(
        onTap: openDetail,
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: tokens.border.withValues(alpha: 0.45),
                borderRadius: BorderRadius.vertical(
                  top: tokens.cardRadius.topLeft,
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: 180,
              height: 104,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: tokens.cardRadius,
                  border: Border.all(
                    color: tokens.border.withValues(alpha: 0.52),
                  ),
                  boxShadow: tokens.cardShadow,
                ),
                child: ClipRRect(
                  borderRadius: tokens.cardRadius,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: heroTag,
                        child: NetworkImgLayer(
                          src: item.cover,
                          width: 180,
                          height: 104,
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      const WindowsNeoCoverScrim(heightFactor: 0.44),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: WindowsNeoMediaBadge(
                          text: '${item.mediaCount}条',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              item.title,
              maxLines: 1,
              overflow: .ellipsis,
              style: tokens.cardTitleStyle(theme.textTheme),
            ),
            const SizedBox(height: 2),
            Text(
              BiliUtils.isPublicFavText(item.attr),
              style: tokens.cardCaptionStyle(theme.textTheme),
            ),
          ],
        ),
      );
    }

    const radius = BorderRadius.all(Radius.circular(12));
    return GestureDetector(
      onTap: openDetail,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.onInverseSurface.withValues(
                    alpha: 0.4,
                  ),
                  offset: const Offset(6, -8),
                ),
              ],
            ),
            child: Hero(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: radius,
                child: NetworkImgLayer(
                  src: item.cover,
                  width: 180,
                  height: 110,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            ' ${item.title}',
            maxLines: 1,
            overflow: .ellipsis,
            style: const TextStyle(height: 1.42, letterSpacing: 0.3),
          ),
          Text(
            ' 共${item.mediaCount}条视频 · ${BiliUtils.isPublicFavText(item.attr)}',
            style: theme.textTheme.labelSmall!.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}
