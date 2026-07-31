import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';

/// A low-contrast rhythm track shared by Windows navigation surfaces.
class WindowsNeoRhythmRail extends StatelessWidget {
  const WindowsNeoRhythmRail({
    super.key,
    this.height = 4,
    this.showBeats = true,
  });

  final double height;
  final bool showBeats;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _WindowsNeoRhythmRailPainter(
          trackColor: tokens.rhythmTrackColor,
          beatColor: tokens.accent.withValues(alpha: 0.28),
          showBeats: showBeats && tokens.identity.showRhythmTicks,
        ),
      ),
    );
  }
}

/// Animated active segment placed over a [WindowsNeoRhythmRail].
class WindowsNeoActiveBeat extends StatelessWidget {
  const WindowsNeoActiveBeat({
    super.key,
    required this.active,
    this.width = 42,
    this.height = 2.5,
  });

  final bool active;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return AnimatedContainer(
      duration: context.windowsNeoDuration(tokens.motionFast),
      curve: Curves.easeOutCubic,
      width: active ? width : 0,
      height: height,
      decoration: BoxDecoration(
        gradient: tokens.rhythmGradient,
        borderRadius: BorderRadius.circular(
          tokens.family == WindowsNeoThemeFamily.miku ? height : 0,
        ),
        boxShadow: active
            ? [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: 0.22),
                  blurRadius: 6,
                ),
              ]
            : const [],
      ),
    );
  }
}

