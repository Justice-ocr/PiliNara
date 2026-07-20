import 'dart:ui' show FontFeature, lerpDouble;

import 'package:flutter/material.dart';

/// Miku-cyan dashboard language for Windows Neo.
/// Airy surfaces, low-noise borders, and a bright cyan focal color.
@immutable
class WindowsNeoTokens extends ThemeExtension<WindowsNeoTokens> {
  const WindowsNeoTokens({
    required this.background,
    required this.sidebar,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.muted,
    required this.hover,
    required this.accent,
    required this.accentSurface,
    required this.accentSoft,
    required this.ink,
    this.radiusSm = 8,
    this.radiusMd = 10,
    this.radiusLg = 16,
    this.spaceXs = 4,
    this.spaceSm = 8,
    this.spaceMd = 12,
    this.spaceLg = 16,
    this.spaceXl = 20,
    this.pagePadding = 24,
    this.pageHeaderHeight = 54,
    this.sectionTabHeight = 36,
    this.videoCardMetaHeight = 104,
    this.horizontalCardHeight = 124,
    this.gridGap = 16,
    this.motionFast = const Duration(milliseconds: 140),
    this.motionStandard = const Duration(milliseconds: 200),
    this.motionPage = const Duration(milliseconds: 240),
    this.motionLoading = const Duration(milliseconds: 1100),
    this.motionStagger = const Duration(milliseconds: 28),
  });

  /// Miku's cyan anchor, with ice-blue and sakura accents used sparingly.
  static const Color mikuCyan = Color(0xFF39C5BB);
  static const Color iceCyan = Color(0xFF70D8E6);
  static const Color sakuraPink = Color(0xFFFFA2BD);
  static const Color inkDefault = Color(0xFF2C3A43);

