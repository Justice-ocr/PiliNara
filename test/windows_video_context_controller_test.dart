import 'package:PiliPlus/pages/video/windows_video_context_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WindowsVideoContextController', () {
    test('maintains a last-in-first-out context history', () {
      final controller = WindowsVideoContextController();
      const first = WindowsVideoMemberContext(mid: 39);
      const second = WindowsVideoMemberContext(mid: 3939);

      controller
        ..push(first)
        ..push(second);

      expect(controller.depth, 2);
      expect(controller.current, same(second));
      expect(controller.entries, [first, second]);
      expect(controller.pop(), same(second));
      expect(controller.current, same(first));
    });

    test('replaces an equivalent current context without growing history', () {
      final controller = WindowsVideoContextController();
      const first = WindowsVideoMemberContext(mid: 39);
      const replacement = WindowsVideoMemberContext(mid: 39);

      controller
        ..push(first)
        ..push(replacement);

      expect(controller.depth, 1);
      expect(controller.current, same(replacement));
    });

    test('clear returns removed entries from newest to oldest', () {
      final controller = WindowsVideoContextController()
        ..push(const WindowsVideoMemberContext(mid: 39))
        ..push(const WindowsVideoMemberContext(mid: 3939));

      final removed = controller.clear();

      expect(removed.map((entry) => entry.id), ['member:3939', 'member:39']);
      expect(controller.current, isNull);
      expect(controller.canPop, isFalse);
    });

    test('exposes a read-only history view', () {
      final controller = WindowsVideoContextController()
        ..push(const WindowsVideoMemberContext(mid: 39));

      expect(
        () => controller.entries.add(
          const WindowsVideoMemberContext(mid: 3939),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
