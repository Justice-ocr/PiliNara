import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class WindowsNeoBackdrop extends StatelessWidget {
  const WindowsNeoBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WindowsNeoDotGrid(
                dotColor: tokens.accent.withValues(alpha: dark ? 0.045 : 0.055),
                watermarkColor: tokens.accent.withValues(
                  alpha: dark ? 0.09 : 0.045,
                ),
                motifColor: tokens.stageMotifColor.withValues(
                  alpha: dark ? 0.065 : 0.045,
                ),
                backdropPattern: tokens.identity.backdropPattern,
                family: tokens.family,
                depth: tokens.depth,
                shellMark: tokens.shellMark,
                shellWordmark: tokens.shellWordmark,
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _WindowsNeoDotGrid extends CustomPainter {
  const _WindowsNeoDotGrid({
    required this.dotColor,
    required this.watermarkColor,
    required this.motifColor,
    required this.backdropPattern,
    required this.family,
    required this.depth,
    required this.shellMark,
    required this.shellWordmark,
  });

  final Color dotColor;
  final Color watermarkColor;
  final Color motifColor;
  final WindowsNeoBackdropPattern backdropPattern;
  final WindowsNeoThemeFamily family;
  final WindowsNeoThemeDepth depth;
  final String shellMark;
  final String shellWordmark;

  @override
  void paint(Canvas canvas, Size size) {
    if (family == WindowsNeoThemeFamily.miku ||
        family == WindowsNeoThemeFamily.popucom) {
      _paintDots(canvas, size);
    }
    if (depth == WindowsNeoThemeDepth.minimal ||
        size.width < 560 ||
        size.height < 360) {
      return;
    }

    _paintFamilyWordmarks(canvas, size);

    if (depth == WindowsNeoThemeDepth.moderate) {
      _paintModerateRule(canvas, size);
    } else {
      switch (backdropPattern) {
        case WindowsNeoBackdropPattern.rhythm:
          _paintRhythmLines(canvas, size);
        case WindowsNeoBackdropPattern.engineeringGrid:
          _paintEngineeringGrid(canvas, size);
        case WindowsNeoBackdropPattern.industrialBlueprint:
          _paintBlueprint(canvas, size);
        case WindowsNeoBackdropPattern.orbitalArchive:
          _paintOrbit(canvas, size);
        case WindowsNeoBackdropPattern.playfulBlocks:
          _paintPlayfulBlocks(canvas, size);
        case WindowsNeoBackdropPattern.studioGrid:
          _paintStudioGrid(canvas, size);
      }
    }
    if (depth == WindowsNeoThemeDepth.maximal) {
      _paintMaximalFrame(canvas, size);
    }
  }

  void _paintFamilyWordmarks(Canvas canvas, Size size) {
    final (offset, fontSize, rotation) = switch (family) {
      WindowsNeoThemeFamily.endfield => (
        Offset(size.width - 164, size.height * .16),
        112.0,
        0.0,
      ),
      WindowsNeoThemeFamily.ark => (
        Offset(size.width - 254, size.height * .16),
        86.0,
        -.06,
      ),
      WindowsNeoThemeFamily.exAstris => (
        Offset(size.width - 198, size.height * .16),
        88.0,
        0.0,
      ),
      WindowsNeoThemeFamily.popucom => (
        Offset(size.width - 194, size.height * .16),
        86.0,
        -.08,
      ),
      WindowsNeoThemeFamily.corporate => (
        Offset(size.width - 176, size.height * .16),
        94.0,
        0.0,
      ),
      WindowsNeoThemeFamily.miku => (
        Offset(size.width - 210, size.height * .20),
        94.0,
        -.10,
      ),
    };
    _paintWordmark(
      canvas,
      text: shellMark,
      offset: offset,
      fontSize: fontSize,
      weight: FontWeight.w800,
      letterSpacing: 1,
      rotation: rotation,
    );
    _paintWordmark(
      canvas,
      text: shellWordmark,
      offset: Offset(28, size.height * .72),
      fontSize: family == WindowsNeoThemeFamily.exAstris ? 22 : 20,
      weight: FontWeight.w700,
      letterSpacing: family == WindowsNeoThemeFamily.miku ? 7 : 4,
      rotation: 0,
    );
  }

  void _paintModerateRule(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = motifColor
      ..strokeWidth = 1;
    final y = size.height * .74;
    canvas
      ..drawLine(Offset(size.width * .56, y), Offset(size.width - 28, y), paint)
      ..drawLine(
        Offset(size.width * .62, y - 7),
        Offset(size.width * .62, y + 7),
        paint,
      )
      ..drawLine(
        Offset(size.width * .84, y - 7),
        Offset(size.width * .84, y + 7),
        paint,
      );
  }

  void _paintMaximalFrame(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = motifColor
      ..strokeWidth = 1;
    const tick = 7.0;
    for (final x in [size.width * .48, size.width * .72, size.width * .94]) {
      canvas
        ..drawLine(Offset(x, 14), Offset(x, 14 + tick), paint)
        ..drawLine(
          Offset(x, size.height - 14),
          Offset(x, size.height - 14 - tick),
          paint,
        );
    }
    canvas
      ..drawLine(const Offset(14, 14), const Offset(14 + tick, 14), paint)
      ..drawLine(
        Offset(size.width - 14, size.height - 14),
        Offset(size.width - 14 - tick, size.height - 14),
        paint,
      );
  }

  void _paintDots(Canvas canvas, Size size) {
    const spacing = 20.0;
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = .7;
    for (var x = spacing; x < size.width; x += spacing) {
      for (var y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.75, paint);
      }
    }
  }

  void _paintEngineeringGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = motifColor
      ..strokeWidth = 1;
    final left = size.width * 0.56;
    for (var index = 0; index < 7; index++) {
      final x = left + index * 42;
      canvas.drawLine(
        Offset(x, size.height * .18),
        Offset(x, size.height * .82),
        paint,
      );
    }
    for (var index = 0; index < 6; index++) {
      final y = size.height * .18 + index * 38;
      canvas.drawLine(Offset(left, y), Offset(size.width - 28, y), paint);
    }
    _paintCornerTicks(
      canvas,
      size,
      left,
      size.height * .18,
      size.width - 28,
      size.height * .82,
    );
  }

  void _paintBlueprint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = motifColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Rect.fromLTWH(
      size.width * .56,
      size.height * .20,
      size.width * .35,
      size.height * .44,
    );
    canvas
      ..drawRect(rect, paint)
      ..drawLine(rect.topLeft, rect.bottomRight, paint)
      ..drawLine(rect.topRight, rect.bottomLeft, paint)
      ..drawCircle(rect.center, rect.shortestSide * .20, paint);
    _paintCornerTicks(
      canvas,
      size,
      rect.left,
      rect.top,
      rect.right,
      rect.bottom,
    );
  }

  void _paintStudioGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = motifColor
      ..strokeWidth = 1;
    final baseline = size.height * .73;
    canvas.drawLine(
      Offset(size.width * .52, baseline),
      Offset(size.width - 28, baseline),
      paint,
    );
    for (var index = 0; index < 5; index++) {
      final x = size.width * .56 + index * 58;
      canvas.drawLine(Offset(x, baseline - 56), Offset(x, baseline + 1), paint);
    }
    for (var index = 0; index < 3; index++) {
      final y = baseline - 56 + index * 18;
      canvas.drawLine(
        Offset(size.width * .52, y),
        Offset(size.width - 28, y),
        paint,
      );
    }
  }

  void _paintCornerTicks(
    Canvas canvas,
    Size size,
    double left,
    double top,
    double right,
    double bottom,
  ) {
    final paint = Paint()
      ..color = motifColor
      ..strokeWidth = 2;
    const length = 9.0;
    canvas
      ..drawLine(Offset(left, top), Offset(left + length, top), paint)
      ..drawLine(Offset(left, top), Offset(left, top + length), paint)
      ..drawLine(Offset(right, bottom), Offset(right - length, bottom), paint)
      ..drawLine(Offset(right, bottom), Offset(right, bottom - length), paint);
  }

  void _paintOrbit(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = motifColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final center = Offset(size.width * .78, size.height * .36);
    canvas
      ..drawOval(
        Rect.fromCenter(center: center, width: 280, height: 132),
        paint,
      )
      ..drawOval(Rect.fromCenter(center: center, width: 190, height: 82), paint)
      ..drawCircle(
        center,
        4,
        Paint()
          ..color = motifColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    final archiveLine = Paint()
      ..color = motifColor
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(size.width * .56, size.height * .65),
      Offset(size.width - 30, size.height * .65),
      archiveLine,
    );
  }

  void _paintPlayfulBlocks(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = motifColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    for (var i = 0; i < 6; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            size.width - 300 + i * 40,
            size.height - 90 - (i.isEven ? 0 : 18),
            24,
            24,
          ),
          const Radius.circular(5),
        ),
        paint,
      );
    }
    final outline = Paint()
      ..color = motifColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas
      ..drawCircle(Offset(size.width * .72, size.height * .29), 34, outline)
      ..drawLine(
        Offset(size.width * .72 - 48, size.height * .29),
        Offset(size.width * .72 + 48, size.height * .29),
        outline,
      );
  }

  void _paintRhythmLines(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = motifColor
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    final startX = size.width - 310;
    final startY = size.height - 82;
    for (var index = 0; index < 4; index++) {
      final y = startY + index * 10;
      canvas.drawLine(
        Offset(startX, y),
        Offset(size.width - 28, y - 24),
        linePaint,
      );
    }
    final beatPaint = Paint()..color = motifColor;
    for (final beat in const [0.18, 0.46, 0.74]) {
      final x = startX + 282 * beat;
      final y = startY + 22 - 24 * beat;
      canvas
        ..drawCircle(Offset(x, y), 3.2, beatPaint)
        ..drawLine(Offset(x + 3, y), Offset(x + 3, y - 18), linePaint);
    }
  }

  void _paintWordmark(
    Canvas canvas, {
    required String text,
    required Offset offset,
    required double fontSize,
    required FontWeight weight,
    required double letterSpacing,
    required double rotation,
  }) {
    final outline = family != WindowsNeoThemeFamily.miku;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: outline ? null : watermarkColor,
          foreground: outline
              ? (Paint()
                  ..color = watermarkColor
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = .85)
              : null,
          fontSize: fontSize,
          fontWeight: weight,
          letterSpacing: letterSpacing,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas
      ..save()
      ..translate(offset.dx, offset.dy)
      ..rotate(rotation);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoDotGrid oldDelegate) =>
      oldDelegate.dotColor != dotColor ||
      oldDelegate.watermarkColor != watermarkColor ||
      oldDelegate.motifColor != motifColor ||
      oldDelegate.backdropPattern != backdropPattern ||
      oldDelegate.family != family ||
      oldDelegate.depth != depth ||
      oldDelegate.shellMark != shellMark ||
      oldDelegate.shellWordmark != shellWordmark;
}
