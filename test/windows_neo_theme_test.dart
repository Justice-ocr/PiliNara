import 'package:PiliPlus/pages/search_result/view.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_section_tabs.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_state.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_stage.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_video_search_tile.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/shell/windows_neo_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('theme registry defines every selectable Windows theme', () {
    final families = WindowsNeoThemeRegistry.values
        .map((definition) => definition.family)
        .toList();

    expect(families, orderedEquals(WindowsNeoThemeFamily.values));
    for (final definition in WindowsNeoThemeRegistry.values) {
      final tokens = definition.buildTokens(
        ThemeData.light(),
        definition.defaultDepth,
      );
      expect(tokens.definition, same(definition));
      expect(definition.label, isNotEmpty);
      expect(definition.description, isNotEmpty);
      if (definition.family != WindowsNeoThemeFamily.miku) {
        expect(definition.defaultDepth, WindowsNeoThemeDepth.maximal);
      }
    }
  });

  test('theme family and depth remain independent axes', () {
    final theme = ThemeData.light();
    final maximalArk = WindowsNeoTokens.fromTheme(
      theme,
      family: WindowsNeoThemeFamily.ark,
      depth: WindowsNeoThemeDepth.maximal,
    );
    final compactArk = WindowsNeoTokens.fromTheme(
      theme,
      family: WindowsNeoThemeFamily.ark,
      depth: WindowsNeoThemeDepth.moderate,
    );

    expect(maximalArk.family, WindowsNeoThemeFamily.ark);
    expect(maximalArk.depth, WindowsNeoThemeDepth.maximal);
    expect(compactArk.family, WindowsNeoThemeFamily.ark);
    expect(compactArk.depth, WindowsNeoThemeDepth.moderate);
    expect(maximalArk.accent, const Color(0xFF18D1FF));
    expect(compactArk.accent, maximalArk.accent);
  });

  test('WindowsNeoTheme installs light workspace tokens', () {
    final theme = WindowsNeoTheme.apply(
      ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
    );
    final tokens = theme.extension<WindowsNeoTokens>();

    expect(tokens, isNotNull);
    expect(tokens!.background, isNot(tokens.surface));
    expect(tokens.sidebar, const Color(0xFFD0E7E5));
    expect(tokens.accent, const Color(0xFF39C5BB));
    expect(WindowsNeoTokens.iceCyan, const Color(0xFF70D8E6));
    expect(WindowsNeoTokens.sakuraPink, const Color(0xFFFFA2BD));
    expect(tokens.workspaceTabGradient.colors, hasLength(2));
    expect(tokens.cardAccentGradient.colors, hasLength(3));
    final selectionColors = tokens.sidebarSelectionGradient.colors;
    expect(selectionColors, hasLength(3));
    expect(
      selectionColors.last.computeLuminance(),
      greaterThan(selectionColors.first.computeLuminance()),
    );
    expect(
      tokens.sidebar.computeLuminance(),
      lessThan(tokens.background.computeLuminance()),
    );
    expect(
      tokens.background.computeLuminance(),
      lessThan(tokens.surface.computeLuminance()),
    );
    expect(tokens.pagePadding, 24);
    expect(tokens.sectionTabHeight, 40);
    expect(tokens.gridGap, 16);
    expect(tokens.radiusMd, 10);
    expect(tokens.motionFast, const Duration(milliseconds: 140));
    expect(tokens.motionStandard, const Duration(milliseconds: 200));
    expect(tokens.motionPage, const Duration(milliseconds: 240));
    expect(tokens.motionLoading, const Duration(milliseconds: 1100));
    expect(
      theme.pageTransitionsTheme.builders[TargetPlatform.windows],
      isA<WindowsNeoPageTransitionsBuilder>(),
    );
    expect(theme.dialogTheme.backgroundColor, tokens.surface);
    expect(theme.dialogTheme.surfaceTintColor, Colors.transparent);
    expect(theme.bottomSheetTheme.modalBackgroundColor, tokens.surface);
    expect(theme.bottomSheetTheme.surfaceTintColor, Colors.transparent);
    expect(theme.visualDensity, VisualDensity.compact);
  });

  test('WindowsNeoTheme installs dark workspace tokens', () {
    final theme = WindowsNeoTheme.apply(
      ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),
    );
    final tokens = theme.extension<WindowsNeoTokens>();

    expect(tokens, isNotNull);
    expect(tokens!.background, const Color(0xFF11191D));
    expect(tokens.surface, const Color(0xFF202A2F));
    expect(tokens.sidebar, const Color(0xFF172327));
    expect(tokens.background.computeLuminance(), lessThan(0.02));
    expect(WindowsNeoShell, isA<Type>());
    expect(WindowsNeoPage, isA<Type>());
    expect(WindowsNeoVideoSearchTile, isA<Type>());
    expect(SearchResultPage, isA<Type>());
  });

  test('Endfield theme uses rectangular yellow engineering tokens', () {
    final theme = WindowsNeoTheme.apply(
      ThemeData.light(),
      family: WindowsNeoThemeFamily.endfield,
    );
    final tokens = theme.extension<WindowsNeoTokens>();
    final darkTokens = WindowsNeoTokens.fromTheme(
      ThemeData.dark(),
      family: WindowsNeoThemeFamily.endfield,
    );

    expect(tokens, isNotNull);
    expect(tokens!.family, WindowsNeoThemeFamily.endfield);
    expect(tokens.accent, const Color(0xFFFFFA00));
    expect(tokens.ink, const Color(0xFF191919));
    expect(tokens.background, const Color(0xFFE9E9E2));
    expect(tokens.radiusSm, 0);
    expect(tokens.radiusMd, 0);
    expect(tokens.radiusLg, 0);
    expect(
      tokens.identity.backdropPattern,
      WindowsNeoBackdropPattern.engineeringGrid,
    );
    expect(tokens.identity.usesSquaredGeometry, isTrue);
    expect(darkTokens.background, const Color(0xFF141414));
    expect(darkTokens.ink, const Color(0xFFF4F4EE));
  });

  test('theme families keep their intended geometry contracts', () {
    final theme = ThemeData.light();
    final ark = WindowsNeoTokens.fromTheme(
      theme,
      family: WindowsNeoThemeFamily.ark,
    );
    final exAstris = WindowsNeoTokens.fromTheme(
      theme,
      family: WindowsNeoThemeFamily.exAstris,
    );
    final popucom = WindowsNeoTokens.fromTheme(
      theme,
      family: WindowsNeoThemeFamily.popucom,
    );
    final corporate = WindowsNeoTokens.fromTheme(
      theme,
      family: WindowsNeoThemeFamily.corporate,
    );

    expect(ark.cardRadius, BorderRadius.zero);
    expect(ark.panelRadius, BorderRadius.zero);
    expect(ark.workspaceTabRadius, BorderRadius.zero);
    expect(ark.chromeSurface, const Color(0xFF080A0B));
    expect(ark.navigationSurface, ark.chromeSurface);
    expect(ark.stageMotifColor, ark.accent);
    expect(ark.structuralSecondaryAccent, ark.accent);
    expect(exAstris.cardRadius, BorderRadius.zero);
    expect(exAstris.panelRadius, BorderRadius.zero);
    expect(exAstris.mediaBadgeRadius.topLeft.x, 999);
    expect(corporate.cardRadius, BorderRadius.zero);
    expect(corporate.panelRadius, BorderRadius.zero);
    expect(corporate.chromeSurface, const Color(0xFF050505));
    expect(popucom.cardRadius.topLeft.x, 12);
    expect(popucom.workspaceTabRadius.topLeft.x, 10);
    expect(popucom.chromeSurface, const Color(0xFF252B35));
    expect(ark.displayFontFallback, contains('Arial Narrow'));
    expect(exAstris.displayFontFallback, contains('Noto Serif SC'));
  });

  testWidgets('stage modes render across every theme family', (tester) async {
    for (final family in WindowsNeoThemeFamily.values) {
      await tester.pumpWidget(
        MaterialApp(
          theme: WindowsNeoTheme.apply(ThemeData.light(), family: family),
          home: Scaffold(
            body: SizedBox(
              width: 1200,
              height: 720,
              child: Column(
                children: [
                  Expanded(
                    child: WindowsNeoStageFrame(
                      mode: WindowsNeoStageMode.browse,
                      stateLabel: 'HOME',
                      stateIndex: 1,
                      child: const SizedBox.expand(),
                    ),
                  ),
                  const SizedBox(
                    height: 220,
                    child: WindowsNeoMediaStage(
                      mode: WindowsNeoStageMode.video,
                      stateLabel: 'DETAILS',
                      child: ColoredBox(color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: family.name);
    }
  });

  testWidgets('shared rhythm markers render without layout exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: Scaffold(
          body: Column(
            children: [
              const WindowsNeoRhythmRail(),
              const WindowsNeoHeaderBeat(),
              const WindowsNeoHeaderWave(),
              const WindowsNeoActiveBeat(active: true),
              const WindowsNeoSectionHeader(child: Text('Search history')),
              SizedBox(
                width: 280,
                child: DefaultTabController(
                  length: 2,
                  child: Builder(
                    builder: (context) => WindowsNeoSectionTabs(
                      controller: DefaultTabController.of(context),
                      tabs: const [
                        Tab(text: '推荐'),
                        Tab(text: '热门'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('windows-neo-header-beat')), findsOneWidget);
    expect(find.byType(WindowsNeoRhythmRail), findsNWidgets(3));
    expect(find.byKey(const Key('windows-neo-header-wave')), findsOneWidget);
    expect(find.byType(WindowsNeoActiveBeat), findsOneWidget);
    expect(find.byType(WindowsNeoSectionHeader), findsOneWidget);
    expect(find.byType(WindowsNeoSectionTabs), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('field terminal replaces the Miku empty-state mark', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(
          ThemeData.light(),
          family: WindowsNeoThemeFamily.endfield,
        ),
        home: const Scaffold(
          body: CustomScrollView(
            slivers: [
              WindowsNeoSliverState(
                icon: Icons.inbox_outlined,
                title: 'No items',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('01'), findsOneWidget);
    expect(find.text('39'), findsNothing);
  });
}
