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

  testWidgets('loading placeholders share one restrained sliver pulse', (
    tester,
  ) async {
    await tester.pumpWidget(const _LoadingPulseHarness());

    final initial = _loadingOpacity(tester);
    expect(initial, closeTo(0.72, 0.01));

    await tester.pump(const Duration(milliseconds: 550));
    expect(_loadingOpacity(tester), greaterThan(initial));
    expect(find.byType(SliverFadeTransition), findsOneWidget);
  });

  testWidgets('loading pulse honors reduced motion', (tester) async {
    await tester.pumpWidget(
      const _LoadingPulseHarness(disableAnimations: true),
    );

    expect(_loadingOpacity(tester), 1);
  });

  testWidgets('content transition replays once for a refreshed token', (
    tester,
  ) async {
    final token = ValueNotifier(0);
    addTearDown(token.dispose);

    await tester.pumpWidget(_ContentTransitionHarness(token: token));
    expect(_contentOpacity(tester), 1);

    token.value = 1;
    await tester.pump();
    expect(_contentOpacity(tester), 0);

    await tester.pump(const Duration(milliseconds: 100));
    expect(_contentOpacity(tester), inExclusiveRange(0, 1));

    await tester.pumpAndSettle();
    expect(_contentOpacity(tester), 1);
  });

  testWidgets('dark loading pulse uses a quieter opacity range', (
    tester,
  ) async {
    await tester.pumpWidget(const _LoadingPulseHarness(dark: true));

    expect(_loadingOpacity(tester), closeTo(0.82, 0.01));
  });
}

double _opacity(WidgetTester tester) {
  final finder = find.descendant(
    of: find.byType(WindowsNeoPageStage),
    matching: find.byType(FadeTransition),
  );
  return tester.widget<FadeTransition>(finder).opacity.value;
}

double _loadingOpacity(WidgetTester tester) => tester
    .widget<SliverFadeTransition>(find.byType(SliverFadeTransition))
    .opacity
    .value;

double _contentOpacity(WidgetTester tester) => tester
    .widget<SliverFadeTransition>(
      find.descendant(
        of: find.byType(WindowsNeoSliverContentTransition),
        matching: find.byType(SliverFadeTransition),
      ),
    )
    .opacity
    .value;

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

class _LoadingPulseHarness extends StatelessWidget {
  const _LoadingPulseHarness({
    this.disableAnimations = false,
    this.dark = false,
  });

  final bool disableAnimations;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: WindowsNeoTheme.apply(dark ? ThemeData.dark() : ThemeData.light()),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: CustomScrollView(
          slivers: [
            WindowsNeoSliverLoadingPulse(
              sliver: SliverList.list(
                children: const [SizedBox(height: 40)],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContentTransitionHarness extends StatelessWidget {
  const _ContentTransitionHarness({required this.token});

  final ValueNotifier<int> token;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: WindowsNeoTheme.apply(ThemeData.light()),
      home: CustomScrollView(
        slivers: [
          ValueListenableBuilder<int>(
            valueListenable: token,
            builder: (context, value, child) =>
                WindowsNeoSliverContentTransition(
                  token: value,
                  sliver: SliverList.list(
                    children: const [SizedBox(height: 40)],
                  ),
                ),
          ),
        ],
      ),
    );
  }
}
