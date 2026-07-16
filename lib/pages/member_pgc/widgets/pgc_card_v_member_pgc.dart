import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/space/space_archive/item.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

// 视频卡片 - 垂直布局
class PgcCardVMemberPgc extends StatelessWidget {
  const PgcCardVMemberPgc({
    super.key,
    required this.item,
  });

  final SpaceArchiveItem item;

  @override
  Widget build(BuildContext context) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    void onLongPress() => imageSaveDialog(
      title: item.title,
      cover: item.cover,
    );
    return Card(
      color: isWindowsNeo ? context.windowsNeo.surface : null,
      elevation: 0,
      margin: isWindowsNeo ? EdgeInsets.zero : null,
      clipBehavior: isWindowsNeo ? Clip.antiAlias : Clip.none,
      shape: RoundedRectangleBorder(
        borderRadius: Style.mdRadius,
        side: isWindowsNeo
            ? BorderSide(color: context.windowsNeo.border)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: Style.mdRadius,
        onTap: () => PageUtils.viewPgc(seasonId: item.param),
        onLongPress: onLongPress,
        onSecondaryTap: PlatformUtils.isMobile ? null : onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 0.75,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  return NetworkImgLayer(
                    src: item.cover,
                    width: boxConstraints.maxWidth,
                    height: boxConstraints.maxHeight,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 5, 0, 3),
              child: Text(
                item.title,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  letterSpacing: 0.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
