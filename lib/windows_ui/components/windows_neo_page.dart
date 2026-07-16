import 'package:PiliPlus/windows_ui/components/windows_neo_backdrop.dart';
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
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget> actions;
  final Widget? commandBar;
  final Widget child;
  final bool compactHeader;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    final showSubtitle =
        !compactHeader && subtitle != null && subtitle!.isNotEmpty;
    final headerHeight = showSubtitle
        ? tokens.pageHeaderHeight
        : tokens.pageHeaderHeight - 8;

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
                  padding: EdgeInsets.symmetric(horizontal: tokens.pagePadding),
                  child: Row(
                    children: [
                      if (leading != null) ...[
                        SizedBox.square(dimension: 34, child: leading),
                        SizedBox(width: tokens.spaceMd - 2),
                      ],
                      Expanded(
                        child: Column(
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
                      ),
                      for (final action in actions) action,
                    ],
                  ),
                ),
              ),
            ),
            if (commandBar case final commandBar?) ...[
              ColoredBox(color: tokens.surface, child: commandBar),
              Divider(
                height: 1,
                thickness: 1.2,
                color: tokens.border.withValues(alpha: 0.95),
              ),
            ],
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
