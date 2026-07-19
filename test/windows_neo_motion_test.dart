import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('page stage fades selected Windows content into place', (
    tester,
  ) async {
    final active = ValueNotifier(false);
    addTearDown(active.dispose);

    await tester.pumpWidget(_MotionHarness(active: active));
    expect(_opacity(tester), 0);

    active.value = true;
    await tester.pump();
    expect(_opacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 120));
    expect(_opacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_opacity(tester), 1);
  });

  testWidgets('page stage honors reduced motion', (tester) async {
    final active = ValueNotifier(false);
    addTearDown(active.dispose);

    await tester.pumpWidget(
      _MotionHarness(active: active, disableAnimations: true),
    );
    active.value = true;
    await tester.pump();

    expect(_opacity(tester), 1);
  });
}

double _opacity(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(WindowsNeoPageStage),
    matching: find.byType(FadeTransition),
  );
  return tester.widget<FadeTransition>(finder).opacity.value;
}

class _MotionHarness extends StatelessWidget {
  const _MotionHarness({
    required this.active,
    this.disableAnimations = false,
  });

  final ValueNotifier<bool> active;
  final bool disableAnimations;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: WindowsNeoTheme.apply(ThemeData.light()),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: ValueListenableBuilder(
          valueListenable: active,
          builder: (context, value, child) => WindowsNeoPageStage(
            active: value,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
