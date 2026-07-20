import 'package:PiliPlus/windows_ui/components/windows_neo_backdrop.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class WindowsNeoPage extends StatelessWidget {
  const WindowsNeoPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.leading,
    this.actions = const [],
    this.commandBar,
    this.compactHeader = false,
    this.showBackButton,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? commandBar;
  final Widget child;
  final bool compactHeader;
  final bool? showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    final showSubtitle =
        !compactHeader && subtitle != null && subtitle!.isNotEmpty;
    final headerHeight = showSubtitle
        ? tokens.pageHeaderHeight
        : tokens.pageHeaderHeight - 8;
    final navigator = Navigator.maybeOf(context);
    final showBack = showBackButton ?? (navigator?.canPop() ?? false);
    final VoidCallback? back = onBack ?? navigator?.maybePop;

    return ColoredBox(
      color: tokens.background,
      child: WindowsNeoBackdrop(
        child: Column(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: tokens.surface.withValues(alpha: 0.92),
                boxShadow: [
                  BoxShadow(
                    color: tokens.accent.withValues(alpha: 0.07),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: SizedBox(
                height: headerHeight,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.pagePadding,
                  ),
                  child: Row(
                    children: [
                      if (showBack) ...[
                        IconButton(
                          tooltip: '返回',
                          onPressed: back,
                          icon: const Icon(Icons.arrow_back_outlined),
                        ),
                        SizedBox(width: tokens.spaceSm),
                      ],
                      if (leading != null) ...[
                        SizedBox.square(dimension: 34, child: leading),
                        SizedBox(width: tokens.spaceMd - 2),
                      ],
                      const WindowsNeoHeaderBeat(),
                      SizedBox(width: tokens.spaceSm),
                      Expanded(
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const Positioned(
                              right: 14,
                              top: 9,
                              child: IgnorePointer(
                                child: WindowsNeoHeaderWave(),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: tokens.pageTitleStyle(theme.textTheme),
                                ),
                                if (showSubtitle) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: tokens.pageSubtitleStyle(
                                      theme.textTheme,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      for (final action in actions) action,
                    ],
                  ),
                ),
              ),
            ),
            if (commandBar case final commandBar?) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.surface,
                  boxShadow: [
                    BoxShadow(
                      color: tokens.accent.withValues(alpha: 0.05),
                      blurRadius: 7,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: commandBar,
              ),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
