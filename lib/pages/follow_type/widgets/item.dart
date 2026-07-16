import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class FollowTypeItem extends StatelessWidget {
  const FollowTypeItem({
    super.key,
    required this.item,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
  });

  final FollowItemModel item;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final child = SizedBox(
      height: 66,
      child: InkWell(
        onTap: onTap ?? () => PageUtils.toMember(item.mid),
        onLongPress: onLongPress,
        onSecondaryTap: onSecondaryTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 10,
          ),
          child: Row(
            spacing: 10,
            children: [
              NetworkImgLayer(
                width: 45,
                height: 45,
                type: ImageType.avatar,
                src: item.face,
              ),
              Expanded(
                child: Column(
                  spacing: 3,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.uname!,
                      style: const TextStyle(fontSize: 14),
                    ),
                    if (item.sign case final sign?)
                      Text(
                        sign,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: ColorScheme.of(context).outline,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!isWindowsNeo) return child;
    return Material(
      color: context.windowsNeo.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: context.windowsNeo.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
