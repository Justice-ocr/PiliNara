import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class WindowsNeoBackdrop extends StatelessWidget {
  const WindowsNeoBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _WindowsNeoDotGrid(
                dotColor: tokens.accent.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.045
                      : 0.055,
                ),
                watermarkColor: tokens.accent.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.09
                      : 0.045,
                ),
                motifColor: WindowsNeoTokens.iceCyan.withValues(
                  alpha: Theme.of(context).brightness == Brightness.dark
                      ? 0.065
                      : 0.045,
                ),
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
  });

  final Color dotColor;
  final Color watermarkColor;
  final Color motifColor;

  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 20.0;
    final paint = Paint()..color = dotColor;
    for (var x = spacing; x < size.width; x += spacing) {
      for (var y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.75, paint);
      }
    }

    if (size.width < 560 || size.height < 360) return;
    _paintWordmark(
      canvas,
      text: '39',
      offset: Offset(size.width - 210, size.height * 0.20),
      fontSize: 94,
      weight: FontWeight.w800,
      letterSpacing: 1,
    );
    _paintWordmark(
      canvas,
      text: 'MIKU',
      offset: Offset(28, size.height * 0.72),
      fontSize: 22,
      weight: FontWeight.w700,
      letterSpacing: 7,
    );
    _paintRhythmLines(canvas, size);
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

    final beatPaint = Paint()
      ..color = motifColor
      ..style = PaintingStyle.fill;
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
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: watermarkColor,
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
      ..rotate(-0.10);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoDotGrid oldDelegate) =>
      oldDelegate.dotColor != dotColor ||
      oldDelegate.watermarkColor != watermarkColor ||
      oldDelegate.motifColor != motifColor;
}
