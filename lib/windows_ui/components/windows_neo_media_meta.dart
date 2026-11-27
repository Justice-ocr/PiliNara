import 'package:PiliPlus/models/common/stat_type.dart';
import 'package:PiliPlus/utils/num_utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:material_ui/material_ui.dart';

class WindowsNeoMediaBadge extends StatelessWidget {
  const WindowsNeoMediaBadge({
    super.key,
    required this.text,
    this.icon,
  });

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final background = switch (tokens.family) {
      WindowsNeoThemeFamily.miku => const Color(0xFF202A2F),
      WindowsNeoThemeFamily.endfield => tokens.ink,
      WindowsNeoThemeFamily.ark => tokens.chromeSurface,
      WindowsNeoThemeFamily.exAstris => tokens.background,
      WindowsNeoThemeFamily.popucom => const Color(0xFF252B35),
      WindowsNeoThemeFamily.corporate => tokens.chromeSurface,
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background.withValues(alpha: 0.86),
        borderRadius: tokens.mediaBadgeRadius,
        border: Border.all(
          color: tokens.accent.withValues(alpha: 0.46),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 11, color: tokens.accent),
              const SizedBox(width: 3),
            ],
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontSize: 10.5,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  shadows: [
                    Shadow(
                      color: tokens.ink.withValues(alpha: 0.28),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WindowsNeoStat extends StatelessWidget {
  const WindowsNeoStat({
    super.key,
    required this.type,
    required this.value,
  });

  final StatType type;
  final dynamic value;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final usesRoundMarker = switch (tokens.family) {
      WindowsNeoThemeFamily.miku ||
      WindowsNeoThemeFamily.exAstris ||
      WindowsNeoThemeFamily.popucom => true,
      _ => false,
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            color: tokens.accentInk.withValues(alpha: 0.78),
            shape: usesRoundMarker ? BoxShape.circle : BoxShape.rectangle,
          ),
        ),
        const SizedBox(width: 4),
        Icon(
          type.iconData,
          semanticLabel: type.label,
          size: 12.5,
          color: tokens.muted,
        ),
        const SizedBox(width: 2),
        Text(
          NumUtils.numFormat(value),
          style: TextStyle(
            color: tokens.muted,
            fontSize: 11.5,
            height: 1,
            letterSpacing: 0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class WindowsNeoMediaDivider extends StatelessWidget {
  const WindowsNeoMediaDivider({super.key, this.axis = Axis.horizontal});

  final Axis axis;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final decoration = BoxDecoration(
      gradient: LinearGradient(
        begin: axis == Axis.horizontal
            ? Alignment.centerLeft
            : Alignment.topCenter,
        end: axis == Axis.horizontal
            ? Alignment.centerRight
            : Alignment.bottomCenter,
        colors: [
          tokens.accent.withValues(alpha: 0.30),
          tokens.structuralSecondaryAccent.withValues(alpha: 0.16),
          Colors.transparent,
        ],
        stops: const [0, 0.62, 1],
      ),
    );
    return axis == Axis.horizontal
        ? SizedBox(
            height: 1,
            width: double.infinity,
            child: DecoratedBox(decoration: decoration),
          )
        : SizedBox(
            width: 1,
            height: double.infinity,
            child: DecoratedBox(decoration: decoration),
          );
  }
}

/// Subtle bottom scrim placed over media thumbnails so badges remain crisp
/// even on bright covers.
class WindowsNeoCoverScrim extends StatelessWidget {
  const WindowsNeoCoverScrim({super.key, this.heightFactor = 0.40});

  final double heightFactor;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: heightFactor,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.16),
                    Colors.black.withValues(alpha: 0.48),
                  ],
                  stops: const [0, 0.52, 1],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum WindowsNeoTagTone { accent, outline, danger, neutral }

/// Theme-unified metadata tag that follows the active family's geometry
/// (rounded for Miku, squared for industrial/archive families) and high-contrast
/// foreground tokens.
class WindowsNeoTag extends StatelessWidget {
  const WindowsNeoTag({
    super.key,
    required this.text,
    this.tone = WindowsNeoTagTone.accent,
    this.fontSize = 10,
  });

  final String text;
  final WindowsNeoTagTone tone;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    final tokens = context.windowsNeo;
    final (Color bg, Color fg, Color border) = switch (tone) {
      WindowsNeoTagTone.accent => (
        tokens.accentSurface,
        tokens.accentInk,
        tokens.accentBorder.withValues(alpha: 0.34),
      ),
      WindowsNeoTagTone.outline => (
        Colors.transparent,
        tokens.accentInk,
        tokens.accentBorder.withValues(alpha: 0.65),
      ),
      WindowsNeoTagTone.danger => (
        const Color(0xFFD93848),
        Colors.white,
        const Color(0xFFFF6B7A).withValues(alpha: 0.55),
      ),
      WindowsNeoTagTone.neutral => (
        tokens.surfaceRaised,
        tokens.muted,
        tokens.border.withValues(alpha: 0.55),
      ),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: tokens.mediaBadgeRadius,
        border: Border.all(color: border, width: 0.8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        child: Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: fg,
            fontSize: fontSize,
            height: 1.05,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
            fontFamilyFallback: tokens.uiFontFallback,
          ),
        ),
      ),
    );
  }
}