  factory WindowsNeoTokens.fromTheme(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    // Windows Neo has its own visual language. Keep its primary signal stable
    // instead of inheriting a potentially forest-green user seed.
    const accent = mikuCyan;
    // Dark mode is graphite with a cool cyan bias, rather than a green-on-green
    // stack. The player can therefore remain a neutral dark surface.
    final surface = isDark ? const Color(0xFF202A2F) : const Color(0xFFFAFDFC);
    return WindowsNeoTokens(
      background: isDark ? const Color(0xFF11191D) : const Color(0xFFEEF6F5),
      sidebar: isDark ? const Color(0xFF172327) : const Color(0xFFE0F0EE),
      surface: surface,
      surfaceRaised: isDark ? const Color(0xFF29363B) : const Color(0xFFFFFFFF),
      border: isDark ? const Color(0xFF465960) : const Color(0xFFB2D2CF),
      muted: isDark ? const Color(0xFFA9B9BE) : const Color(0xFF5F747A),
      hover: isDark ? const Color(0xFF34464D) : const Color(0xFFD8ECE9),
      accent: accent,
      accentSurface: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.22 : 0.12),
        surface,
      ),
      accentSoft: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.16 : 0.08),
        surface,
      ),
      ink: isDark ? const Color(0xFFE8EEEC) : inkDefault,
    );
  }

  final Color background;
  final Color sidebar;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color muted;
  final Color hover;
  final Color accent;
  final Color accentSurface;
  final Color accentSoft;
  final Color ink;

  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double pagePadding;
  final double pageHeaderHeight;
  final double sectionTabHeight;
  final double videoCardMetaHeight;
  final double horizontalCardHeight;
  final double gridGap;
  final Duration motionFast;
  final Duration motionStandard;
  final Duration motionPage;
  final Duration motionLoading;
  final Duration motionStagger;

  BorderRadius get cardRadius => BorderRadius.circular(radiusMd);
  BorderRadius get chipRadius => BorderRadius.circular(radiusSm);
  BorderRadius get panelRadius => BorderRadius.circular(radiusLg);

  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF18383B).withValues(alpha: 0.065),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  List<BoxShadow> get cardHoverShadow => [
    BoxShadow(
      color: accent.withValues(alpha: 0.10),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  LinearGradient get accentBannerGradient => LinearGradient(
    colors: [
      Color.lerp(accent, mikuCyan, 0.25)!,
      Color.lerp(accent, const Color(0xFF75D8D2), 0.45)!,
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  LinearGradient get workspaceTabGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color.alphaBlend(accent.withValues(alpha: 0.14), surfaceRaised),
      Color.alphaBlend(
        Colors.white.withValues(
          alpha: surface.computeLuminance() < 0.1 ? 0.07 : 0.50,
        ),
        surfaceRaised,
      ),
    ],
  );

  LinearGradient get cardAccentGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      accent.withValues(alpha: 0.82),
      iceCyan.withValues(alpha: 0.48),
      sakuraPink.withValues(alpha: 0.22),
    ],
    stops: const [0, 0.62, 1],
  );

  Color get rhythmTrackColor => border.withValues(alpha: 0.52);

  LinearGradient get rhythmGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [accent, iceCyan, sakuraPink.withValues(alpha: 0.42)],
    stops: const [0, 0.78, 1],
  );

  LinearGradient get sidebarSelectionGradient => LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color.alphaBlend(accent.withValues(alpha: 0.88), sidebar),
      Color.alphaBlend(accent.withValues(alpha: 0.56), sidebar),
      Color.alphaBlend(
        Colors.white.withValues(alpha: 0.42),
        Color.alphaBlend(accent.withValues(alpha: 0.20), sidebar),
      ),
    ],
    stops: const [0, 0.58, 1],
  );

  TextStyle pageTitleStyle(TextTheme textTheme) =>
      (textTheme.titleMedium ?? const TextStyle(fontSize: 18)).copyWith(
        color: ink,
        fontWeight: FontWeight.w700,
        height: 1.15,
        letterSpacing: 0,
      );

  TextStyle pageSubtitleStyle(TextTheme textTheme) =>
      (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
        color: muted,
        height: 1.2,
      );

  TextStyle cardTitleStyle(TextTheme textTheme) =>
      (textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
        color: ink,
        fontWeight: FontWeight.w600,
        height: 1.35,
        fontSize: 13.5,
      );

  TextStyle cardMetaStyle(TextTheme textTheme) =>
      (textTheme.labelMedium ?? const TextStyle(fontSize: 12)).copyWith(
        color: muted,
        height: 1.2,
      );

  TextStyle cardCaptionStyle(TextTheme textTheme) =>
      (textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
        color: muted,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  @override
  WindowsNeoTokens copyWith({
    Color? background,
    Color? sidebar,
    Color? surface,
    Color? surfaceRaised,
    Color? border,
    Color? muted,
    Color? hover,
    Color? accent,
    Color? accentSurface,
    Color? accentSoft,
    Color? ink,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? pagePadding,
    double? pageHeaderHeight,
    double? sectionTabHeight,
    double? videoCardMetaHeight,
    double? horizontalCardHeight,
    double? gridGap,
    Duration? motionFast,
    Duration? motionStandard,
    Duration? motionPage,
    Duration? motionLoading,
    Duration? motionStagger,
  }) => WindowsNeoTokens(
    background: background ?? this.background,
    sidebar: sidebar ?? this.sidebar,
    surface: surface ?? this.surface,
    surfaceRaised: surfaceRaised ?? this.surfaceRaised,
    border: border ?? this.border,
    muted: muted ?? this.muted,
    hover: hover ?? this.hover,
    accent: accent ?? this.accent,
    accentSurface: accentSurface ?? this.accentSurface,
    accentSoft: accentSoft ?? this.accentSoft,
    ink: ink ?? this.ink,
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    radiusLg: radiusLg ?? this.radiusLg,
    spaceXs: spaceXs ?? this.spaceXs,
    spaceSm: spaceSm ?? this.spaceSm,
    spaceMd: spaceMd ?? this.spaceMd,
    spaceLg: spaceLg ?? this.spaceLg,
    spaceXl: spaceXl ?? this.spaceXl,
    pagePadding: pagePadding ?? this.pagePadding,
    pageHeaderHeight: pageHeaderHeight ?? this.pageHeaderHeight,
    sectionTabHeight: sectionTabHeight ?? this.sectionTabHeight,
    videoCardMetaHeight: videoCardMetaHeight ?? this.videoCardMetaHeight,
    horizontalCardHeight: horizontalCardHeight ?? this.horizontalCardHeight,
    gridGap: gridGap ?? this.gridGap,
    motionFast: motionFast ?? this.motionFast,
    motionStandard: motionStandard ?? this.motionStandard,
    motionPage: motionPage ?? this.motionPage,
    motionLoading: motionLoading ?? this.motionLoading,
    motionStagger: motionStagger ?? this.motionStagger,
  );

  @override
  WindowsNeoTokens lerp(WindowsNeoTokens? other, double t) {
    if (other == null) return this;
    return WindowsNeoTokens(
      background: Color.lerp(background, other.background, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      border: Color.lerp(border, other.border, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      hover: Color.lerp(hover, other.hover, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSurface: Color.lerp(accentSurface, other.accentSurface, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t)!,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t)!,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t)!,
      spaceXs: lerpDouble(spaceXs, other.spaceXs, t)!,
      spaceSm: lerpDouble(spaceSm, other.spaceSm, t)!,
      spaceMd: lerpDouble(spaceMd, other.spaceMd, t)!,
      spaceLg: lerpDouble(spaceLg, other.spaceLg, t)!,
      spaceXl: lerpDouble(spaceXl, other.spaceXl, t)!,
      pagePadding: lerpDouble(pagePadding, other.pagePadding, t)!,
      pageHeaderHeight: lerpDouble(
        pageHeaderHeight,
        other.pageHeaderHeight,
        t,
      )!,
      sectionTabHeight: lerpDouble(
        sectionTabHeight,
        other.sectionTabHeight,
        t,
      )!,
      videoCardMetaHeight: lerpDouble(
        videoCardMetaHeight,
        other.videoCardMetaHeight,
        t,
      )!,
      horizontalCardHeight: lerpDouble(
        horizontalCardHeight,
        other.horizontalCardHeight,
        t,
      )!,
      gridGap: lerpDouble(gridGap, other.gridGap, t)!,
      motionFast: t < 0.5 ? motionFast : other.motionFast,
      motionStandard: t < 0.5 ? motionStandard : other.motionStandard,
      motionPage: t < 0.5 ? motionPage : other.motionPage,
      motionLoading: t < 0.5 ? motionLoading : other.motionLoading,
      motionStagger: t < 0.5 ? motionStagger : other.motionStagger,
    );
  }
}

abstract final class WindowsNeoTheme {
  static ThemeData apply(ThemeData base) {
    final tokens = WindowsNeoTokens.fromTheme(base);
    final extensions =
        base.extensions.values
            .where((item) => item is! WindowsNeoTokens)
            .toList()
          ..add(tokens);
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      borderSide: BorderSide(color: tokens.border),
    );

    return base.copyWith(
      scaffoldBackgroundColor: tokens.background,
      canvasColor: tokens.surface,
      dividerColor: tokens.border,
      visualDensity: VisualDensity.compact,
      appBarTheme: base.appBarTheme.copyWith(
        backgroundColor: tokens.surface,
        foregroundColor: tokens.ink,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: base.cardTheme.copyWith(
        color: tokens.surface,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: tokens.cardRadius,
          side: BorderSide(color: tokens.border.withValues(alpha: 0.9)),
        ),
      ),
      inputDecorationTheme: base.inputDecorationTheme.copyWith(
        filled: true,
        fillColor: tokens.surfaceRaised,
        isDense: true,
        border: outline,
        enabledBorder: outline,
        focusedBorder: outline.copyWith(
          borderSide: BorderSide(color: tokens.accent, width: 1.4),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: tokens.spaceMd,
          vertical: 10,
        ),
      ),
      popupMenuTheme: base.popupMenuTheme.copyWith(
        color: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 10,
        shadowColor: const Color(0xFF18383B).withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: tokens.cardRadius,
          side: BorderSide(color: tokens.border),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shadowColor: const Color(0xFF18383B).withValues(alpha: 0.16),
        barrierColor: Colors.black.withValues(alpha: 0.30),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: tokens.panelRadius,
          side: BorderSide(
            color: tokens.border.withValues(alpha: 0.52),
          ),
        ),
      ),
      bottomSheetTheme: base.bottomSheetTheme.copyWith(
        backgroundColor: tokens.surface,
        modalBackgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 12,
        modalElevation: 18,
        shadowColor: const Color(0xFF18383B).withValues(alpha: 0.16),
        modalBarrierColor: Colors.black.withValues(alpha: 0.30),
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(tokens.radiusLg),
          ),
          side: BorderSide(
            color: tokens.border.withValues(alpha: 0.46),
          ),
        ),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          ...base.pageTransitionsTheme.builders,
          TargetPlatform.windows: const WindowsNeoPageTransitionsBuilder(),
        },
      ),
      tabBarTheme: base.tabBarTheme.copyWith(
        labelColor: tokens.ink,
        unselectedLabelColor: tokens.muted,
        indicatorColor: tokens.accent,
        dividerColor: Colors.transparent,
      ),
      tooltipTheme: base.tooltipTheme.copyWith(
        decoration: BoxDecoration(
          color: tokens.ink.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(tokens.radiusSm),
        ),
      ),
      extensions: extensions,
    );
  }
}

class WindowsNeoPageTransitionsBuilder extends PageTransitionsBuilder {
  const WindowsNeoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      return child;
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.82, curve: Curves.easeOutCubic),
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.90, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.014),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

extension WindowsNeoThemeContext on BuildContext {
  WindowsNeoTokens get windowsNeo =>
      Theme.of(this).extension<WindowsNeoTokens>() ??
      WindowsNeoTokens.fromTheme(Theme.of(this));
}
