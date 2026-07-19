import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';

/// Adds a local Miku-cyan hover halo without changing a control's layout.
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
    final haloAlpha = isDark ? 0.17 : 0.11;
    final visible = _hovered || widget.active;

    if (!widget.enabled) return widget.child;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: context.windowsNeoDuration(tokens.motionFast),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: visible
              ? [
                  BoxShadow(
                    color: tokens.accent.withValues(alpha: haloAlpha),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : const [],
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
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: widget.borderRadius,
                      gradient: RadialGradient(
                        center: const Alignment(-0.45, -0.55),
                        radius: 1.25,
                        colors: [
                          tokens.accent.withValues(alpha: haloAlpha),
                          const Color(0xFF70D8E6).withValues(
                            alpha: haloAlpha * 0.62,
                          ),
                          const Color(0xFFFFA2BD).withValues(
                            alpha: haloAlpha * 0.20,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0, 0.42, 0.70, 1],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
