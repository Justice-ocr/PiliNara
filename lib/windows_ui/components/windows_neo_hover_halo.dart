import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

/// Adds a local Miku-cyan hover halo without changing a control's layout.
class WindowsNeoHoverHalo extends StatefulWidget {
  const WindowsNeoHoverHalo({
    super.key,
    required this.child,
    required this.borderRadius,
  });

  final Widget child;
  final BorderRadius borderRadius;

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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: tokens.motionFast,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: _hovered
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
                  duration: tokens.motionFast,
                  curve: Curves.easeOutCubic,
                  opacity: _hovered ? 1 : 0,
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
