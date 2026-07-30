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
          final compact =
              constraints.maxWidth < 900 || constraints.maxHeight < 520;
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
              if (showInstrumentation &&
                  tokens.isMaximal &&
                  tokens.family != WindowsNeoThemeFamily.miku)
                IgnorePointer(
                  child: CustomPaint(
                    painter: _WindowsNeoStageOutlinePainter(
                      family: tokens.family,
                      mode: mode,
                      accent: tokens.accent.withValues(alpha: 0.18),
                      secondary: tokens.stageMotifColor.withValues(alpha: 0.11),
                    ),
                  ),
                ),
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
                  duration:
                      reduceMotion ? Duration.zero : tokens.motionStandard,
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
                      duration:
                          reduceMotion ? Duration.zero : tokens.motionFast,
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
    final left = size.width * .61;
    final baseline = switch (mode) {
      WindowsNeoStageMode.browse => size.height * .74,
      WindowsNeoStageMode.video => size.height * .67,
      WindowsNeoStageMode.live => size.height * .61,
    };
    canvas
      ..drawLine(Offset(left, 24), Offset(left, size.height - 28), paint)
      ..drawLine(
        Offset(left, baseline),
        Offset(size.width - 24, baseline),
        paint,
      );
    final dossier = Rect.fromLTWH(
      left + 26,
      baseline - 58,
      size.width * .25,
      44,
    );
    canvas.drawRect(
      dossier,
      Paint()
        ..color = secondary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    for (var step = 0; step < 5; step++) {
      final x = left + 28 + step * 44;
      canvas.drawLine(
        Offset(x, baseline - 8),
        Offset(x, baseline + (step == index % 5 ? 14 : 8)),
        paint,
      );
    }
  }

  void _paintEndfield(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = secondary
      ..strokeWidth = 1;
    final x = size.width * .57;
    final y = switch (mode) {
      WindowsNeoStageMode.browse => size.height * .42,
      WindowsNeoStageMode.video => size.height * .50,
      WindowsNeoStageMode.live => size.height * .35,
    };
    for (var step = 0; step < 6; step++) {
      canvas.drawLine(
        Offset(x, y + step * 18),
        Offset(size.width - 24, y + step * 18),
        paint,
      );
    }
    for (var step = 0; step < 5; step++) {
      final column = x + 38 + step * 48;
      canvas.drawLine(Offset(column, y), Offset(column, y + 90), paint);
    }
    canvas.drawPath(
      Path()
        ..moveTo(size.width - 60, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, 50)
        ..close(),
      Paint()
        ..color = accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    final selectedColumn = x + 38 + (index % 5) * 48;
    canvas.drawRect(
      Rect.fromLTWH(selectedColumn + 1, y + 1, 46, 16),
      Paint()
        ..color = accent.withValues(alpha: .72)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  void _paintExAstris(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(
      size.width * .74,
      switch (mode) {
        WindowsNeoStageMode.browse => size.height * .60,
        WindowsNeoStageMode.video => size.height * .54,
        WindowsNeoStageMode.live => size.height * .66,
      },
    );
    canvas
      ..drawOval(Rect.fromCenter(center: center, width: 238, height: 84), paint)
      ..drawOval(
        Rect.fromCenter(center: center, width: 118, height: 174),
        paint,
      )
      ..drawOval(
        Rect.fromCenter(center: center, width: 174, height: 116),
        paint,
      )
      ..drawCircle(
        center,
        3,
        Paint()
          ..color = secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    final points = <Offset>[
      Offset(center.dx - 78, center.dy - 31),
      Offset(center.dx + 84, center.dy + 22),
      Offset(center.dx + 20, center.dy - 68),
    ];
    for (var pointIndex = 0; pointIndex < points.length; pointIndex++) {
      final point = points[pointIndex];
      canvas.drawCircle(
        point,
        pointIndex == index % points.length ? 3.5 : 1.8,
        Paint()
          ..color = pointIndex == index % points.length ? secondary : accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _paintPopucom(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final offset = (index % 3) * 12.0;
    canvas
      ..drawCircle(
        Offset(size.width * .77 + offset, size.height * .68),
        22,
        paint,
      )
      ..drawCircle(
        Offset(size.width * .89, size.height * .56),
        12,
        Paint()
          ..color = secondary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width * .63,
            mode == WindowsNeoStageMode.live
                ? size.height * .30
                : size.height * .38,
            54,
            22,
          ),
          const Radius.circular(11),
        ),
        Paint()
          ..color = secondary.withValues(alpha: .64)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      )
      ..drawCircle(
        Offset(size.width * .65, size.height * .80),
        9,
        Paint()
          ..color = accent.withValues(alpha: .68)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
  }

  void _paintCorporate(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = accent
      ..strokeWidth = 1;
    final left = size.width * .58;
    final top = mode == WindowsNeoStageMode.video ? 42.0 : 28.0;
    final bottom =
        mode == WindowsNeoStageMode.live ? size.height - 50 : size.height - 28;
    canvas
      ..drawLine(Offset(left, top), Offset(size.width - 24, top), paint)
      ..drawLine(
        Offset(size.width - 24, top),
        Offset(size.width - 24, bottom),
        paint,
      )
      ..drawLine(Offset(left, bottom), Offset(size.width - 24, bottom), paint);
    final indexLine = left + 26 + (index % 4) * 54;
    canvas.drawLine(
      Offset(indexLine, bottom - 34),
      Offset(indexLine, bottom),
      Paint()
        ..color = secondary
        ..strokeWidth = 4,
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

/// Keeps the visual stage present when dense media cards cover most of the
/// background. Every motif is an outline and lives at the stage perimeter.
class _WindowsNeoStageOutlinePainter extends CustomPainter {
  const _WindowsNeoStageOutlinePainter({
    required this.family,
    required this.mode,
    required this.accent,
    required this.secondary,
  });

  final WindowsNeoThemeFamily family;
  final WindowsNeoStageMode mode;
  final Color accent;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final accentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final secondaryPaint = Paint()
      ..color = secondary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const inset = 12.0;
    final edge = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    switch (family) {
      case WindowsNeoThemeFamily.ark:
        final dossier = Rect.fromLTWH(
          size.width * .74,
          mode == WindowsNeoStageMode.live ? 36 : 22,
          size.width * .20,
          72,
        );
        canvas
          ..drawLine(
            edge.topLeft,
            Offset(edge.left + 32, edge.top),
            accentPaint,
          )
          ..drawLine(
            edge.topRight,
            Offset(edge.right, edge.top + 32),
            accentPaint,
          )
          ..drawLine(
            edge.bottomLeft,
            Offset(edge.left + 32, edge.bottom),
            accentPaint,
          )
          ..drawRect(dossier, secondaryPaint)
          ..drawLine(dossier.topLeft, dossier.bottomRight, secondaryPaint);
      case WindowsNeoThemeFamily.endfield:
        final field = Path()
          ..moveTo(size.width * .76, inset)
          ..lineTo(size.width - inset, inset)
          ..lineTo(size.width - inset, size.height * .30)
          ..lineTo(size.width * .71, size.height * .38)
          ..close();
        canvas
          ..drawPath(field, accentPaint)
          ..drawLine(
            Offset(size.width * .68, size.height - inset),
            Offset(size.width - inset, size.height - inset),
            secondaryPaint,
          );
      case WindowsNeoThemeFamily.exAstris:
        final center = Offset(size.width * .88, size.height * .16);
        canvas
          ..drawOval(
            Rect.fromCenter(center: center, width: 160, height: 54),
            accentPaint,
          )
          ..drawOval(
            Rect.fromCenter(center: center, width: 72, height: 118),
            secondaryPaint,
          )
          ..drawCircle(center, 4, accentPaint);
      case WindowsNeoThemeFamily.popucom:
        canvas
          ..drawCircle(Offset(size.width - 38, 38), 20, accentPaint)
          ..drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(size.width - 124, size.height - 44, 72, 24),
              const Radius.circular(12),
            ),
            secondaryPaint,
          );
      case WindowsNeoThemeFamily.corporate:
        final editorial = Rect.fromLTWH(
          size.width * .72,
          inset,
          size.width * .22,
          size.height - inset * 2,
        );
        canvas
          ..drawRect(editorial, accentPaint)
          ..drawLine(
            Offset(editorial.left, editorial.center.dy),
            Offset(editorial.right, editorial.center.dy),
            secondaryPaint,
          );
      case WindowsNeoThemeFamily.miku:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoStageOutlinePainter oldDelegate) =>
      oldDelegate.family != family ||
      oldDelegate.mode != mode ||
      oldDelegate.accent != accent ||
      oldDelegate.secondary != secondary;
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
          Paint()
            ..color = alphaAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
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
          Paint()
            ..color = alphaAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawCircle(
          Offset(size.width - 76, 52),
          9,
          Paint()
            ..color = alphaSecondary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
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
