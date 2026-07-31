import 'dart:ui' show FontFeature, lerpDouble;

import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:flutter/material.dart';

/// Visual families available to the Windows-only desktop workspace.
enum WindowsNeoThemeFamily {
  miku,
  // Kept at index 1 so existing Field Terminal preferences become Endfield.
  endfield,
  ark,
  exAstris,
  popucom,
  corporate,
  ;

  static WindowsNeoThemeFamily fromStorageValue(int value) =>
      WindowsNeoThemeFamily.values.elementAtOrNull(value) ??
      WindowsNeoThemeFamily.miku;
}

enum WindowsNeoThemeDepth {
  minimal,
  moderate,
  complex,
  maximal,
  ;

  static WindowsNeoThemeDepth fromStorageValue(int value) =>
      WindowsNeoThemeDepth.values.elementAtOrNull(value) ??
      WindowsNeoThemeDepth.maximal;
}

extension WindowsNeoThemeDepthLabel on WindowsNeoThemeDepth {
  String get label => switch (this) {
        WindowsNeoThemeDepth.minimal => 'Minimal',
        WindowsNeoThemeDepth.moderate => 'Moderate',
        WindowsNeoThemeDepth.complex => 'Complex',
        WindowsNeoThemeDepth.maximal => 'Maximal',
      };
}

enum WindowsNeoBackdropPattern {
  rhythm,
  engineeringGrid,
  industrialBlueprint,
  orbitalArchive,
  playfulBlocks,
  studioGrid,
}

enum WindowsNeoSidebarArtwork {
  portrait,
  suppliedStage,
  instrumentPanel,
  archivePanel,
  playfulPanel,
  studioPanel,
}

/// Generated artwork is deliberately shared by the sidebar and the workspace
/// backdrop. The artwork stays an atmospheric layer; page and player content
/// retain visual priority.
extension WindowsNeoThemeFamilyArtwork on WindowsNeoThemeFamily {
  String? get backdropAsset => switch (this) {
        WindowsNeoThemeFamily.endfield =>
          'assets/images/windows_neo_endfield_sidebar.png',
        WindowsNeoThemeFamily.ark =>
          'assets/images/windows_neo_ark_sidebar.png',
        WindowsNeoThemeFamily.exAstris =>
          'assets/images/windows_neo_ex_astris_sidebar.png',
        WindowsNeoThemeFamily.popucom =>
          'assets/images/windows_neo_popucom_sidebar.png',
        // The provider rejected the Corporate render, so it keeps its deliberate
        // monochrome fallback instead of referencing a missing asset.
        WindowsNeoThemeFamily.corporate => null,
        WindowsNeoThemeFamily.miku => null,
      };
}

@immutable
class WindowsNeoThemeIdentity {
  const WindowsNeoThemeIdentity({
    required this.shellMark,
    required this.shellWordmark,
    required this.shellSubmark,
    required this.backdropPattern,
    required this.sidebarArtwork,
    required this.usesSquaredGeometry,
    required this.showRhythmTicks,
  });

  final String shellMark;
  final String shellWordmark;
  final String shellSubmark;
  final WindowsNeoBackdropPattern backdropPattern;
  final WindowsNeoSidebarArtwork sidebarArtwork;
  final bool usesSquaredGeometry;
  final bool showRhythmTicks;
}

typedef WindowsNeoThemeTokenBuilder = WindowsNeoTokens Function(
  ThemeData theme,
  WindowsNeoThemeDefinition definition,
  WindowsNeoThemeDepth depth,
);

@immutable
class WindowsNeoThemeDefinition {
  const WindowsNeoThemeDefinition({
    required this.family,
    required this.label,
    required this.description,
    required this.identity,
    required this.defaultDepth,
    required this.tokenBuilder,
  });

  final WindowsNeoThemeFamily family;
  final String label;
  final String description;
  final WindowsNeoThemeIdentity identity;
  final WindowsNeoThemeDepth defaultDepth;
  final WindowsNeoThemeTokenBuilder tokenBuilder;

  WindowsNeoTokens buildTokens(ThemeData theme, WindowsNeoThemeDepth depth) =>
      tokenBuilder(theme, this, depth);
}

