import 'package:PiliPlus/pages/windows_media_tabs/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('closing an inactive tab keeps the active page fully visible', (
    tester,
  ) async {
    final now = DateTime(2026);
    final home = WindowsVideoTabItem(
      id: WindowsVideoTabService.homeTabId,
      type: WindowsMediaTabType.home,
      arguments: const {'mediaTabType': 'home'},
      createdAt: now,
      updatedAt: now,
    );
    final search = WindowsVideoTabItem(
      id: 'search:miku',
      type: WindowsMediaTabType.search,
      arguments: const {'mediaTabType': 'search', 'keyword': 'miku'},
      createdAt: now,
      updatedAt: now,
    );

    Widget build(List<WindowsVideoTabItem> tabs, int activeIndex) {
      return MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: Scaffold(
          body: WindowsMediaTabStack(
            tabs: tabs,
            activeId: tabs[activeIndex].id,
            splitTabs: const [],
            maximizedSplitTab: null,
            splitHorizontalRatio: 0.5,
            splitVerticalRatio: 0.5,
            tabBuilder: (item) => Text(item.id),
          ),
        ),
      );
    }

    await tester.pumpWidget(build([home, search], 1));
    await tester.pumpAndSettle();

    await tester.pumpWidget(build([search], 0));
    await tester.pump();

    final activeStage = find.byKey(const ValueKey('search:miku'));
    final fade = tester.widget<FadeTransition>(
      find.descendant(of: activeStage, matching: find.byType(FadeTransition)),
    );
    expect(fade.opacity.value, 1);
    expect(find.text('search:miku'), findsOneWidget);
  });
}