/// Static accent line for placeholder surfaces. The parent loading sliver owns
/// the opacity animation so individual cards do not create controllers.
class WindowsNeoLoadingMarker extends StatelessWidget {
  const WindowsNeoLoadingMarker({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final radius = switch (tokens.family) {
      WindowsNeoThemeFamily.miku => 2.0,
      _ => 0.0,
    };
    return SizedBox(
      height: 2,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: tokens.rhythmGradient,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Compact vertical beat used beside shared page titles.
class WindowsNeoHeaderBeat extends StatelessWidget {
  const WindowsNeoHeaderBeat({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return SizedBox(
      key: const Key('windows-neo-header-beat'),
      width: 5,
      height: 30,
      child: CustomPaint(
        painter: _WindowsNeoHeaderBeatPainter(
          gradient: tokens.rhythmGradient,
          mutedColor: tokens.border.withValues(alpha: 0.72),
          family: tokens.family,
        ),
      ),
    );
  }
}

class WindowsNeoHeaderWave extends StatelessWidget {
  const WindowsNeoHeaderWave({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final isMiku = tokens.family == WindowsNeoThemeFamily.miku;
    return SizedBox(
      key: const Key('windows-neo-header-wave'),
      width: isMiku ? 168 : 252,
      height: isMiku ? 28 : 42,
      child: CustomPaint(
        painter: _WindowsNeoHeaderWavePainter(
          primary: tokens.accent.withValues(alpha: isMiku ? 0.11 : 0.18),
          secondary: tokens.structuralSecondaryAccent.withValues(
            alpha: isMiku ? 0.075 : 0.14,
          ),
          family: tokens.family,
        ),
      ),
    );
  }
}

/// Adds a compact beat and rhythm rail around an open workspace section.
/// The content stays unframed so adjacent sections remain airy.
class WindowsNeoSectionHeader extends StatelessWidget {
  const WindowsNeoSectionHeader({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final markerRadius = switch (tokens.family) {
      WindowsNeoThemeFamily.miku => 2.0,
      _ => 0.0,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                gradient: tokens.rhythmGradient,
                borderRadius: BorderRadius.circular(markerRadius),
              ),
            ),
            SizedBox(width: tokens.spaceSm),
            Expanded(child: child),
          ],
        ),
        SizedBox(height: tokens.spaceXs + 1),
        WindowsNeoRhythmRail(
          height: 3,
          showBeats: tokens.identity.showRhythmTicks,
        ),
      ],
    );
  }
}

class WindowsNeoTabIndicator extends Decoration {
  const WindowsNeoTabIndicator({
    required this.tokens,
    this.width = 38,
    this.height = 2.5,
  });

  final WindowsNeoTokens tokens;
  final double width;
  final double height;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _WindowsNeoTabIndicatorPainter(
        tokens: tokens,
        width: width,
        height: height,
      );
}

class _WindowsNeoRhythmRailPainter extends CustomPainter {
  const _WindowsNeoRhythmRailPainter({
    required this.trackColor,
    required this.beatColor,
    required this.showBeats,
  });

  final Color trackColor;
  final Color beatColor;
  final bool showBeats;

  @override
  void paint(Canvas canvas, Size size) {
    final y = size.height / 2;
    canvas.drawLine(
      Offset(0, y),
      Offset(size.width, y),
      Paint()
        ..color = trackColor
        ..strokeWidth = 1,
    );
    if (!showBeats || size.width < 80) return;

    final beatPaint = Paint()..color = beatColor;
    for (final position in const [0.18, 0.39, 0.72]) {
      canvas.drawCircle(Offset(size.width * position, y), 1.5, beatPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoRhythmRailPainter oldDelegate) =>
      oldDelegate.trackColor != trackColor ||
      oldDelegate.beatColor != beatColor ||
      oldDelegate.showBeats != showBeats;
}

class _WindowsNeoHeaderBeatPainter extends CustomPainter {
  const _WindowsNeoHeaderBeatPainter({
    required this.gradient,
    required this.mutedColor,
    required this.family,
  });

  final Gradient gradient;
  final Color mutedColor;
  final WindowsNeoThemeFamily family;

  @override
  void paint(Canvas canvas, Size size) {
    final lineRect = Rect.fromLTWH(
      0,
      0,
      family == WindowsNeoThemeFamily.popucom ? 3 : 2,
      size.height,
    );
    if (family == WindowsNeoThemeFamily.exAstris) {
      final ring = Paint()
        ..color = mutedColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas
        ..drawCircle(const Offset(1.5, 7), 1.5, ring)
        ..drawCircle(const Offset(1.5, 22), 1.5, ring);
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          lineRect,
          Radius.circular(family == WindowsNeoThemeFamily.miku ? 2 : 0),
        ),
        Paint()..shader = gradient.createShader(lineRect),
      );
    }
    final beatPaint = Paint()..color = mutedColor;
    if (family == WindowsNeoThemeFamily.miku ||
        family == WindowsNeoThemeFamily.popucom) {
      canvas
        ..drawCircle(Offset(size.width - 1.5, 7), 1.5, beatPaint)
        ..drawCircle(Offset(size.width - 1.5, 22), 1.5, beatPaint);
    } else if (family == WindowsNeoThemeFamily.ark) {
      canvas
        ..drawLine(const Offset(3, 6), Offset(size.width, 6), beatPaint)
        ..drawLine(const Offset(3, 23), Offset(size.width, 23), beatPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoHeaderBeatPainter oldDelegate) =>
      oldDelegate.gradient != gradient ||
      oldDelegate.mutedColor != mutedColor ||
      oldDelegate.family != family;
}

class _WindowsNeoHeaderWavePainter extends CustomPainter {
  const _WindowsNeoHeaderWavePainter({
    required this.primary,
    required this.secondary,
    required this.family,
  });

  final Color primary;
  final Color secondary;
  final WindowsNeoThemeFamily family;

  @override
  void paint(Canvas canvas, Size size) {
    final primaryPaint = Paint()
      ..color = primary
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final secondaryPaint = Paint()
      ..color = secondary
      ..strokeWidth = 1;
    final center = size.height / 2;
    switch (family) {
      case WindowsNeoThemeFamily.miku:
        _paintPolyline(
          canvas,
          primaryPaint,
          center,
          const [0.0, -4.0, 7.0, -10.0, 5.0, -2.0, 8.0, -5.0, 0.0],
          size,
        );
        for (final position in const [0.18, 0.39, 0.72]) {
          final x = size.width * position;
          canvas.drawLine(
            Offset(x, center - 10),
            Offset(x, center + 10),
            secondaryPaint,
          );
        }
      case WindowsNeoThemeFamily.endfield:
        canvas.drawPath(
          Path()
            ..moveTo(size.width * .20, 4)
            ..lineTo(size.width * .88, 4)
            ..lineTo(size.width, size.height - 6)
            ..lineTo(size.width * .32, size.height - 6)
            ..close(),
          primaryPaint,
        );
        for (final position in const [0.16, 0.43, 0.78]) {
          final x = size.width * position;
          canvas.drawLine(
            Offset(x, center - 7),
            Offset(x, center + 7),
            secondaryPaint,
          );
        }
      case WindowsNeoThemeFamily.ark:
        final frame = Rect.fromLTWH(
          size.width * .16,
          4,
          size.width * .72,
          size.height - 8,
        );
        canvas
          ..drawRect(frame, primaryPaint)
          ..drawLine(
            frame.topLeft,
            Offset(frame.center.dx, frame.bottom),
            secondaryPaint,
          )
          ..drawLine(
            Offset(frame.center.dx, frame.top),
            frame.bottomRight,
            secondaryPaint,
          );
      case WindowsNeoThemeFamily.exAstris:
        final orbitCenter = Offset(size.width * .72, center);
        canvas
          ..drawOval(
            Rect.fromCenter(center: orbitCenter, width: 128, height: 34),
            primaryPaint,
          )
          ..drawOval(
            Rect.fromCenter(center: orbitCenter, width: 58, height: 62),
            secondaryPaint,
          )
          ..drawCircle(orbitCenter, 3, primaryPaint);
      case WindowsNeoThemeFamily.popucom:
        canvas
          ..drawRect(
            Rect.fromLTWH(size.width * .20, 6, size.width * .56, 30),
            primaryPaint,
          )
          ..drawCircle(Offset(size.width * .28, center), 5, secondaryPaint)
          ..drawCircle(Offset(size.width * .70, center), 5, secondaryPaint);
      case WindowsNeoThemeFamily.corporate:
        final frame = Rect.fromLTWH(
          size.width * .20,
          6,
          size.width * .72,
          size.height - 12,
        );
        canvas
          ..drawRect(frame, primaryPaint)
          ..drawLine(
            Offset(frame.left, frame.center.dy),
            Offset(frame.right, frame.center.dy),
            secondaryPaint,
          )
          ..drawLine(
            Offset(frame.right - 18, frame.top),
            Offset(frame.right - 18, frame.bottom),
            secondaryPaint,
          );
    }
  }

  void _paintPolyline(
    Canvas canvas,
    Paint paint,
    double center,
    List<double> levels,
    Size size,
  ) {
    final path = Path()..moveTo(0, center);
    final step = size.width / (levels.length - 1);
    for (var index = 1; index < levels.length; index++) {
      path.lineTo(step * index, center + levels[index]);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoHeaderWavePainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.family != family;
}

class _WindowsNeoTabIndicatorPainter extends BoxPainter {
  _WindowsNeoTabIndicatorPainter({
    required this.tokens,
    required this.width,
    required this.height,
  });

  final WindowsNeoTokens tokens;
  final double width;
  final double height;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size;
    if (size == null) return;
    final context = configuration.textDirection;
    final selectionRect = Rect.fromLTWH(
      offset.dx - 11,
      offset.dy + 4,
      size.width + 22,
      size.height - 7,
    );
    final selectionGradient = switch (tokens.family) {
      WindowsNeoThemeFamily.miku => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          tokens.accent.withValues(alpha: 0.14),
          Colors.white.withValues(alpha: 0.26),
          tokens.structuralSecondaryAccent.withValues(alpha: 0.08),
        ],
        stops: const [0, 0.68, 1],
      ),
      WindowsNeoThemeFamily.endfield => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          tokens.accent.withValues(alpha: 0.30),
          tokens.accent.withValues(alpha: 0.08),
          Colors.transparent,
        ],
        stops: const [0, 0.62, 1],
      ),
      WindowsNeoThemeFamily.ark => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          tokens.accent.withValues(alpha: 0.18),
          tokens.accent.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0, 0.56, 1],
      ),
      WindowsNeoThemeFamily.exAstris => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          tokens.secondaryAccent.withValues(alpha: 0.12),
          tokens.accent.withValues(alpha: 0.13),
          Colors.transparent,
        ],
        stops: const [0, 0.58, 1],
      ),
      WindowsNeoThemeFamily.popucom => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          tokens.accent.withValues(alpha: 0.36),
          tokens.secondaryAccent.withValues(alpha: 0.16),
          Colors.white.withValues(alpha: 0.14),
        ],
        stops: const [0, 0.66, 1],
      ),
      WindowsNeoThemeFamily.corporate => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          tokens.accent.withValues(alpha: 0.24),
          tokens.accent.withValues(alpha: 0.06),
          Colors.transparent,
        ],
        stops: const [0, 0.64, 1],
      ),
    };
    final selectionRadius = Radius.circular(
      tokens.workspaceTabRadius.topLeft.x,
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(selectionRect, selectionRadius),
        Paint()..shader = selectionGradient.createShader(selectionRect),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          selectionRect,
          selectionRadius,
        ),
        Paint()
          ..color = tokens.accent.withValues(alpha: 0.16)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    final left = offset.dx + (size.width - width) / 2;
    final rect = Rect.fromLTWH(
      left,
      offset.dy + size.height - height,
      width,
      height,
    );
    final gradient = LinearGradient(
      colors: [tokens.accent, tokens.structuralSecondaryAccent],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(
          tokens.family == WindowsNeoThemeFamily.miku ? height : 0,
        ),
      ),
      Paint()..shader = gradient.createShader(rect),
    );
    if (context == null) return;
    final dotX = context == TextDirection.ltr ? rect.right : rect.left;
    canvas.drawCircle(
      Offset(dotX, rect.center.dy),
      height,
      Paint()..color = tokens.structuralSecondaryAccent.withValues(alpha: 0.58),
    );
  }
}
