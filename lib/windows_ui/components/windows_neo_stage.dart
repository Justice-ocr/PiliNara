import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

/// Real workspace modes used to compose the Windows stage. The mode is fed by
/// the current page, while [stateLabel] mirrors an already-visible page state.
enum WindowsNeoStageMode { browse, video, live }

extension WindowsNeoStageModeLabel on WindowsNeoStageMode {
  String get label => switch (this) {
    WindowsNeoStageMode.browse => 'BROWSE',
    WindowsNeoStageMode.video => 'VIDEO',
    WindowsNeoStageMode.live => 'LIVE',
  };
}

/// Background instrumentation for browse pages. It remains behind the actual
/// page content and simplifies automatically for compact workspaces.
class WindowsNeoStageFrame extends StatelessWidget {
  const WindowsNeoStageFrame({
    super.key,
    required this.mode,
    required this.child,
    this.stateLabel,
    this.stateIndex = 0,
  });

  final WindowsNeoStageMode mode;
  final Widget child;
  final String? stateLabel;
  final int stateIndex;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final tokens = context.windowsNeo;
      final compact = constraints.maxWidth < 900 || constraints.maxHeight < 520;
      final showInstrumentation =
          !compact && tokens.depth != WindowsNeoThemeDepth.minimal;
      return Stack(
        fit: StackFit.expand,
        children: [
          if (showInstrumentation)
            IgnorePointer(
              child: CustomPaint(
                painter: _WindowsNeoStagePainter(
                  family: tokens.family,
                  mode: mode,
                  accent: tokens.accent.withValues(alpha: 0.13),
                  secondary: tokens.stageMotifColor.withValues(alpha: 0.08),
                  index: stateIndex,
                ),
              ),
            ),
          child,
          if (showInstrumentation && stateLabel?.isNotEmpty == true)
            Positioned(
              right: 20,
              bottom: 12,
              child: ExcludeSemantics(
                child: Text(
                  '${mode.label} / $stateLabel',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.muted.withValues(alpha: 0.48),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    fontFamilyFallback: tokens.uiFontFallback,
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

/// Edge instrumentation for a real video/live media stage. It is intentionally
/// non-interactive and carries no labels that are required to use the player.
class WindowsNeoMediaStage extends StatelessWidget {
  const WindowsNeoMediaStage({
    super.key,
    required this.mode,
    required this.child,
    this.stateLabel,
    this.stateIndex = 0,
  }) : assert(mode != WindowsNeoStageMode.browse);

  final WindowsNeoStageMode mode;
  final Widget child;
  final String? stateLabel;
  final int stateIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 640 || constraints.maxHeight < 360;
        final stageOpacity = switch (tokens.depth) {
          WindowsNeoThemeDepth.minimal => 0.0,
          WindowsNeoThemeDepth.moderate => 0.45,
          WindowsNeoThemeDepth.complex => 0.72,
          WindowsNeoThemeDepth.maximal => compact ? 0.58 : 1.0,
        };
        return RepaintBoundary(
          child: Stack(
            fit: StackFit.expand,
            children: [
              child,
              IgnorePointer(
                child: AnimatedOpacity(
                  duration: reduceMotion
                      ? Duration.zero
                      : tokens.motionStandard,
                  opacity: stageOpacity,
                  child: CustomPaint(
                    painter: _WindowsNeoMediaStagePainter(
                      family: tokens.family,
                      mode: mode,
                      accent: tokens.accent,
                      secondary: tokens.stageMotifColor,
                      index: stateIndex,
                    ),
                  ),
                ),
              ),
              if (!compact && stateLabel?.isNotEmpty == true)
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: ExcludeSemantics(
                    child: AnimatedSwitcher(
                      duration: reduceMotion
                          ? Duration.zero
                          : tokens.motionFast,
                      child: Text(
                        '${mode.label} / $stateLabel',
                        key: ValueKey('${mode.name}-$stateLabel'),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          fontFamilyFallback: tokens.uiFontFallback,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _WindowsNeoStagePainter extends CustomPainter {
  const _WindowsNeoStagePainter({
    required this.family,
    required this.mode,
    required this.accent,
    required this.secondary,
    required this.index,
  });

  final WindowsNeoThemeFamily family;
  final WindowsNeoStageMode mode;
  final Color accent;
  final Color secondary;
  final int index;

  @override
  void paint(Canvas canvas, Size size) {
    switch (family) {
      case WindowsNeoThemeFamily.miku:
        _paintMiku(canvas, size);
      case WindowsNeoThemeFamily.ark:
        _paintArk(canvas, size);
      case WindowsNeoThemeFamily.endfield:
        _paintEndfield(canvas, size);
      case WindowsNeoThemeFamily.exAstris:
        _paintExAstris(canvas, size);
      case WindowsNeoThemeFamily.popucom:
        _paintPopucom(canvas, size);
      case WindowsNeoThemeFamily.corporate:
        _paintCorporate(canvas, size);
    }
  }

  void _paintArk(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 1;
    final left = size.width * .64;
    canvas
      ..drawLine(Offset(left, 24), Offset(left, size.height - 28), paint)
      ..drawLine(
        Offset(left, size.height * .74),
        Offset(size.width - 24, size.height * .74),
        paint,
      );
    for (var step = 0; step < 4; step++) {
      final x = left + 42 + step * 50;
      canvas.drawLine(
        Offset(x, size.height * .74 - 9),
        Offset(x, size.height * .74 + 9),
        paint,
      );
    }
  }

  void _paintEndfield(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = secondary
      ..strokeWidth = 1;
    final x = size.width * .60;
    for (var step = 0; step < 5; step++) {
      canvas.drawLine(
        Offset(x, size.height * .50 + step * 18),
        Offset(size.width - 24, size.height * .50 + step * 18),
        paint,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 54, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, 44)
        ..close(),
      Paint()..color = accent,
    );
  }

  void _paintExAstris(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * .74, size.height * .62);
    canvas
      ..drawOval(Rect.fromCenter(center: center, width: 230, height: 82), paint)
      ..drawOval(
        Rect.fromCenter(center: center, width: 118, height: 174),
        paint,
      )
      ..drawCircle(center, 3, Paint()..color = secondary);
  }

  void _paintPopucom(Canvas canvas, Size size) {
    final paint = Paint()..color = accent;
    final offset = (index % 3) * 12.0;
    canvas.drawCircle(
      Offset(size.width * .77 + offset, size.height * .68),
      22,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * .89, size.height * .56),
      12,
      Paint()..color = secondary,
    );
  }

  void _paintCorporate(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 1;
    canvas
      ..drawLine(
        Offset(size.width * .58, 28),
        Offset(size.width - 24, 28),
        paint,
      )
      ..drawLine(
        Offset(size.width - 24, 28),
        Offset(size.width - 24, size.height - 28),
        paint,
      )
      ..drawLine(
        Offset(size.width * .58, size.height - 28),
        Offset(size.width - 24, size.height - 28),
        paint,
      );
  }

  void _paintMiku(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = secondary
      ..strokeWidth = 1;
    final y = size.height * .76;
    canvas.drawLine(
      Offset(size.width * .60, y),
      Offset(size.width - 24, y - 22),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoStagePainter oldDelegate) =>
      oldDelegate.family != family ||
      oldDelegate.mode != mode ||
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary ||
      oldDelegate.index != index;
}

class _WindowsNeoMediaStagePainter extends _WindowsNeoStagePainter {
  const _WindowsNeoMediaStagePainter({
    required super.family,
    required super.mode,
    required super.accent,
    required super.secondary,
    required super.index,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final alphaAccent = accent.withValues(alpha: .62);
    final alphaSecondary = secondary.withValues(alpha: .34);
    switch (family) {
      case WindowsNeoThemeFamily.ark:
        final paint = Paint()
          ..color = alphaAccent
          ..strokeWidth = 1;
        canvas
          ..drawLine(const Offset(16, 14), Offset(size.width - 16, 14), paint)
          ..drawLine(
            Offset(size.width - 16, 14),
            Offset(size.width - 16, size.height - 16),
            paint,
          )
          ..drawLine(
            Offset(16, size.height - 32),
            Offset(size.width - 16, size.height - 32),
            paint,
          );
      case WindowsNeoThemeFamily.endfield:
        canvas.drawPath(
          Path()
            ..moveTo(size.width - 58, 0)
            ..lineTo(size.width, 0)
            ..lineTo(size.width, 48)
            ..close(),
          Paint()..color = alphaAccent,
        );
        canvas.drawLine(
          Offset(16, size.height - 28),
          Offset(size.width - 16, size.height - 28),
          Paint()
            ..color = alphaSecondary
            ..strokeWidth = 1,
        );
      case WindowsNeoThemeFamily.exAstris:
        final paint = Paint()
          ..color = alphaAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final center = Offset(size.width * .86, size.height * .20);
        canvas
          ..drawOval(
            Rect.fromCenter(center: center, width: 150, height: 54),
            paint,
          )
          ..drawOval(
            Rect.fromCenter(center: center, width: 66, height: 108),
            paint,
          );
      case WindowsNeoThemeFamily.popucom:
        canvas.drawCircle(
          Offset(size.width - 34, 32),
          18,
          Paint()..color = alphaAccent,
        );
        canvas.drawCircle(
          Offset(size.width - 76, 52),
          9,
          Paint()..color = alphaSecondary,
        );
      case WindowsNeoThemeFamily.corporate:
        final paint = Paint()
          ..color = alphaAccent
          ..strokeWidth = 1;
        canvas
          ..drawLine(const Offset(16, 16), Offset(size.width - 16, 16), paint)
          ..drawLine(
            Offset(size.width - 16, 16),
            Offset(size.width - 16, size.height - 16),
            paint,
          );
      case WindowsNeoThemeFamily.miku:
        final paint = Paint()
          ..color = alphaAccent
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(16, size.height - 28),
          Offset(size.width - 16, size.height - 42),
          paint,
        );
    }
  }
}