/// The sole registration point for Windows Neo themes. A new theme must define
/// its palette builder and visual identity here before it can be selected.
abstract final class WindowsNeoThemeRegistry {
  static const miku = WindowsNeoThemeDefinition(
    family: WindowsNeoThemeFamily.miku,
    label: 'Miku Cyan',
    description: '青绿舞台',
    identity: WindowsNeoThemeIdentity(
      shellMark: '39',
      shellWordmark: 'MIKU',
      shellSubmark: '39',
      backdropPattern: WindowsNeoBackdropPattern.rhythm,
      sidebarArtwork: WindowsNeoSidebarArtwork.portrait,
      usesSquaredGeometry: false,
      showRhythmTicks: true,
    ),
    defaultDepth: WindowsNeoThemeDepth.maximal,
    tokenBuilder: _buildMikuTokens,
  );

  static const endfield = WindowsNeoThemeDefinition(
    family: WindowsNeoThemeFamily.endfield,
    label: 'Endfield',
    description: '现场终端',
    identity: WindowsNeoThemeIdentity(
      shellMark: '01',
      shellWordmark: 'FIELD',
      shellSubmark: 'OPS',
      backdropPattern: WindowsNeoBackdropPattern.engineeringGrid,
      sidebarArtwork: WindowsNeoSidebarArtwork.instrumentPanel,
      usesSquaredGeometry: true,
      showRhythmTicks: false,
    ),
    defaultDepth: WindowsNeoThemeDepth.maximal,
    tokenBuilder: _buildEndfieldTokens,
  );

  static const ark = WindowsNeoThemeDefinition(
    family: WindowsNeoThemeFamily.ark,
    label: 'Ark',
    description: '工业信息系统',
    identity: WindowsNeoThemeIdentity(
      shellMark: '02',
      shellWordmark: 'ARK',
      shellSubmark: 'SYSTEM',
      backdropPattern: WindowsNeoBackdropPattern.industrialBlueprint,
      sidebarArtwork: WindowsNeoSidebarArtwork.suppliedStage,
      usesSquaredGeometry: true,
      showRhythmTicks: false,
    ),
    defaultDepth: WindowsNeoThemeDepth.maximal,
    tokenBuilder: _buildArkTokens,
  );

  static const exAstris = WindowsNeoThemeDefinition(
    family: WindowsNeoThemeFamily.exAstris,
    label: 'Ex Astris',
    description: '宇宙档案',
    identity: WindowsNeoThemeIdentity(
      shellMark: '03',
      shellWordmark: 'ARCHIVE',
      shellSubmark: 'ORBIT',
      backdropPattern: WindowsNeoBackdropPattern.orbitalArchive,
      sidebarArtwork: WindowsNeoSidebarArtwork.archivePanel,
      usesSquaredGeometry: false,
      showRhythmTicks: false,
    ),
    defaultDepth: WindowsNeoThemeDepth.maximal,
    tokenBuilder: _buildExAstrisTokens,
  );

  static const popucom = WindowsNeoThemeDefinition(
    family: WindowsNeoThemeFamily.popucom,
    label: 'POPUCOM',
    description: '明快协作乐园',
    identity: WindowsNeoThemeIdentity(
      shellMark: '04',
      shellWordmark: 'PLAY',
      shellSubmark: 'CO-OP',
      backdropPattern: WindowsNeoBackdropPattern.playfulBlocks,
      sidebarArtwork: WindowsNeoSidebarArtwork.playfulPanel,
      usesSquaredGeometry: false,
      showRhythmTicks: false,
    ),
    defaultDepth: WindowsNeoThemeDepth.maximal,
    tokenBuilder: _buildPopucomTokens,
  );

  static const corporate = WindowsNeoThemeDefinition(
    family: WindowsNeoThemeFamily.corporate,
    label: 'Corporate',
    description: '酸性工作室',
    identity: WindowsNeoThemeIdentity(
      shellMark: '05',
      shellWordmark: 'STUDIO',
      shellSubmark: 'WORK',
      backdropPattern: WindowsNeoBackdropPattern.studioGrid,
      sidebarArtwork: WindowsNeoSidebarArtwork.studioPanel,
      usesSquaredGeometry: true,
      showRhythmTicks: false,
    ),
    defaultDepth: WindowsNeoThemeDepth.maximal,
    tokenBuilder: _buildCorporateTokens,
  );

