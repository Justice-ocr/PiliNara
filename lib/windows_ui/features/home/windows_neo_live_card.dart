import 'package:PiliPlus/common/widgets/image/image_save.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/models_new/live/live_feed_index/card_data_list_item.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_card_shell.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';

class WindowsNeoLiveCard extends StatefulWidget {
  const WindowsNeoLiveCard({
    super.key,
    required this.item,
    required this.showFirstFrame,
  });

  final CardLiveItem item;
  final bool showFirstFrame;

  @override
  State<WindowsNeoLiveCard> createState() => _WindowsNeoLiveCardState();
}

class WindowsNeoLiveCardSkeleton extends StatelessWidget {
  const WindowsNeoLiveCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: tokens.cardRadius,
        border: Border.all(color: tokens.border.withValues(alpha: 0.42)),
        boxShadow: tokens.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: tokens.cardRadius,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: ColoredBox(color: tokens.hover)),
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(92),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, color: tokens.hover),
                    SizedBox(height: tokens.spaceSm - 1),
                    FractionallySizedBox(
                      widthFactor: 0.74,
                      child: Container(height: 12, color: tokens.hover),
                    ),
                    const Spacer(),
                    FractionallySizedBox(
                      widthFactor: 0.46,
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

class _WindowsNeoLiveCardState extends State<WindowsNeoLiveCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final tokens = context.windowsNeo;
    final theme = Theme.of(context);

    void saveCover() => imageSaveDialog(title: item.title, cover: item.cover);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: WindowsNeoCardShell(
        hovered: _hovered,
        onTap: () => PageUtils.toLiveRoom(item.roomid),
        onLongPress: saveCover,
        onSecondaryTap: saveCover,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  fit: StackFit.expand,
                  children: [
                    AnimatedScale(
                      scale: _hovered ? 1.018 : 1,
                      duration: context.windowsNeoDuration(tokens.motionFast),
                      curve: Curves.easeOutCubic,
                      child: NetworkImgLayer(
                        src: widget.showFirstFrame
                            ? item.systemCover
                            : item.cover,
                        width: constraints.maxWidth,
                        height: constraints.maxHeight,
                        type: .emote,
                      ),
                    ),
                    Positioned(
                      left: 8,
                      right: 8,
                      bottom: 7,
                      child: Row(
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: _OverlayLabel(
                                text: item.areaName ?? '',
                              ),
                            ),
                          ),
                          if (item.watchedShow?.textLarge case final value?)
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _OverlayLabel(
                                  icon: Icons.visibility_outlined,
                                  text: value,
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
            SizedBox(
              height: MediaQuery.textScalerOf(context).scale(92),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: tokens.muted,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.uname ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: tokens.muted,
                            ),
                          ),
                        ),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE5484D),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '\u76f4\u64ad\u4e2d',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: tokens.muted,
                          ),
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

class _OverlayLabel extends StatelessWidget {
  const _OverlayLabel({required this.text, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: Colors.white),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
