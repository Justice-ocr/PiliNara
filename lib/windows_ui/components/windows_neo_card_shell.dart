import 'package:PiliPlus/windows_ui/components/windows_neo_hover_halo.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

/// Cyan card shell with a short, non-layout-shifting hover lift.
class WindowsNeoCardShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return AnimatedSlide(
      offset: hovered ? const Offset(0, -0.012) : Offset.zero,
      duration: tokens.motionFast,
      curve: Curves.easeOutCubic,
      child: WindowsNeoHoverHalo(
        borderRadius: tokens.cardRadius,
        child: AnimatedContainer(
          duration: tokens.motionFast,
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: hovered ? tokens.surfaceRaised : tokens.surface,
            borderRadius: tokens.cardRadius,
            border: Border.all(
              color: hovered
                  ? tokens.accent.withValues(alpha: 0.22)
                  : tokens.border.withValues(alpha: 0.58),
            ),
            boxShadow: hovered ? tokens.cardHoverShadow : tokens.cardShadow,
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: tokens.cardRadius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              onSecondaryTap: onSecondaryTap,
              splashColor: tokens.accent.withValues(alpha: 0.06),
              highlightColor: tokens.accentSoft,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