  static const values = <WindowsNeoThemeDefinition>[
    miku,
    endfield,
    ark,
    exAstris,
    popucom,
    corporate,
  ];

  static WindowsNeoThemeDefinition resolve(WindowsNeoThemeFamily family) =>
      values.firstWhere(
        (definition) => definition.family == family,
        orElse: () => miku,
      );

  static WindowsNeoTokens _buildMikuTokens(
    ThemeData theme,
    WindowsNeoThemeDefinition definition,
    WindowsNeoThemeDepth depth,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    const accent = WindowsNeoTokens.mikuCyan;
    final surface = isDark ? const Color(0xFF202A2F) : const Color(0xFFFAFDFC);
    return WindowsNeoTokens(
      definition: definition,
      depth: depth,
      background: isDark ? const Color(0xFF11191D) : const Color(0xFFEEF6F5),
      sidebar: isDark ? const Color(0xFF172327) : const Color(0xFFD0E7E5),
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
      ink: isDark ? const Color(0xFFE8EEEC) : WindowsNeoTokens.inkDefault,
      secondaryAccent: WindowsNeoTokens.iceCyan,
      tertiaryAccent: WindowsNeoTokens.sakuraPink,
      bannerAccentEnd: const Color(0xFF75D8D2),
    );
  }

  static WindowsNeoTokens _buildEndfieldTokens(
    ThemeData theme,
    WindowsNeoThemeDefinition definition,
    WindowsNeoThemeDepth depth,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFFFFFA00);
    final surface = isDark ? const Color(0xFF20201E) : const Color(0xFFF7F7F3);
    return WindowsNeoTokens(
      definition: definition,
      depth: depth,
      background: isDark ? const Color(0xFF141414) : const Color(0xFFE9E9E2),
      sidebar: isDark ? const Color(0xFF1D1D1C) : const Color(0xFFDDDCD5),
      surface: surface,
      surfaceRaised: isDark ? const Color(0xFF292927) : const Color(0xFFFFFFFF),
      border: isDark ? const Color(0xFF565650) : const Color(0xFF96968D),
      muted: isDark ? const Color(0xFFBDBDB5) : const Color(0xFF595952),
      hover: isDark ? const Color(0xFF2C2C29) : const Color(0xFFE0E0D9),
      accent: accent,
      accentSurface: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.18 : 0.34),
        surface,
      ),
      accentSoft: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.10 : 0.18),
        surface,
      ),
      ink: isDark ? const Color(0xFFF4F4EE) : const Color(0xFF191919),
      secondaryAccent:
          isDark ? const Color(0xFFF4F4EE) : const Color(0xFF191919),
      tertiaryAccent:
          isDark ? const Color(0xFF565650) : const Color(0xFF96968D),
      bannerAccentEnd: const Color(0xFFD5D500),
      radiusSm: 0,
      radiusMd: 0,
      radiusLg: 0,
      motionFast: const Duration(milliseconds: 150),
      motionStandard: const Duration(milliseconds: 220),
      motionPage: const Duration(milliseconds: 270),
    );
  }

  static WindowsNeoTokens _buildArkTokens(
    ThemeData theme,
    WindowsNeoThemeDefinition definition,
    WindowsNeoThemeDepth depth,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFF18D1FF);
    final surface = isDark ? const Color(0xFF111617) : const Color(0xFFF4F6F6);
    return WindowsNeoTokens(
      definition: definition,
      depth: depth,
      background: isDark ? const Color(0xFF080A0B) : const Color(0xFFE6EBEC),
      sidebar: isDark ? const Color(0xFF101719) : const Color(0xFFDDE6E7),
      surface: surface,
      surfaceRaised: isDark ? const Color(0xFF182124) : Colors.white,
      border: isDark ? const Color(0xFF476166) : const Color(0xFF9BAAAB),
      muted: isDark ? const Color(0xFFAFC0C3) : const Color(0xFF506165),
      hover: isDark ? const Color(0xFF1D3035) : const Color(0xFFD7E9EC),
      accent: accent,
      accentSurface: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.20 : 0.12),
        surface,
      ),
      accentSoft: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.10 : 0.07),
        surface,
      ),
      ink: isDark ? const Color(0xFFF4F6F6) : const Color(0xFF080A0B),
      secondaryAccent: const Color(0xFFC8EB21),
      tertiaryAccent:
          isDark ? const Color(0xFF476166) : const Color(0xFFB8CBCD),
      bannerAccentEnd: const Color(0xFF8AE7FF),
      radiusSm: 0,
      radiusMd: 0,
      radiusLg: 0,
      motionFast: const Duration(milliseconds: 150),
      motionStandard: const Duration(milliseconds: 220),
      motionPage: const Duration(milliseconds: 280),
    );
  }

  static WindowsNeoTokens _buildExAstrisTokens(
    ThemeData theme,
    WindowsNeoThemeDefinition definition,
    WindowsNeoThemeDepth depth,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFF46F6E6);
    final surface = isDark ? const Color(0xFF101225) : const Color(0xFFF3F2EF);
    return WindowsNeoTokens(
      definition: definition,
      depth: depth,
      background: isDark ? const Color(0xFF080914) : const Color(0xFFE8E8E8),
      sidebar: isDark ? const Color(0xFF11142A) : const Color(0xFFDDDDE4),
      surface: surface,
      surfaceRaised: isDark ? const Color(0xFF171A34) : Colors.white,
      border: isDark ? const Color(0xFF51557A) : const Color(0xFFAAAABD),
      muted: isDark ? const Color(0xFFB8BAD2) : const Color(0xFF595B72),
      hover: isDark ? const Color(0xFF20254A) : const Color(0xFFDDECEF),
      accent: accent,
      accentSurface: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.16 : 0.10),
        surface,
      ),
      accentSoft: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.08 : 0.06),
        surface,
      ),
      ink: isDark ? const Color(0xFFF4F4FA) : const Color(0xFF080914),
      secondaryAccent: const Color(0xFF925DFF),
      tertiaryAccent:
          isDark ? const Color(0xFF51557A) : const Color(0xFFD7D6EA),
      bannerAccentEnd: const Color(0xFF7D6BFF),
      radiusSm: 0,
      radiusMd: 0,
      radiusLg: 0,
      motionFast: const Duration(milliseconds: 180),
      motionStandard: const Duration(milliseconds: 260),
      motionPage: const Duration(milliseconds: 360),
    );
  }

  static WindowsNeoTokens _buildPopucomTokens(
    ThemeData theme,
    WindowsNeoThemeDefinition definition,
    WindowsNeoThemeDepth depth,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFFFFCC1A);
    final surface = isDark ? const Color(0xFF242424) : const Color(0xFFFFFDF4);
    return WindowsNeoTokens(
      definition: definition,
      depth: depth,
      background: isDark ? const Color(0xFF141414) : const Color(0xFFF1F4F7),
      sidebar: isDark ? const Color(0xFF252B35) : const Color(0xFFDCEBFA),
      surface: surface,
      surfaceRaised: isDark ? const Color(0xFF303030) : Colors.white,
      border: isDark ? const Color(0xFF6B6B6B) : const Color(0xFFB7C5D1),
      muted: isDark ? const Color(0xFFD1D1CC) : const Color(0xFF59636D),
      hover: isDark ? const Color(0xFF3A414D) : const Color(0xFFFFEDB0),
      accent: accent,
      accentSurface: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.18 : 0.32),
        surface,
      ),
      accentSoft: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.10 : 0.16),
        surface,
      ),
      ink: isDark ? const Color(0xFFFFFDF4) : const Color(0xFF141414),
      secondaryAccent: const Color(0xFF3994FF),
      tertiaryAccent: const Color(0xFFFF7A1A),
      bannerAccentEnd: const Color(0xFF3994FF),
      radiusSm: 0,
      radiusMd: 0,
      radiusLg: 0,
      motionFast: const Duration(milliseconds: 170),
      motionStandard: const Duration(milliseconds: 240),
      motionPage: const Duration(milliseconds: 320),
    );
  }

  static WindowsNeoTokens _buildCorporateTokens(
    ThemeData theme,
    WindowsNeoThemeDefinition definition,
    WindowsNeoThemeDepth depth,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFFF3FF00);
    final surface = isDark ? const Color(0xFF111111) : const Color(0xFFF3F3F3);
    return WindowsNeoTokens(
      definition: definition,
      depth: depth,
      background: isDark ? const Color(0xFF050505) : const Color(0xFFE8E8E8),
      sidebar: isDark ? const Color(0xFF101010) : const Color(0xFFDCDCDC),
      surface: surface,
      surfaceRaised: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      border: isDark ? const Color(0xFF5C5C5C) : const Color(0xFF9C9C9C),
      muted: isDark ? const Color(0xFFC6C6C6) : const Color(0xFF4F4F4F),
      hover: isDark ? const Color(0xFF242424) : const Color(0xFFE8F092),
      accent: accent,
      accentSurface: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.15 : 0.28),
        surface,
      ),
      accentSoft: Color.alphaBlend(
        accent.withValues(alpha: isDark ? 0.08 : 0.14),
        surface,
      ),
      ink: isDark ? Colors.white : const Color(0xFF050505),
      secondaryAccent: Colors.white,
      tertiaryAccent:
          isDark ? const Color(0xFF5C5C5C) : const Color(0xFFBDBDBD),
      bannerAccentEnd: const Color(0xFFD4DD00),
      radiusSm: 0,
      radiusMd: 0,
      radiusLg: 0,
      motionFast: const Duration(milliseconds: 140),
      motionStandard: const Duration(milliseconds: 200),
      motionPage: const Duration(milliseconds: 260),
    );
  }
}

