import 'package:PiliPlus/windows_ui/components/windows_neo_backdrop.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_stage.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:material_ui/material_ui.dart';

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
    this.stageMode,
    this.stageScene,
    this.stageState,
    this.stageIndex = 0,
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
  final WindowsNeoStageMode? stageMode;
  final WindowsNeoStageScene? stageScene;
  final String? stageState;
  final int stageIndex;
  final bool? showBackButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    final headerUsesDarkChrome = switch (tokens.family) {
      WindowsNeoThemeFamily.ark ||
      WindowsNeoThemeFamily.exAstris ||
      WindowsNeoThemeFamily.popucom ||
      WindowsNeoThemeFamily.corporate => true,
      _ => false,
    };
    final headerSurface = headerUsesDarkChrome
        ? tokens.chromeSurface
        : tokens.surface.withValues(alpha: 0.92);
    final headerInk = headerUsesDarkChrome ? Colors.white : tokens.ink;
    final commandUsesDarkChrome = switch (tokens.family) {
      WindowsNeoThemeFamily.ark ||
      WindowsNeoThemeFamily.exAstris ||
      WindowsNeoThemeFamily.corporate => true,
      _ => false,
    };
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
                color: headerSurface,
                border: Border(
                  bottom: BorderSide(
                    color: headerUsesDarkChrome
                        ? Colors.white.withValues(alpha: 0.16)
                        : tokens.border.withValues(alpha: 0.78),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: tokens.accent.withValues(alpha: 0.07),
                    blurRadius: 9,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: tokens.depth == WindowsNeoThemeDepth.minimal
                    ? null
                    : _WindowsNeoPageHeaderCuePainter(
                        family: tokens.family,
                        accent: tokens.accent,
                        rule: headerUsesDarkChrome
                            ? Colors.white.withValues(alpha: 0.28)
                            : tokens.border.withValues(alpha: 0.78),
                      ),
                child: SizedBox(
                  height: headerHeight,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.pagePadding,
                    ),
                    child: IconTheme(
                      data: IconThemeData(color: headerInk),
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
                                if (tokens.depth !=
                                    WindowsNeoThemeDepth.minimal)
                                  const Positioned(
                                    right: 14,
                                    top: 4,
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
                                      style: tokens
                                          .pageTitleStyle(theme.textTheme)
                                          .copyWith(color: headerInk),
                                    ),
                                    if (showSubtitle) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: tokens
                                            .pageSubtitleStyle(theme.textTheme)
                                            .copyWith(
                                              color: headerInk.withValues(
                                                alpha: 0.68,
                                              ),
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
              ),
            ),
            if (commandBar case final commandBar?) ...[
              DecoratedBox(
                decoration: BoxDecoration(
                  color: commandUsesDarkChrome
                      ? tokens.chromeSurface
                      : tokens.surface,
                  border: Border(
                    bottom: BorderSide(
                      color: commandUsesDarkChrome
                          ? Colors.white.withValues(alpha: 0.12)
                          : tokens.border.withValues(alpha: 0.62),
                    ),
                  ),
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
            Expanded(
              child: stageMode == null
                  ? child
                  : WindowsNeoStageFrame(
                      mode: stageMode!,
                      scene: stageScene,
                      stateLabel: stageState,
                      stateIndex: stageIndex,
                      child: child,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small, non-interactive family cue for the shared header. It keeps the
/// shell distinct without adding state or obscuring the page controls.
class _WindowsNeoPageHeaderCuePainter extends CustomPainter {
  const _WindowsNeoPageHeaderCuePainter({
    required this.family,
    required this.accent,
    required this.rule,
  });

  final WindowsNeoThemeFamily family;
  final Color accent;
  final Color rule;

  @override
  void paint(Canvas canvas, Size size) {
    final accentPaint = Paint()
      ..color = accent.withValues(alpha: 0.86)
      ..strokeWidth = 1;
    final rulePaint = Paint()
      ..color = rule
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    switch (family) {
      case WindowsNeoThemeFamily.endfield:
        canvas
          ..drawLine(const Offset(0, 0), Offset(0, size.height), accentPaint)
          ..drawLine(
            Offset(42, size.height - 9),
            Offset(146, size.height - 9),
            rulePaint,
          )
          ..drawPath(
            Path()
              ..moveTo(size.width - 36, 0)
              ..lineTo(size.width, 0)
              ..lineTo(size.width, 28)
              ..close(),
            rulePaint,
          );
      case WindowsNeoThemeFamily.ark:
        canvas
          ..drawLine(const Offset(0, 8), const Offset(62, 8), accentPaint)
          ..drawLine(
            Offset(size.width - 132, size.height - 9),
            Offset(size.width - 16, size.height - 9),
            rulePaint,
          )
          ..drawLine(
            Offset(size.width - 16, 8),
            Offset(size.width - 16, size.height - 9),
            rulePaint,
          );
      case WindowsNeoThemeFamily.exAstris:
        final center = Offset(size.width - 42, 18);
        canvas
          ..drawOval(
            Rect.fromCenter(center: center, width: 62, height: 22),
            rulePaint,
          )
          ..drawOval(
            Rect.fromCenter(center: center, width: 26, height: 46),
            rulePaint,
          )
          ..drawCircle(center, 2, accentPaint);
      case WindowsNeoThemeFamily.popucom:
        for (var x = 8.0; x < size.width; x += 16) {
          canvas.drawCircle(Offset(x, 9), 1.2, rulePaint);
        }
        canvas.drawCircle(
          Offset(size.width - 36, size.height - 16),
          8,
          rulePaint,
        );
      case WindowsNeoThemeFamily.corporate:
        canvas
          ..drawLine(const Offset(0, 8), Offset(size.width, 8), rulePaint)
          ..drawLine(
            Offset(size.width - 18, 8),
            Offset(size.width - 18, size.height - 8),
            accentPaint,
          )
          ..drawLine(
            Offset(size.width - 132, size.height - 9),
            Offset(size.width - 34, size.height - 9),
            rulePaint,
          );
      case WindowsNeoThemeFamily.miku:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoPageHeaderCuePainter oldDelegate) =>
      oldDelegate.family != family ||
      oldDelegate.accent != accent ||
      oldDelegate.rule != rule;
}
