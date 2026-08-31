import 'package:PiliPlus/router/app_pages.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_workspace/routing/windows_workspace_route_registry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WindowsWorkspaceTab tab(String id, {bool pinned = false}) {
    final now = DateTime(2026);
    return WindowsWorkspaceTab(
      id: id,
      type: WindowsWorkspaceTabType.video,
      arguments: {'bvid': id, if (pinned) 'pinned': true},
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    WindowsVideoTabService.enabledOverride = true;
    WindowsVideoTabService.clear();
  });

  tearDown(() => WindowsVideoTabService.enabledOverride = null);

  group('WindowsVideoTabService.keyFromArgs', () {
    test('builds stable keys for supported tab types', () {
      expect(
        WindowsVideoTabService.keyFromArgs({
          'bvid': 'BV1xx',
          'cid': 42,
        }),
        'video:BV1xx:42',
      );
      expect(
        WindowsVideoTabService.keyFromArgs({
          'mediaTabType': 'search',
          'keyword': 'flutter',
        }),
        'search:flutter',
      );
      expect(
        WindowsVideoTabService.keyFromArgs({
          'mediaTabType': 'member',
          'mid': 123,
        }),
        'member:123',
      );
      expect(
        WindowsVideoTabService.keyFromArgs({
          'mediaTabType': 'dynamic',
          'dynamicId': '456',
        }),
        'dynamic:456',
      );
      expect(
        WindowsVideoTabService.keyFromArgs({
          'mediaTabType': 'tool',
          'tabRoute': '/setting',
        }),
        'tool:/setting',
      );
    });
  });

  group('WindowsWorkspaceRouteRegistry', () {
    test('uses unique paths with complete route categories', () {
      final paths = WindowsWorkspaceRouteRegistry.definitions
          .map((route) => route.path)
          .toList(growable: false);

      expect(paths.toSet(), hasLength(paths.length));
      expect(
        WindowsVideoTabService.nestedRoutes,
        unorderedEquals(WindowsWorkspaceRouteRegistry.nestedPaths),
      );
      expect(
        WindowsVideoTabService.workspaceRoutes,
        unorderedEquals(WindowsWorkspaceRouteRegistry.toolTabPaths),
      );
      for (final route in WindowsWorkspaceRouteRegistry.definitions) {
        expect(WindowsWorkspaceRouteRegistry.buildPage(route.path), isNotNull);
        if (route.opensAsToolTab) {
          expect(route.defaultTitle, isNotEmpty);
        }
      }
    });

    test('registers every workspace path globally without duplicates', () {
      final globalPaths = Routes.getPages.map((route) => route.name).toList();

      expect(globalPaths.toSet(), hasLength(globalPaths.length));
      expect(
        globalPaths,
        containsAll(
          WindowsWorkspaceRouteRegistry.definitions.map((route) => route.path),
        ),
      );
    });
  });

  group('WindowsWorkspaceTab.title', () {
    test('uses loaded titles before type fallbacks', () {
      final now = DateTime(2026);
      final item = WindowsWorkspaceTab(
        id: 'member:123',
        type: WindowsWorkspaceTabType.member,
        arguments: {'mid': 123, 'title': 'Test user'},
        createdAt: now,
        updatedAt: now,
      );

      expect(item.title, 'Test user');
    });

    test('uses useful fallback titles', () {
      final now = DateTime(2026);
      final search = WindowsWorkspaceTab(
        id: 'search:flutter',
        type: WindowsWorkspaceTabType.search,
        arguments: {'keyword': 'flutter'},
        createdAt: now,
        updatedAt: now,
      );
      final member = WindowsWorkspaceTab(
        id: 'member:123',
        type: WindowsWorkspaceTabType.member,
        arguments: {'mid': 123},
        createdAt: now,
        updatedAt: now,
      );

      expect(search.title, '搜索: flutter');
      expect(member.title, '用户 123');
    });
  });

  group('WindowsWorkspaceTab model', () {
    test('normalizes every tab payload type in one place', () {
      final arguments = WindowsWorkspaceTabIdentity.normalizeArguments(
        {'roomId': 42, 'mediaTabType': 'video'},
        WindowsWorkspaceTabType.live,
      );

      expect(arguments, {
        'roomId': 42,
        'mediaTabType': WindowsWorkspaceTabType.live.name,
      });
    });

    test('shares lifecycle capabilities without treating a tool tab as media',
        () {
      final now = DateTime(2026, 8, 31);
      final tool = WindowsWorkspaceTab(
        id: 'tool:/setting',
        type: WindowsWorkspaceTabType.tool,
        arguments: {'tabRoute': '/setting', 'title': '设置'},
        createdAt: now,
        updatedAt: now,
      );
      final live = WindowsWorkspaceTab(
        id: 'live:42',
        type: WindowsWorkspaceTabType.live,
        arguments: {'roomId': 42},
        createdAt: now,
        updatedAt: now,
      );

      expect(tool.canClose, isTrue);
      expect(tool.canPin, isTrue);
      expect(tool.canSplit, isFalse);
      expect(tool.supportsAudio, isFalse);
      expect(tool.rootRoute, '/setting');
      expect(live.canSplit, isTrue);
      expect(live.supportsAudio, isTrue);
      expect(live.rootRoute, '/liveRoom');
    });

    test('keeps user tab state when route payload is refreshed', () {
      final item = WindowsWorkspaceTab(
        id: 'video:BV1xx:7',
        type: WindowsWorkspaceTabType.video,
        arguments: {
          'bvid': 'BV1xx',
          'cid': 7,
          'title': '已加载标题',
          'pinned': true,
        },
        createdAt: DateTime(2026, 8, 31),
        updatedAt: DateTime(2026, 8, 31),
      );

      item.replaceArguments({'bvid': 'BV1xx', 'cid': 7, 'progress': 1200});

      expect(item.arguments['title'], '已加载标题');
      expect(item.arguments['pinned'], isTrue);
      expect(item.arguments['progress'], 1200);
    });

    test('copies only persisted state for recently closed tab restoration', () {
      final tab = WindowsWorkspaceTab(
        id: 'tool:/history',
        type: WindowsWorkspaceTabType.tool,
        arguments: {'tabRoute': '/history', 'title': '观看记录'},
        createdAt: DateTime(2026, 8, 31),
        updatedAt: DateTime(2026, 8, 31),
      );
      final restoredAt = DateTime(2026, 8, 31, 12);

      final restored = tab.copyForRestore(restoredAt: restoredAt);
      restored.arguments['title'] = '已恢复';

      expect(restored, isNot(same(tab)));
      expect(tab.arguments['title'], '观看记录');
      expect(restored.updatedAt, restoredAt);
      expect(restored.createdAt, tab.createdAt);
    });

    test('restores tool tabs through the same history as media tabs', () {
      WindowsVideoTabService.upsert(
        {'tabRoute': '/setting', 'title': '设置'},
        type: WindowsWorkspaceTabType.tool,
      );

      WindowsVideoTabService.close('tool:/setting');

      expect(
        WindowsVideoTabService.recentlyClosedTabs.single.type,
        WindowsWorkspaceTabType.tool,
      );
      expect(WindowsVideoTabService.restoreLastClosedTab(), isTrue);
      expect(WindowsVideoTabService.has('tool:/setting'), isTrue);
    });
  });

  group('desktop tab management', () {
    test('wraps previous tab selection from the first tab to the last tab', () {
      WindowsVideoTabService.tabs.addAll([
        tab('video:first'),
        tab('video:last'),
      ]);
      WindowsVideoTabService.activeId.value = 'video:first';

      WindowsVideoTabService.selectRelative(-1);

      expect(WindowsVideoTabService.activeId.value, 'video:last');
    });

    test('keeps multiple media tabs audible outside split mode', () async {
      WindowsVideoTabService.upsert({'bvid': 'one'});
      WindowsVideoTabService.upsert({'bvid': 'two'});

      expect(
        WindowsVideoTabService.audibleTabIds,
        containsAll(['video:one', 'video:two']),
      );
      expect(
        WindowsVideoTabService.shouldSuppressTabAudio('video:one', false),
        isFalse,
      );
      expect(
        WindowsVideoTabService.shouldSuppressTabAudio('video:two', false),
        isFalse,
      );

      await WindowsVideoTabService.setTabAudioEnabled('video:one', false);
      expect(
        WindowsVideoTabService.shouldSuppressTabAudio('video:one', false),
        isTrue,
      );
      expect(
        WindowsVideoTabService.shouldSuppressTabAudio('video:two', false),
        isFalse,
      );
    });

    test('suppresses audible tabs outside the active split', () {
      WindowsVideoTabService.upsert({'bvid': 'one'});
      WindowsVideoTabService.upsert({'bvid': 'two'});
      WindowsVideoTabService.upsert({'bvid': 'outside'});
      WindowsVideoTabService.beginSplitSelection();
      WindowsVideoTabService.toggleSplitDraft('video:outside');
      WindowsVideoTabService.toggleSplitDraft('video:one');
      WindowsVideoTabService.toggleSplitDraft('video:two');
      expect(WindowsVideoTabService.applySplitSelection(), isTrue);

      expect(
        WindowsVideoTabService.shouldSuppressTabAudio('video:outside', false),
        isTrue,
      );
    });

    test('pins tabs without changing their identity', () {
      WindowsVideoTabService.tabs.add(tab('video:one'));

      WindowsVideoTabService.togglePinned('video:one');

      expect(WindowsVideoTabService.isPinned('video:one'), isTrue);
      expect(
        WindowsVideoTabService.tabs
            .singleWhere((item) => item.id == 'video:one')
            .id,
        'video:one',
      );
    });

    test('remembers and restores a closed tab', () {
      WindowsVideoTabService.tabs.add(tab('video:one'));

      WindowsVideoTabService.close('video:one');

      expect(WindowsVideoTabService.recentlyClosedTabs.single.id, 'video:one');
      expect(WindowsVideoTabService.restoreLastClosedTab(), isTrue);
      expect(WindowsVideoTabService.has('video:one'), isTrue);
    });

    test('keeps pinned tabs when closing other tabs', () {
      WindowsVideoTabService.tabs.addAll([
        tab('video:pinned', pinned: true),
        tab('video:active'),
        tab('video:other'),
      ]);

      WindowsVideoTabService.closeOthers('video:active');

      expect(WindowsVideoTabService.has('video:pinned'), isTrue);
      expect(WindowsVideoTabService.has('video:active'), isTrue);
      expect(WindowsVideoTabService.has('video:other'), isFalse);
    });
  });
}