/// Keeps the Windows theme live while leaving the global light/dark preference
/// and non-Windows platforms untouched.
abstract final class WindowsNeoThemeController {
  static final ValueNotifier<WindowsNeoThemeFamily> family = ValueNotifier(
    WindowsNeoThemeFamily.fromStorageValue(Pref.windowsNeoThemeFamily),
  );
  static final ValueNotifier<WindowsNeoThemeDepth> depth = ValueNotifier(
    WindowsNeoThemeDepth.fromStorageValue(Pref.windowsNeoThemeDepth),
  );

  static Future<void> select(WindowsNeoThemeFamily value) async {
    family.value = value;
    await GStorage.setting.put(
      SettingBoxKey.windowsNeoThemeFamily,
      value.index,
    );
  }

  static Future<void> selectDepth(WindowsNeoThemeDepth value) async {
    depth.value = value;
    await GStorage.setting.put(SettingBoxKey.windowsNeoThemeDepth, value.index);
  }
}

/// Miku-cyan dashboard language for Windows Neo.
/// Airy surfaces, low-noise borders, and a bright cyan focal color.
@immutable
class WindowsNeoTokens extends ThemeExtension<WindowsNeoTokens> {
  const WindowsNeoTokens({
    required this.definition,
    required this.depth,
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
    required this.secondaryAccent,
    required this.tertiaryAccent,
    required this.bannerAccentEnd,
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
    this.sectionTabHeight = 40,
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

  factory WindowsNeoTokens.fromTheme(
    ThemeData theme, {
    WindowsNeoThemeFamily family = WindowsNeoThemeFamily.miku,
    WindowsNeoThemeDepth depth = WindowsNeoThemeDepth.maximal,
  }) =>
      WindowsNeoThemeRegistry.resolve(family).buildTokens(theme, depth);

  final WindowsNeoThemeDefinition definition;
  final WindowsNeoThemeDepth depth;
  WindowsNeoThemeFamily get family => definition.family;
  WindowsNeoThemeIdentity get identity => definition.identity;
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
  final Color secondaryAccent;
  final Color tertiaryAccent;
  final Color bannerAccentEnd;

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

  /// The five Ark UI-derived families use ruled, rectangular instrumentation.
  /// Miku deliberately remains the sole soft-surface exception.
  BorderRadius get workspaceTabRadius => switch (family) {
        WindowsNeoThemeFamily.miku => BorderRadius.circular(6),
        _ => BorderRadius.zero,
      };

  BorderRadius get sidebarArtworkRadius => switch (family) {
        WindowsNeoThemeFamily.miku => BorderRadius.circular(8),
        _ => BorderRadius.zero,
      };

  BorderRadius get navigationItemRadius => switch (family) {
        WindowsNeoThemeFamily.miku => BorderRadius.circular(6),
        _ => BorderRadius.zero,
      };

  BorderRadius get mediaBadgeRadius => switch (family) {
        WindowsNeoThemeFamily.miku => BorderRadius.circular(4),
        _ => BorderRadius.zero,
      };

  BorderRadius get actionRadius => switch (family) {
        WindowsNeoThemeFamily.miku => BorderRadius.circular(6),
        _ => BorderRadius.zero,
      };

  bool get isMaximal => depth == WindowsNeoThemeDepth.maximal;
  String get shellMark => identity.shellMark;
  String get shellWordmark => identity.shellWordmark;
  String get shellSubmark => identity.shellSubmark;

  /// The optional Ark green is reserved for verified/success states. It must
  /// not become a second structural signal across cards and backgrounds.
  Color get stageMotifColor => switch (family) {
        WindowsNeoThemeFamily.ark => accent,
        WindowsNeoThemeFamily.exAstris => accent,
        _ => secondaryAccent,
      };

  Color get structuralSecondaryAccent => switch (family) {
        WindowsNeoThemeFamily.ark => accent,
        WindowsNeoThemeFamily.exAstris => accent,
        _ => secondaryAccent,
      };

  List<String> get displayFontFallback => switch (family) {
        WindowsNeoThemeFamily.ark => const [
            'Arial Narrow',
            'Roboto Condensed',
            'DIN Condensed',
          ],
        WindowsNeoThemeFamily.endfield => const [
            'Space Grotesk',
            'IBM Plex Sans'
          ],
        WindowsNeoThemeFamily.exAstris => const [
            'Noto Serif SC',
            'Source Han Serif SC',
            'serif',
          ],
        WindowsNeoThemeFamily.popucom => const ['Noto Sans SC', 'PingFang SC'],
        WindowsNeoThemeFamily.corporate => const [
            'Space Grotesk',
            'IBM Plex Sans'
          ],
        WindowsNeoThemeFamily.miku => const ['Noto Sans SC', 'PingFang SC'],
      };

  List<String> get uiFontFallback => switch (family) {
        WindowsNeoThemeFamily.exAstris => const [
            'Noto Sans SC',
            'Source Han Sans SC',
            'sans-serif',
          ],
        _ => const ['Noto Sans SC', 'Source Han Sans SC', 'PingFang SC'],
      };

  Color get chromeSurface => switch (family) {
        WindowsNeoThemeFamily.ark => const Color(0xFF080A0B),
        WindowsNeoThemeFamily.exAstris => const Color(0xFF080914),
        WindowsNeoThemeFamily.popucom => const Color(0xFF252B35),
        WindowsNeoThemeFamily.corporate => const Color(0xFF050505),
        _ => sidebar,
      };

  bool get usesDarkChrome => chromeSurface.computeLuminance() < 0.12;

  Color get chromeForeground => usesDarkChrome ? Colors.white : ink;

  Color get chromeMuted =>
      usesDarkChrome ? Colors.white.withValues(alpha: 0.68) : muted;

  Color get navigationSurface => switch (family) {
        WindowsNeoThemeFamily.ark ||
        WindowsNeoThemeFamily.exAstris ||
        WindowsNeoThemeFamily.corporate =>
          chromeSurface,
        _ => sidebar,
      };

  Color get navigationForeground =>
      navigationSurface.computeLuminance() < 0.12 ? Colors.white : ink;

  Color get navigationMuted => navigationSurface.computeLuminance() < 0.12
      ? Colors.white.withValues(alpha: 0.66)
      : muted;

  List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: ink.withValues(
            alpha: identity.usesSquaredGeometry ? 0.055 : 0.065,
          ),
          blurRadius: identity.usesSquaredGeometry ? 12 : 18,
          offset: Offset(0, identity.usesSquaredGeometry ? 4 : 6),
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
          accent,
          bannerAccentEnd,
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
          structuralSecondaryAccent.withValues(
            alpha: identity.usesSquaredGeometry ? 0.30 : 0.48,
          ),
          tertiaryAccent.withValues(
            alpha: identity.usesSquaredGeometry ? 0.56 : 0.22,
          ),
        ],
        stops: const [0, 0.62, 1],
      );

