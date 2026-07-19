import 'package:PiliPlus/pages/search_result/view.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
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
    expect(tokens.gridGap, 16);
    expect(tokens.motionFast, const Duration(milliseconds: 140));
    expect(tokens.motionStandard, const Duration(milliseconds: 200));
    expect(tokens.motionPage, const Duration(milliseconds: 240));
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
    expect(tokens!.background.computeLuminance(), lessThan(0.02));
    expect(WindowsNeoShell, isA<Type>());
    expect(WindowsNeoPage, isA<Type>());
    expect(WindowsNeoVideoSearchTile, isA<Type>());
    expect(SearchResultPage, isA<Type>());
  });
}
