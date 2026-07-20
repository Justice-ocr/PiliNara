import 'package:PiliPlus/pages/search_result/view.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_video_search_tile.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/shell/windows_neo_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('shared rhythm markers render without layout exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: const Scaffold(
          body: Column(
            children: [
              WindowsNeoRhythmRail(),
              WindowsNeoHeaderBeat(),
              WindowsNeoHeaderWave(),
              WindowsNeoActiveBeat(active: true),
              SizedBox(
                width: 280,
                child: DefaultTabController(
                  length: 2,
                  child: TabBar(
                    indicator: WindowsNeoTabIndicator(),
                    tabs: [Tab(text: '推荐'), Tab(text: '热门')],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('windows-neo-header-beat')), findsOneWidget);
    expect(find.byType(WindowsNeoRhythmRail), findsOneWidget);
    expect(find.byKey(const Key('windows-neo-header-wave')), findsOneWidget);
    expect(find.byType(WindowsNeoActiveBeat), findsOneWidget);
    expect(find.byType(TabBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
