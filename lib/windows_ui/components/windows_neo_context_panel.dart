import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class WindowsNeoContextStack extends StatelessWidget {
  const WindowsNeoContextStack({
    super.key,
    required this.base,
    this.contexts = const [],
  });

  final Widget base;
  final List<Widget> contexts;

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: contexts.length,
    children: [base, ...contexts],
  );
}

class WindowsNeoContextPanel extends StatelessWidget {
  const WindowsNeoContextPanel({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.actions = const [],
    this.backTooltip = '返回相关内容',
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;
  final List<Widget> actions;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final darkHeader = switch (tokens.family) {
      WindowsNeoThemeFamily.ark ||
      WindowsNeoThemeFamily.exAstris ||
      WindowsNeoThemeFamily.corporate => true,
      _ => false,
    };
    final foreground = darkHeader ? Colors.white : tokens.ink;
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: darkHeader ? tokens.chromeSurface : tokens.surface,
            border: Border(
              bottom: BorderSide(
                color: darkHeader
                    ? Colors.white.withValues(alpha: 0.16)
                    : tokens.border,
              ),
            ),
          ),
          child: SizedBox(
            height: 46,
            child: IconTheme(
              data: IconThemeData(color: foreground),
              child: Row(
                children: [
                  IconButton(
                    tooltip: backTooltip,
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, size: 19),
                  ),
                  const SizedBox(width: 2),
                  Container(
                    width: tokens.family == WindowsNeoThemeFamily.exAstris
                        ? 2
                        : 3,
                    height: 18,
                    color: tokens.accent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: tokens.displayFontFallback,
                      ),
                    ),
                  ),
                  ...actions,
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
