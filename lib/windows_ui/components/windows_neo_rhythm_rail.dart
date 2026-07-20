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
  Widget build(BuildContext context) => SizedBox(
    height: height,
    width: double.infinity,
    child: CustomPaint(
      painter: _WindowsNeoRhythmRailPainter(
        trackColor: context.windowsNeo.rhythmTrackColor,
        beatColor: context.windowsNeo.accent.withValues(alpha: 0.28),
        showBeats: showBeats,
      ),
    ),
  );
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
        borderRadius: BorderRadius.circular(height),
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
  Widget build(BuildContext context) => SizedBox(
    height: 2,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: context.windowsNeo.rhythmGradient,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
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
        ),
      ),
    );
  }
}

class WindowsNeoHeaderWave extends StatelessWidget {
  const WindowsNeoHeaderWave({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    key: const Key('windows-neo-header-wave'),
    width: 168,
    height: 28,
    child: CustomPaint(
      painter: _WindowsNeoHeaderWavePainter(
        primary: context.windowsNeo.accent.withValues(alpha: 0.11),
        secondary: WindowsNeoTokens.iceCyan.withValues(alpha: 0.075),
      ),
    ),
  );
}

class WindowsNeoTabIndicator extends Decoration {
  const WindowsNeoTabIndicator({this.width = 38, this.height = 2.5});

  final double width;
  final double height;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) =>
      _WindowsNeoTabIndicatorPainter(width: width, height: height);
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
  });

  final Gradient gradient;
  final Color mutedColor;

  @override
  void paint(Canvas canvas, Size size) {
    final lineRect = Rect.fromLTWH(0, 0, 2, size.height);
    canvas.drawRRect(
      RRect.fromRectAndRadius(lineRect, const Radius.circular(2)),
      Paint()..shader = gradient.createShader(lineRect),
    );
    final beatPaint = Paint()..color = mutedColor;
    canvas
      ..drawCircle(Offset(size.width - 1.5, 7), 1.5, beatPaint)
      ..drawCircle(Offset(size.width - 1.5, 22), 1.5, beatPaint);
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoHeaderBeatPainter oldDelegate) =>
      oldDelegate.gradient != gradient || oldDelegate.mutedColor != mutedColor;
}

class _WindowsNeoHeaderWavePainter extends CustomPainter {
  const _WindowsNeoHeaderWavePainter({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.height / 2;
    final primaryPaint = Paint()
      ..color = primary
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final secondaryPaint = Paint()
      ..color = secondary
      ..strokeWidth = 1;
    final path = Path()..moveTo(0, center);
    const levels = [0.0, -4.0, 7.0, -10.0, 5.0, -2.0, 8.0, -5.0, 0.0];
    final step = size.width / (levels.length - 1);
    for (var index = 1; index < levels.length; index++) {
      path.lineTo(step * index, center + levels[index]);
    }
    canvas.drawPath(path, primaryPaint);
    for (final position in const [0.18, 0.39, 0.72]) {
      final x = size.width * position;
      canvas.drawLine(
        Offset(x, center - 10),
        Offset(x, center + 10),
        secondaryPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WindowsNeoHeaderWavePainter oldDelegate) =>
      oldDelegate.primary != primary || oldDelegate.secondary != secondary;
}

class _WindowsNeoTabIndicatorPainter extends BoxPainter {
  _WindowsNeoTabIndicatorPainter({required this.width, required this.height});

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
    final selectionGradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [
        WindowsNeoTokens.mikuCyan.withValues(alpha: 0.14),
        Colors.white.withValues(alpha: 0.26),
        WindowsNeoTokens.iceCyan.withValues(alpha: 0.08),
      ],
      stops: const [0, 0.68, 1],
    );
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(selectionRect, const Radius.circular(5)),
        Paint()..shader = selectionGradient.createShader(selectionRect),
      )
      ..drawRRect(
        RRect.fromRectAndRadius(selectionRect, const Radius.circular(5)),
        Paint()
          ..color = WindowsNeoTokens.mikuCyan.withValues(alpha: 0.16)
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
    const gradient = LinearGradient(
      colors: [WindowsNeoTokens.mikuCyan, WindowsNeoTokens.iceCyan],
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(height)),
      Paint()..shader = gradient.createShader(rect),
    );
    if (context == null) return;
    final dotX = context == TextDirection.ltr ? rect.right : rect.left;
    canvas.drawCircle(
      Offset(dotX, rect.center.dy),
      height,
      Paint()..color = WindowsNeoTokens.iceCyan.withValues(alpha: 0.58),
    );
  }
}
