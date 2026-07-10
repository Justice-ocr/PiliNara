import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
      containsAll(['/search', '/member', '/dynamicDetail', '/articlePage']),
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
}
