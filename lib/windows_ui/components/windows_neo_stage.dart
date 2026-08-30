import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:material_ui/material_ui.dart';

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

/// Semantic page scene for Windows-only composition. A scene is derived from
/// real navigation and content state; it never introduces synthetic telemetry.
enum WindowsNeoStageScene { home, discover, profile, archive, video, live }

extension WindowsNeoStageSceneLabel on WindowsNeoStageScene {
  String get label => switch (this) {
        WindowsNeoStageScene.home => 'HOME',
        WindowsNeoStageScene.discover => 'DISCOVER',
        WindowsNeoStageScene.profile => 'PROFILE',
        WindowsNeoStageScene.archive => 'ARCHIVE',
        WindowsNeoStageScene.video => 'VIDEO',
        WindowsNeoStageScene.live => 'LIVE',
      };

  WindowsNeoStageMode get mode => switch (this) {
        WindowsNeoStageScene.home ||
        WindowsNeoStageScene.discover ||
        WindowsNeoStageScene.profile ||
        WindowsNeoStageScene.archive =>
          WindowsNeoStageMode.browse,
        WindowsNeoStageScene.video => WindowsNeoStageMode.video,
        WindowsNeoStageScene.live => WindowsNeoStageMode.live,
      };
}

extension WindowsNeoStageModeScene on WindowsNeoStageMode {
  WindowsNeoStageScene get defaultScene => switch (this) {
        WindowsNeoStageMode.browse => WindowsNeoStageScene.discover,
        WindowsNeoStageMode.video => WindowsNeoStageScene.video,
        WindowsNeoStageMode.live => WindowsNeoStageScene.live,
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
    this.scene,
  });

  final WindowsNeoStageMode mode;
  final Widget child;
  final String? stateLabel;
  final int stateIndex;
  final WindowsNeoStageScene? scene;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final tokens = context.windowsNeo;
          final resolvedScene = scene ?? mode.defaultScene;
          final compact =
              constraints.maxWidth < 900 || constraints.maxHeight < 520;
          final playbackScene = resolvedScene == WindowsNeoStageScene.video ||
              resolvedScene == WindowsNeoStageScene.live;
          final showInstrumentation = !playbackScene &&
              !compact &&
              tokens.depth != WindowsNeoThemeDepth.minimal;
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
                      scene: resolvedScene,
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
                      scene: resolvedScene,
                    ),
                  ),
                ),
              if (showInstrumentation && stateLabel?.isNotEmpty == true)
                Positioned(
                  right: 20,
                  bottom: 12,
                  child: ExcludeSemantics(
                    child: _WindowsNeoStageStateDossier(
                      scene: resolvedScene,
                      stateLabel: stateLabel!,
                    ),
                  ),
                ),
            ],
          );
        },
      );
}

/// Gives the already-visible route/tab state one bounded visual owner on a
/// maximal stage. It intentionally contains no synthetic counters or status.
class _WindowsNeoStageStateDossier extends StatelessWidget {
  const _WindowsNeoStageStateDossier({
    required this.scene,
    required this.stateLabel,
  });

