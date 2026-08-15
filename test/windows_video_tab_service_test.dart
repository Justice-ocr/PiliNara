import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  WindowsVideoTabItem tab(String id, {bool pinned = false}) {
    final now = DateTime(2026);
    return WindowsVideoTabItem(
      id: id,
      type: WindowsMediaTabType.video,
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

  test('declares the routes supported inside an active tab', () {
    expect(
      WindowsVideoTabService.nestedRoutes,
      containsAll([
        '/search',
        '/searchTrending',
        '/member',
        '/memberSearch',
        '/editProfile',
        '/spaceSetting',
        '/dynamicDetail',
        '/articlePage',
        '/articleList',
        '/dynTopic',
        '/blockSetting',
        '/blackListPage',
        '/sponsorBlock',
        '/aiSetting',
        '/playSpeedSet',
        '/colorSetting',
        '/fontSizeSetting',
        '/barSetting',
        '/historySearch',
        '/laterSearch',
        '/favDetail',
        '/favSearch',
        '/popularSeries',
        '/popularPrecious',
        '/rank',
        '/whisperDetail',
        '/replyMe',
        '/atMe',
        '/likeMe',
        '/sysMsg',
        '/webview',
        '/subDetail',
        '/msgLikeDetail',
        '/memberDynamics',
        '/follow',
        '/fan',
      ]),
    );
    expect(
      WindowsVideoTabService.workspaceRoutes,
      containsAll([
        '/download',
        '/fav',
        '/history',
        '/later',
        '/myReply',
        '/setting',
        '/subscription',
        '/whisper',
      ]),
    );
  });

  group('WindowsVideoTabItem.title', () {
    test('uses loaded titles before type fallbacks', () {
      final now = DateTime(2026);
      final item = WindowsVideoTabItem(
        id: 'member:123',
        type: WindowsMediaTabType.member,
        arguments: {'mid': 123, 'title': 'Test user'},
        createdAt: now,
        updatedAt: now,
      );

      expect(item.title, 'Test user');
    });

    test('uses useful fallback titles', () {
      final now = DateTime(2026);
      final search = WindowsVideoTabItem(
        id: 'search:flutter',
        type: WindowsMediaTabType.search,
        arguments: {'keyword': 'flutter'},
        createdAt: now,
        updatedAt: now,
      );
      final member = WindowsVideoTabItem(
        id: 'member:123',
        type: WindowsMediaTabType.member,
        arguments: {'mid': 123},
        createdAt: now,
        updatedAt: now,
      );

      expect(search.title, '搜索: flutter');
      expect(member.title, '用户 123');
    });
  });

  group('desktop tab management', () {
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
