import 'package:PiliPlus/windows_ui/components/windows_neo_hover_halo.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';

/// Cyan card shell with a short, non-layout-shifting hover lift.
class WindowsNeoCardShell extends StatefulWidget {
  const WindowsNeoCardShell({
    super.key,
    required this.hovered,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onSecondaryTap,
  });

  final bool hovered;
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onSecondaryTap;

  @override
  State<WindowsNeoCardShell> createState() => _WindowsNeoCardShellState();
}

class _WindowsNeoCardShellState extends State<WindowsNeoCardShell> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final highlighted = widget.hovered || _focused;
    return AnimatedSlide(
      offset: highlighted ? const Offset(0, -0.012) : Offset.zero,
      duration: context.windowsNeoDuration(tokens.motionFast),
      curve: Curves.easeOutCubic,
      child: WindowsNeoHoverHalo(
        borderRadius: tokens.cardRadius,
        active: _focused,
        child: AnimatedContainer(
          duration: context.windowsNeoDuration(tokens.motionFast),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: highlighted ? tokens.surfaceRaised : tokens.surface,
            borderRadius: tokens.cardRadius,
            border: Border.all(
              color: highlighted
                  ? tokens.accent.withValues(alpha: 0.34)
                  : tokens.border.withValues(alpha: 0.40),
            ),
            boxShadow: highlighted ? tokens.cardHoverShadow : tokens.cardShadow,
          ),
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              Material(
                color: Colors.transparent,
                borderRadius: tokens.cardRadius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  onSecondaryTap: widget.onSecondaryTap,
                  onFocusChange: (focused) {
                    if (_focused != focused) setState(() => _focused = focused);
                  },
                  focusColor: tokens.accentSoft,
                  splashColor: tokens.accent.withValues(alpha: 0.06),
                  highlightColor: tokens.accentSoft,
                  child: widget.child,
                ),
              ),
              Positioned(
                top: 0,
                left: tokens.spaceLg,
                right: tokens.spaceLg,
                height: highlighted ? 2 : 1,
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: 0.28,
                      end: highlighted ? 1 : 0.28,
                    ),
                    duration: context.windowsNeoDuration(tokens.motionFast),
                    curve: Curves.easeOutCubic,
                    builder: (context, widthFactor, child) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: widthFactor,
                        child: AnimatedOpacity(
                          duration: context.windowsNeoDuration(
                            tokens.motionFast,
                          ),
                          opacity: highlighted ? 0.82 : 0.42,
                          child: child,
                        ),
                      ),
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: tokens.cardAccentGradient,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
