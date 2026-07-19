import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/shell/windows_neo_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('home and closable workspace tabs keep the same height', (
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
    final download = WindowsVideoTabItem(
      id: 'tool:/download',
      type: WindowsMediaTabType.tool,
      arguments: const {
        'mediaTabType': 'tool',
        'tabRoute': '/download',
        'title': 'Download',
      },
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: Scaffold(
          body: Row(
            children: [
              WindowsNeoWorkspaceTab(
                key: const Key('home-tab'),
                item: home,
                active: false,
                onClose: () async {},
              ),
              WindowsNeoWorkspaceTab(
                key: const Key('download-tab'),
                item: download,
                active: true,
                onClose: () async {},
              ),
            ],
          ),
        ),
      ),
    );

    final homeSize = tester.getSize(find.byKey(const Key('home-tab')));
    final downloadSize = tester.getSize(find.byKey(const Key('download-tab')));

    expect(homeSize.height, WindowsNeoWorkspaceTab.height);
    expect(downloadSize.height, WindowsNeoWorkspaceTab.height);
    expect(homeSize.height, downloadSize.height);

    final activeContainers = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byKey(const Key('download-tab')),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .where(
          (container) =>
              container.decoration is BoxDecoration &&
              (container.decoration! as BoxDecoration).gradient != null,
        );
    expect(activeContainers, hasLength(1));
  });
}