  Color get rhythmTrackColor => border.withValues(alpha: 0.52);

  LinearGradient get rhythmGradient => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          accent,
          structuralSecondaryAccent,
          tertiaryAccent.withValues(alpha: 0.42),
        ],
        stops: const [0, 0.78, 1],
      );

  LinearGradient get sidebarSelectionGradient {
    final colors = switch (family) {
      WindowsNeoThemeFamily.miku => [
          Color.alphaBlend(accent.withValues(alpha: 0.88), navigationSurface),
          Color.alphaBlend(accent.withValues(alpha: 0.56), navigationSurface),
          Color.alphaBlend(
            Colors.white.withValues(alpha: 0.42),
            Color.alphaBlend(accent.withValues(alpha: 0.20), navigationSurface),
          ),
        ],
      WindowsNeoThemeFamily.endfield => [
          Color.alphaBlend(accent.withValues(alpha: 0.34), navigationSurface),
          Color.alphaBlend(accent.withValues(alpha: 0.16), navigationSurface),
          navigationSurface,
        ],
      WindowsNeoThemeFamily.ark => [
          Color.alphaBlend(accent.withValues(alpha: 0.30), navigationSurface),
          Color.alphaBlend(accent.withValues(alpha: 0.10), navigationSurface),
          navigationSurface,
        ],
      WindowsNeoThemeFamily.exAstris => [
          Color.alphaBlend(accent.withValues(alpha: 0.22), navigationSurface),
          Color.alphaBlend(
            secondaryAccent.withValues(alpha: 0.10),
            navigationSurface,
          ),
          navigationSurface,
        ],
      WindowsNeoThemeFamily.popucom => [
          Color.alphaBlend(accent.withValues(alpha: 0.78), navigationSurface),
          Color.alphaBlend(
            secondaryAccent.withValues(alpha: 0.54),
            navigationSurface,
          ),
          navigationSurface,
        ],
      WindowsNeoThemeFamily.corporate => [
          Color.alphaBlend(accent.withValues(alpha: 0.16), navigationSurface),
          Color.alphaBlend(accent.withValues(alpha: 0.05), navigationSurface),
          navigationSurface,
        ],
    };
    return LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: colors,
      stops: const [0, 0.58, 1],
    );
  }

  TextStyle pageTitleStyle(TextTheme textTheme) {
    final base =
        (textTheme.titleMedium ?? const TextStyle(fontSize: 18)).copyWith(
      color: ink,
      fontWeight: FontWeight.w700,
      height: 1.15,
      letterSpacing: 0,
      fontFamilyFallback: displayFontFallback,
    );
    return switch (family) {
      WindowsNeoThemeFamily.endfield => base.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .25,
        ),
      WindowsNeoThemeFamily.ark => base.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .35,
        ),
      WindowsNeoThemeFamily.exAstris => base.copyWith(
          fontWeight: FontWeight.w500,
          fontSize: 19,
        ),
      WindowsNeoThemeFamily.popucom => base.copyWith(
          fontWeight: FontWeight.w900,
          letterSpacing: .15,
        ),
      WindowsNeoThemeFamily.corporate => base.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: .55,
        ),
      WindowsNeoThemeFamily.miku => base,
    };
  }

  TextStyle pageSubtitleStyle(TextTheme textTheme) =>
      (textTheme.bodySmall ?? const TextStyle(fontSize: 12)).copyWith(
        color: muted,
        height: 1.2,
        fontFamilyFallback: uiFontFallback,
      );

  TextStyle cardTitleStyle(TextTheme textTheme) {
    final base =
        (textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
      color: ink,
      fontWeight: FontWeight.w600,
      height: 1.35,
      fontSize: 13.5,
      fontFamilyFallback: uiFontFallback,
    );
    return switch (family) {
      WindowsNeoThemeFamily.endfield => base.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: .12,
        ),
      WindowsNeoThemeFamily.ark => base.copyWith(fontWeight: FontWeight.w700),
      WindowsNeoThemeFamily.exAstris => base.copyWith(
          fontWeight: FontWeight.w500,
          fontFamilyFallback: displayFontFallback,
        ),
      WindowsNeoThemeFamily.popucom => base.copyWith(
          fontWeight: FontWeight.w800,
        ),
      WindowsNeoThemeFamily.corporate => base.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: .18,
        ),
      WindowsNeoThemeFamily.miku => base,
    };
  }

  TextStyle cardMetaStyle(TextTheme textTheme) =>
      (textTheme.labelMedium ?? const TextStyle(fontSize: 12)).copyWith(
        color: muted,
        height: 1.2,
        fontFamilyFallback: uiFontFallback,
      );

  TextStyle cardCaptionStyle(TextTheme textTheme) =>
      (textTheme.labelSmall ?? const TextStyle(fontSize: 11)).copyWith(
        color: muted,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
        fontFamilyFallback: uiFontFallback,
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
    Color? secondaryAccent,
    Color? tertiaryAccent,
    Color? bannerAccentEnd,
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
  }) =>
      WindowsNeoTokens(
        definition: definition,
        depth: depth,
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
        secondaryAccent: secondaryAccent ?? this.secondaryAccent,
        tertiaryAccent: tertiaryAccent ?? this.tertiaryAccent,
        bannerAccentEnd: bannerAccentEnd ?? this.bannerAccentEnd,
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
      definition: t < 0.5 ? definition : other.definition,
      depth: t < 0.5 ? depth : other.depth,
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
      secondaryAccent: Color.lerp(secondaryAccent, other.secondaryAccent, t)!,
      tertiaryAccent: Color.lerp(tertiaryAccent, other.tertiaryAccent, t)!,
      bannerAccentEnd: Color.lerp(bannerAccentEnd, other.bannerAccentEnd, t)!,
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
  static ThemeData apply(
    ThemeData base, {
    WindowsNeoThemeFamily family = WindowsNeoThemeFamily.miku,
    WindowsNeoThemeDepth depth = WindowsNeoThemeDepth.maximal,
  }) {
    final tokens = WindowsNeoTokens.fromTheme(
      base,
      family: family,
      depth: depth,
    );
    final extensions = base.extensions.values
        .where((item) => item is! WindowsNeoTokens)
        .toList()
      ..add(tokens);
    final outline = OutlineInputBorder(
      borderRadius: BorderRadius.circular(tokens.radiusMd),
      borderSide: BorderSide(color: tokens.border),
    );
    final actionShape = RoundedRectangleBorder(
      borderRadius: tokens.actionRadius,
    );
    final accentForeground =
        tokens.accent.computeLuminance() > 0.50 ? Colors.black : Colors.white;
    final actionSide = WidgetStateProperty.resolveWith<BorderSide>((states) {
      if (states.contains(WidgetState.focused)) {
        return BorderSide(color: tokens.accent, width: 2);
      }
      if (states.contains(WidgetState.hovered)) {
        return BorderSide(color: tokens.accent.withValues(alpha: 0.78));
      }
      return BorderSide(color: tokens.border);
    });

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
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.ink),
          side: actionSide,
          shape: WidgetStatePropertyAll(actionShape),
          overlayColor: WidgetStatePropertyAll(
            tokens.accent.withValues(alpha: 0.10),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(accentForeground),
          backgroundColor: WidgetStatePropertyAll(tokens.accent),
          shape: WidgetStatePropertyAll(actionShape),
          overlayColor: WidgetStatePropertyAll(
            tokens.ink.withValues(alpha: 0.10),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(tokens.ink),
          shape: WidgetStatePropertyAll(actionShape),
          overlayColor: WidgetStatePropertyAll(
            tokens.accent.withValues(alpha: 0.10),
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(actionShape),
          overlayColor: WidgetStatePropertyAll(
            tokens.accent.withValues(alpha: 0.10),
          ),
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
        shadowColor: tokens.ink.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: tokens.cardRadius,
          side: BorderSide(color: tokens.border),
        ),
      ),
      dialogTheme: base.dialogTheme.copyWith(
        backgroundColor: tokens.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 16,
        shadowColor: tokens.ink.withValues(alpha: 0.16),
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
        shadowColor: tokens.ink.withValues(alpha: 0.16),
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
    final entryOffset = switch (context.windowsNeo.family) {
      WindowsNeoThemeFamily.endfield => const Offset(-0.018, 0),
      WindowsNeoThemeFamily.ark => const Offset(-0.020, 0),
      WindowsNeoThemeFamily.exAstris => const Offset(0, 0.014),
      WindowsNeoThemeFamily.popucom => const Offset(0, 0.020),
      WindowsNeoThemeFamily.corporate => const Offset(0.016, 0),
      WindowsNeoThemeFamily.miku => const Offset(0, 0.014),
    };
    return FadeTransition(
      opacity: Tween<double>(begin: 0.90, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: entryOffset,
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
