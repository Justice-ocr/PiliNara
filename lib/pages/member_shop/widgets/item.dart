import 'package:PiliPlus/common/widgets/badge.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models/common/badge_type.dart';
import 'package:PiliPlus/models_new/space/space_shop/item.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class MemberShopItem extends StatelessWidget {
  const MemberShopItem({
    super.key,
    required this.item,
  });

  final SpaceShopItem item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final belowLabels = item.belowLabels?.map((e) => e.title).join('|');
    return Card(
      color: isWindowsNeo ? context.windowsNeo.surface : null,
      elevation: 0,
      margin: isWindowsNeo ? EdgeInsets.zero : null,
      clipBehavior: isWindowsNeo ? Clip.antiAlias : Clip.hardEdge,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        side: isWindowsNeo
            ? BorderSide(color: context.windowsNeo.border)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (item.cardUrl case final cardUrl?) {
            Get.toNamed('/webview', parameters: {'url': cardUrl});
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) => NetworkImgLayer(
                type: .emote,
                src: item.cover?.url,
                width: constraints.maxWidth,
                height: constraints.maxWidth,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (belowLabels?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: PBadge(
                        text: belowLabels,
                        type: PBadgeType.shop,
                        size: PBadgeSize.small,
                        isStack: false,
                        fontSize: 10,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 3,
                          vertical: 2,
                        ),
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (item.netPrice case final netPrice?)
                        Text.rich(
                          style: TextStyle(color: colorScheme.vipColor),
                          TextSpan(
                            children: [
                              if (netPrice.pricePrefix?.isNotEmpty == true)
                                TextSpan(
                                  text: '${netPrice.pricePrefix} ',
                                  style: const TextStyle(fontSize: 11),
                                ),
                              TextSpan(
                                text:
                                    '${netPrice.priceSymbol}${netPrice.netPrice}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item.benefitInfos?.isNotEmpty == true)
                        Text(
                          item.benefitInfos!
                              .map(
                                (e) =>
                                    '${e.prefix ?? ''}${e.amount ?? ''}${e.suffix ?? ''}',
                              )
                              .join('|'),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.outline,
                          ),
                        ),
                    ],
                  ),
                  if (item.itemSourceName?.isNotEmpty == true)
                    Text(
                      '来自${item.itemSourceName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.freeColor,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
