import 'package:PiliPlus/services/windows_back_navigation_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pops visible context before the page navigator', () {
    final calls = <String>[];

    final handled = WindowsBackNavigationPolicy.dispatch(
      popContext: () {
        calls.add('context');
        return true;
      },
      popPage: () {
        calls.add('page');
        return true;
      },
    );

    expect(handled, isTrue);
    expect(calls, ['context']);
  });

  test('falls through to page navigation when no context is open', () {
    final calls = <String>[];

    final handled = WindowsBackNavigationPolicy.dispatch(
      popContext: () {
        calls.add('context');
        return false;
      },
      popPage: () {
        calls.add('page');
        return true;
      },
    );

    expect(handled, isTrue);
    expect(calls, ['context', 'page']);
  });

  test('reports an unhandled back action at the tab root', () {
    expect(
      WindowsBackNavigationPolicy.dispatch(
        popContext: () => false,
        popPage: () => false,
      ),
      isFalse,
    );
  });
}