  final WindowsNeoStageScene scene;
  final String stateLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final label = '${scene.label} / $stateLabel';
    if (tokens.family == WindowsNeoThemeFamily.miku) {
      return Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.muted.withValues(alpha: 0.48),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontFamilyFallback: tokens.uiFontFallback,
            ),
      );
    }

    final darkSurface = switch (tokens.family) {
      WindowsNeoThemeFamily.ark ||
      WindowsNeoThemeFamily.exAstris ||
      WindowsNeoThemeFamily.corporate =>
        true,
      _ => false,
    };
    final foreground = darkSurface ? Colors.white : tokens.ink;
    final decoration = switch (tokens.family) {
      WindowsNeoThemeFamily.endfield => BoxDecoration(
          color: tokens.surfaceRaised.withValues(alpha: 0.92),
          border: Border(
            left: BorderSide(color: tokens.accent, width: 3),
            top: BorderSide(color: tokens.border.withValues(alpha: 0.72)),
            bottom: BorderSide(color: tokens.border.withValues(alpha: 0.72)),
            right: BorderSide(color: tokens.border.withValues(alpha: 0.72)),
          ),
        ),
      WindowsNeoThemeFamily.ark => BoxDecoration(
          color: tokens.chromeSurface.withValues(alpha: 0.92),
          border: Border(
            left: BorderSide(color: tokens.accent, width: 2),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.26)),
          ),
        ),
      WindowsNeoThemeFamily.exAstris => BoxDecoration(
          color: tokens.background.withValues(alpha: 0.90),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: tokens.accent.withValues(alpha: 0.58)),
        ),
      WindowsNeoThemeFamily.popucom => BoxDecoration(
          color: tokens.surfaceRaised.withValues(alpha: 0.96),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: tokens.accent, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: tokens.ink.withValues(alpha: 0.30),
              offset: const Offset(3, 3),
            ),
          ],
        ),
      WindowsNeoThemeFamily.corporate => BoxDecoration(
          color: tokens.chromeSurface.withValues(alpha: 0.92),
          border: Border(
            bottom: BorderSide(color: tokens.accent, width: 2),
            left: BorderSide(color: Colors.white.withValues(alpha: 0.28)),
          ),
        ),
      WindowsNeoThemeFamily.miku => const BoxDecoration(),
    };
    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foreground.withValues(alpha: 0.84),
                fontWeight: FontWeight.w700,
                letterSpacing: 1.15,
                fontFamilyFallback: tokens.uiFontFallback,
              ),
        ),
      ),
    );
  }
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
    this.scene,
  }) : assert(mode != WindowsNeoStageMode.browse);

  final WindowsNeoStageMode mode;
  final Widget child;
  final String? stateLabel;
  final int stateIndex;
  final WindowsNeoStageScene? scene;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final resolvedScene = scene ?? mode.defaultScene;
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxWidth < 640 || constraints.maxHeight < 360;
        final playbackScene = resolvedScene == WindowsNeoStageScene.video ||
            resolvedScene == WindowsNeoStageScene.live;
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
              if (!playbackScene)
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
                        scene: resolvedScene,
                      ),
                    ),
                  ),
                ),
              if (!playbackScene && !compact && stateLabel?.isNotEmpty == true)
                Positioned(
                  left: 12,
                  bottom: 10,
                  child: ExcludeSemantics(
                    child: AnimatedSwitcher(
                      duration:
                          reduceMotion ? Duration.zero : tokens.motionFast,
                      child: Text(
                        '${resolvedScene.label} / $stateLabel',
                        key: ValueKey('${resolvedScene.name}-$stateLabel'),
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
    required this.scene,
  });

  final WindowsNeoThemeFamily family;
  final WindowsNeoStageMode mode;
  final Color accent;
  final Color secondary;
  final int index;
  final WindowsNeoStageScene scene;

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
    _paintSceneCue(canvas, size);
  }

  void _paintSceneCue(Canvas canvas, Size size) {
    if (family == WindowsNeoThemeFamily.miku ||
        scene == WindowsNeoStageScene.video ||
        scene == WindowsNeoStageScene.live) {
      return;
    }
    switch (family) {
      case WindowsNeoThemeFamily.endfield:
        _paintEndfieldScene(canvas, size);
      case WindowsNeoThemeFamily.ark:
        _paintArkScene(canvas, size);
      case WindowsNeoThemeFamily.exAstris:
        _paintExAstrisScene(canvas, size);
      case WindowsNeoThemeFamily.popucom:
        _paintPopucomScene(canvas, size);
      case WindowsNeoThemeFamily.corporate:
        _paintCorporateScene(canvas, size);
      case WindowsNeoThemeFamily.miku:
        break;
    }
  }

  Paint _scenePaint(Color color, {double width = 1}) => Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width;

  void _paintEndfieldScene(Canvas canvas, Size size) {
    final paint = _scenePaint(accent);
    final secondaryPaint = _scenePaint(secondary);
    switch (scene) {
      case WindowsNeoStageScene.home:
        final origin = Offset(size.width * .08, size.height - 30);
        for (var step = 0; step < 4; step++) {
          final x = origin.dx + step * 38;
          canvas.drawLine(
            Offset(x, origin.dy),
            Offset(x, origin.dy - 42),
            paint,
          );
        }
        canvas.drawLine(
          origin,
          Offset(origin.dx + 140, origin.dy),
          secondaryPaint,
        );
      case WindowsNeoStageScene.discover:
        final top = size.height * .16;
        canvas
          ..drawLine(Offset(28, top), Offset(size.width * .28, top), paint)
          ..drawLine(
            Offset(size.width * .28, top),
            Offset(size.width * .34, top + 34),
            paint,
          )
          ..drawLine(
            Offset(size.width * .34, top + 34),
            Offset(size.width * .46, top + 34),
            secondaryPaint,
          );
      case WindowsNeoStageScene.profile:
        final identity = Rect.fromLTWH(28, size.height * .23, 96, 124);
        canvas
          ..drawRect(identity, paint)
          ..drawLine(
            identity.topLeft,
            Offset(identity.right, identity.top + 34),
            paint,
          )
          ..drawLine(
            Offset(identity.left, identity.bottom - 26),
            identity.bottomRight,
            secondaryPaint,
          );
      case WindowsNeoStageScene.archive:
        final left = size.width * .08;
        final top = size.height * .22;
        canvas.drawLine(Offset(left, top), Offset(left, top + 160), paint);
        for (var step = 0; step < 4; step++) {
          final y = top + step * 42;
          canvas
            ..drawRect(Rect.fromLTWH(left + 18, y - 8, 112, 16), secondaryPaint)
            ..drawLine(Offset(left - 5, y), Offset(left + 5, y), paint);
        }
      case WindowsNeoStageScene.video || WindowsNeoStageScene.live:
        break;
    }
  }

  void _paintArkScene(Canvas canvas, Size size) {
    final paint = _scenePaint(accent);
    final secondaryPaint = _scenePaint(secondary);
    switch (scene) {
      case WindowsNeoStageScene.home:
        final baseline = size.height * .18;
        canvas
          ..drawLine(
            Offset(30, baseline),
            Offset(size.width * .26, baseline),
            paint,
          )
          ..drawLine(Offset(30, baseline), Offset(30, baseline + 72), paint)
          ..drawRect(Rect.fromLTWH(46, baseline + 20, 88, 36), secondaryPaint);
      case WindowsNeoStageScene.discover:
        final dossier = Rect.fromLTWH(
          size.width * .06,
          size.height * .17,
          size.width * .24,
          56,
        );
        canvas
          ..drawRect(dossier, paint)
          ..drawLine(dossier.topLeft, dossier.bottomRight, secondaryPaint)
          ..drawLine(
            Offset(dossier.left, dossier.bottom + 20),
            Offset(dossier.right, dossier.bottom + 20),
            paint,
          );
      case WindowsNeoStageScene.profile:
        final card = Rect.fromLTWH(28, size.height * .20, 124, 148);
        canvas
          ..drawRect(card, paint)
          ..drawCircle(
            Offset(card.left + 32, card.top + 36),
            14,
            secondaryPaint,
          )
          ..drawLine(
            Offset(card.left + 20, card.bottom - 28),
            Offset(card.right - 18, card.bottom - 28),
            secondaryPaint,
          );
      case WindowsNeoStageScene.archive:
        final x = size.width * .12;
        final top = size.height * .18;
        canvas.drawLine(Offset(x, top), Offset(x, top + 180), paint);
        for (var step = 0; step < 4; step++) {
          final y = top + step * 48;
          canvas
            ..drawLine(Offset(x - 7, y), Offset(x + 7, y), secondaryPaint)
            ..drawLine(Offset(x + 18, y), Offset(x + 156, y), paint);
        }
      case WindowsNeoStageScene.video || WindowsNeoStageScene.live:
        break;
    }
  }

  void _paintExAstrisScene(Canvas canvas, Size size) {
    final paint = _scenePaint(accent);
    final secondaryPaint = _scenePaint(secondary);
    switch (scene) {
      case WindowsNeoStageScene.home:
        final center = Offset(size.width * .18, size.height * .24);
        canvas
          ..drawOval(
            Rect.fromCenter(center: center, width: 164, height: 52),
            paint,
          )
          ..drawCircle(center, 4, secondaryPaint)
          ..drawLine(
            Offset(center.dx - 96, center.dy + 46),
            Offset(center.dx + 102, center.dy + 46),
            secondaryPaint,
          );
      case WindowsNeoStageScene.discover:
        final center = Offset(size.width * .14, size.height * .29);
        canvas
          ..drawOval(
            Rect.fromCenter(center: center, width: 92, height: 154),
            paint,
          )
          ..drawOval(
            Rect.fromCenter(center: center, width: 152, height: 64),
            secondaryPaint,
          );
      case WindowsNeoStageScene.profile:
        final center = Offset(size.width * .14, size.height * .31);
        canvas
          ..drawCircle(center, 48, paint)
          ..drawCircle(center, 26, secondaryPaint)
          ..drawLine(
            Offset(center.dx - 78, center.dy + 72),
            Offset(center.dx + 78, center.dy + 72),
            paint,
          );
      case WindowsNeoStageScene.archive:
        final center = Offset(size.width * .16, size.height * .30);
        canvas
          ..drawOval(
            Rect.fromCenter(center: center, width: 180, height: 66),
            paint,
          )
          ..drawLine(
            Offset(28, center.dy + 72),
            Offset(size.width * .36, center.dy + 72),
            secondaryPaint,
          );
      case WindowsNeoStageScene.video || WindowsNeoStageScene.live:
        break;
    }
  }

  void _paintPopucomScene(Canvas canvas, Size size) {
    final paint = _scenePaint(accent, width: 1.4);
    final secondaryPaint = _scenePaint(secondary, width: 1.4);
    switch (scene) {
      case WindowsNeoStageScene.home:
        for (var step = 0; step < 3; step++) {
          canvas.drawCircle(
            Offset(42 + step * 46, size.height * .22 + (step.isOdd ? 14 : 0)),
            15,
            step == index % 3 ? paint : secondaryPaint,
          );
        }
      case WindowsNeoStageScene.discover:
        for (var step = 0; step < 3; step++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(30, size.height * .18 + step * 36, 104, 22),
              Radius.zero,
            ),
            step == index % 3 ? paint : secondaryPaint,
          );
        }
      case WindowsNeoStageScene.profile:
        final card = RRect.fromRectAndRadius(
          Rect.fromLTWH(28, size.height * .18, 128, 104),
          Radius.zero,
        );
        canvas
          ..drawRRect(card, paint)
          ..drawCircle(
            Offset(card.left + 34, card.top + 34),
            16,
            secondaryPaint,
          )
          ..drawLine(
            Offset(card.left + 64, card.bottom - 24),
            Offset(card.right - 18, card.bottom - 24),
            secondaryPaint,
          );
      case WindowsNeoStageScene.archive:
        final y = size.height * .20;
        for (var step = 0; step < 4; step++) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(28 + step * 40, y + step * 26, 28, 18),
              Radius.zero,
            ),
            step == index % 4 ? paint : secondaryPaint,
          );
        }
      case WindowsNeoStageScene.video || WindowsNeoStageScene.live:
        break;
    }
  }

  void _paintCorporateScene(Canvas canvas, Size size) {
    final paint = _scenePaint(accent);
    final secondaryPaint = _scenePaint(secondary);
    switch (scene) {
      case WindowsNeoStageScene.home:
        final block = Rect.fromLTWH(
          28,
          size.height * .16,
          size.width * .24,
          96,
        );
        canvas
          ..drawRect(block, paint)
          ..drawLine(
            Offset(block.left, block.bottom + 20),
            Offset(block.right, block.bottom + 20),
            secondaryPaint,
          );
      case WindowsNeoStageScene.discover:
        const left = 28.0;
        final top = size.height * .16;
        for (var step = 0; step < 3; step++) {
          canvas.drawRect(
            Rect.fromLTWH(left, top + step * 34, size.width * .28, 22),
            step == index % 3 ? paint : secondaryPaint,
          );
        }
      case WindowsNeoStageScene.profile:
        final portrait = Rect.fromLTWH(28, size.height * .16, 116, 144);
        canvas
          ..drawRect(portrait, paint)
          ..drawLine(portrait.topLeft, portrait.bottomRight, secondaryPaint)
          ..drawLine(
            Offset(portrait.right + 16, portrait.top),
            Offset(portrait.right + 16, portrait.bottom),
            paint,
          );
      case WindowsNeoStageScene.archive:
        final top = size.height * .20;
        for (var step = 0; step < 4; step++) {
          final width = step == index % 4 ? 156.0 : 114.0;
          canvas.drawLine(
            Offset(28, top + step * 36),
            Offset(28 + width, top + step * 36),
            step == index % 4 ? paint : secondaryPaint,
          );
        }
      case WindowsNeoStageScene.video || WindowsNeoStageScene.live:
        break;
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
          Radius.zero,
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
      oldDelegate.index != index ||
      oldDelegate.scene != scene;
}

/// Keeps the visual stage present when dense media cards cover most of the
/// background. Every motif is an outline and lives at the stage perimeter.
class _WindowsNeoStageOutlinePainter extends CustomPainter {
  const _WindowsNeoStageOutlinePainter({
    required this.family,
    required this.mode,
    required this.accent,
    required this.secondary,
    required this.scene,
  });

  final WindowsNeoThemeFamily family;
  final WindowsNeoStageMode mode;
  final Color accent;
  final Color secondary;
  final WindowsNeoStageScene scene;

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
              Radius.zero,
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
      oldDelegate.secondary != secondary ||
      oldDelegate.scene != scene;
}

class _WindowsNeoMediaStagePainter extends _WindowsNeoStagePainter {
  const _WindowsNeoMediaStagePainter({
    required super.family,
    required super.mode,
    required super.accent,
    required super.secondary,
    required super.index,
    required super.scene,
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
        final activeMarker = Paint()
          ..color = alphaSecondary
          ..strokeWidth = 2;
        if (mode == WindowsNeoStageMode.video) {
          final baseline = size.height - 32;
          canvas
            ..drawLine(
              const Offset(16, 14),
              Offset(size.width - 16, 14),
              paint,
            )
            ..drawLine(
              Offset(size.width - 16, 14),
              Offset(size.width - 16, baseline),
              paint,
            )
            ..drawLine(
              Offset(16, baseline),
              Offset(size.width - 16, baseline),
              paint,
            );
          for (var slot = 0; slot < 4; slot++) {
            final x = 28 + slot * 34.0;
            canvas.drawLine(
              Offset(x, baseline - 8),
              Offset(x, baseline + (slot == index % 4 ? 8 : 3)),
              slot == index % 4 ? activeMarker : paint,
            );
          }
        } else {
          final railLeft = size.width - 38;
          final markerTop = 34 + (index % 3) * 34.0;
          canvas
            ..drawLine(const Offset(16, 14), Offset(railLeft, 14), paint)
            ..drawLine(
              Offset(railLeft, 14),
              Offset(railLeft, size.height - 16),
              paint,
            )
            ..drawLine(
              Offset(16, size.height - 16),
              Offset(railLeft, size.height - 16),
              paint,
            )
            ..drawLine(
              Offset(railLeft - 12, markerTop),
              Offset(railLeft + 12, markerTop),
              activeMarker,
            );
        }
      case WindowsNeoThemeFamily.endfield:
        final guide = Paint()
          ..color = alphaSecondary
          ..strokeWidth = 1;
        canvas
          ..drawPath(
            Path()
              ..moveTo(size.width - 58, 0)
              ..lineTo(size.width, 0)
              ..lineTo(size.width, 48)
              ..close(),
            Paint()
              ..color = alphaAccent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          )
          ..drawLine(
            Offset(16, size.height - 28),
            Offset(size.width - 16, size.height - 28),
            guide,
          );
        if (mode == WindowsNeoStageMode.video) {
          for (var slot = 0; slot < 5; slot++) {
            final left = 28 + slot * 42.0;
            final rect = Rect.fromLTWH(left, size.height - 43, 34, 9);
            canvas.drawRect(
              rect,
              Paint()
                ..color = slot == index % 5 ? alphaAccent : alphaSecondary
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1,
            );
          }
        } else {
          final railTop = 30 + (index % 3) * 34.0;
          canvas
            ..drawLine(Offset(16, railTop), Offset(76, railTop), guide)
            ..drawLine(
              Offset(16, railTop + 12),
              Offset(52, railTop + 12),
              guide,
            )
            ..drawLine(
              Offset(16, railTop + 24),
              Offset(92, railTop + 24),
              Paint()
                ..color = alphaAccent
                ..strokeWidth = 2,
            );
        }
      case WindowsNeoThemeFamily.exAstris:
        final paint = Paint()
          ..color = alphaAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        final center = Offset(size.width * .86, size.height * .20);
        final points = <Offset>[
          Offset(center.dx - 54, center.dy - 12),
          Offset(center.dx + 44, center.dy + 14),
          Offset(center.dx + 8, center.dy - 34),
        ];
        canvas
          ..drawOval(
            Rect.fromCenter(center: center, width: 150, height: 54),
            paint,
          )
          ..drawOval(
            Rect.fromCenter(center: center, width: 66, height: 108),
            paint,
          );
        for (var pointIndex = 0; pointIndex < points.length; pointIndex++) {
          canvas.drawCircle(
            points[pointIndex],
            pointIndex == index % points.length ? 4 : 1.5,
            Paint()
              ..color = pointIndex == index % points.length
                  ? alphaSecondary
                  : alphaAccent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        }
      case WindowsNeoThemeFamily.popucom:
        final offset = (index % 3) * 14.0;
        canvas.drawCircle(
          Offset(size.width - 34 - offset, 32),
          18,
          Paint()
            ..color = alphaAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
        canvas.drawCircle(
          Offset(size.width - 76 + offset, 52),
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
        final baseline = size.height - 16;
        final selection = 34 + (index % 4) * 32.0;
        canvas
          ..drawLine(
            const Offset(16, 16),
            Offset(size.width - 16, 16),
            paint,
          )
          ..drawLine(
            Offset(size.width - 16, 16),
            Offset(size.width - 16, baseline),
            paint,
          )
          ..drawLine(
            Offset(16, baseline),
            Offset(size.width - 16, baseline),
            paint,
          )
          ..drawLine(
            Offset(selection, baseline - 16),
            Offset(selection, baseline),
            Paint()
              ..color = alphaSecondary
              ..strokeWidth = 3,
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
