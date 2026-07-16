import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class WindowsNeoMessageButton extends StatelessWidget {
  const WindowsNeoMessageButton({super.key, required this.mainController});

  final MainController mainController;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!mainController.accountService.isLogin.value) {
        return const SizedBox.shrink();
      }
      final count = mainController.msgUnReadCount.value;
      final isNumberBadge = mainController.msgBadgeMode == .number;
      return IconButton(
        tooltip: '\u6d88\u606f',
        onPressed: () {
          mainController
            ..msgUnReadCount.value = ''
            ..lastCheckUnreadAt = DateTime.now().millisecondsSinceEpoch;
          PageUtils.openToolTab(route: '/whisper', title: '\u6d88\u606f');
        },
        icon: Badge(
          isLabelVisible:
              mainController.msgBadgeMode != .hidden && count.isNotEmpty,
          alignment: isNumberBadge
              ? const Alignment(0, -0.85)
              : const Alignment(1, -0.85),
          label: isNumberBadge && count.isNotEmpty ? Text(count) : null,
          child: const Icon(Icons.notifications_none),
        ),
      );
    });
  }
}

class WindowsNeoAccountAvatar extends StatelessWidget {
  const WindowsNeoAccountAvatar({super.key, required this.mainController});

  final MainController mainController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '\u6211\u7684',
      child: Obx(() {
        if (!mainController.accountService.isLogin.value) {
          return SizedBox.square(
            dimension: 34,
            child: IconButton(
              tooltip: '\u70b9\u51fb\u767b\u5f55',
              padding: EdgeInsets.zero,
              onPressed: mainController.toMinePage,
              icon: const Icon(Icons.person_outline, size: 20),
            ),
          );
        }
        return Stack(
          clipBehavior: Clip.none,
          children: [
            NetworkImgLayer(
              type: .avatar,
              width: 32,
              height: 32,
              src: mainController.accountService.face.value,
            ),
            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: mainController.toMinePage,
                ),
              ),
            ),
            if (MineController.anonymity.value)
              Positioned(
                right: -3,
                bottom: -3,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.secondaryContainer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: Icon(
                        MdiIcons.incognito,
                        size: 12,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }
}
