import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:material_ui/material_ui.dart';

/// Adds a theme-aware hover halo without changing a control's layout.
class WindowsNeoHoverHalo extends StatefulWidget {
  const WindowsNeoHoverHalo({
    super.key,
    required this.child,
    required this.borderRadius,
    this.enabled = true,
    this.active = false,
  });

  final Widget child;
  final BorderRadius borderRadius;
  final bool enabled;
  final bool active;

  @override
  State<WindowsNeoHoverHalo> createState() => _WindowsNeoHoverHaloState();
}

class _WindowsNeoHoverHaloState extends State<WindowsNeoHoverHalo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final visible = _hovered || widget.active;

    if (!widget.enabled) return widget.child;

    final haloAlpha = isDark ? 0.17 : 0.11;
    final decoration = switch (tokens.family) {
      WindowsNeoThemeFamily.miku ||
      WindowsNeoThemeFamily.popucom => BoxDecoration(
        borderRadius: widget.borderRadius,
        gradient: RadialGradient(
          center: const Alignment(-0.45, -0.55),
          radius: 1.25,
          colors: [
            tokens.accent.withValues(alpha: haloAlpha),
            tokens.structuralSecondaryAccent.withValues(
              alpha: haloAlpha * 0.62,
            ),
            tokens.tertiaryAccent.withValues(alpha: haloAlpha * 0.20),
            Colors.transparent,
          ],
          stops: const [0, 0.42, 0.70, 1],
        ),
      ),
      WindowsNeoThemeFamily.exAstris => BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border.all(color: tokens.accent.withValues(alpha: 0.42)),
        gradient: RadialGradient(
          center: Alignment.centerRight,
          radius: 1.12,
          colors: [
            tokens.accent.withValues(alpha: haloAlpha * 0.54),
            Colors.transparent,
          ],
        ),
      ),
      WindowsNeoThemeFamily.corporate => BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border(
          bottom: BorderSide(color: tokens.accent, width: visible ? 2 : 1),
        ),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            tokens.accent.withValues(alpha: haloAlpha * 0.40),
            Colors.transparent,
          ],
        ),
      ),
      _ => BoxDecoration(
        borderRadius: widget.borderRadius,
        border: Border(
          left: BorderSide(color: tokens.accent, width: visible ? 2 : 1),
        ),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            tokens.accent.withValues(alpha: haloAlpha * 0.54),
            Colors.transparent,
          ],
        ),
      ),
    };
    final boxShadow = switch (tokens.family) {
      WindowsNeoThemeFamily.miku || WindowsNeoThemeFamily.popucom => [
        BoxShadow(
          color: tokens.accent.withValues(alpha: haloAlpha),
          blurRadius: 16,
          spreadRadius: 1,
        ),
      ],
      WindowsNeoThemeFamily.exAstris => [
        BoxShadow(
          color: tokens.accent.withValues(alpha: haloAlpha * 0.42),
          blurRadius: 12,
        ),
      ],
      _ => const <BoxShadow>[],
    };

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: context.windowsNeoDuration(tokens.motionFast),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: visible ? boxShadow : const [],
        ),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedOpacity(
                  duration: context.windowsNeoDuration(tokens.motionFast),
                  curve: Curves.easeOutCubic,
                  opacity: visible ? 1 : 0,
                  child: DecoratedBox(decoration: decoration),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
