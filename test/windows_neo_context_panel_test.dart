import 'package:PiliPlus/windows_ui/components/windows_neo_context_panel.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('keeps the base panel state while a context is visible', (
    tester,
  ) async {
    final harnessKey = GlobalKey<_ContextHarnessState>();

    await tester.pumpWidget(
      _testApp(_ContextHarness(key: harnessKey)),
    );
    await tester.tap(find.byKey(const ValueKey('increment-base')));
    await tester.pump();
    expect(find.text('base:1'), findsOneWidget);

    harnessKey.currentState!.showContext();
    await tester.pump();
    expect(find.text('context'), findsOneWidget);

    harnessKey.currentState!.hideContext();
    await tester.pump();
    expect(find.text('base:1'), findsOneWidget);
  });

  testWidgets('context panel exposes one consistent back affordance', (
    tester,
  ) async {
    var backCount = 0;

    await tester.pumpWidget(
      _testApp(
        WindowsNeoContextPanel(
          title: '评论详情',
          onBack: () => backCount += 1,
          child: const SizedBox.expand(),
        ),
      ),
    );

    expect(find.text('评论详情'), findsOneWidget);
    await tester.tap(find.byTooltip('返回相关内容'));
    expect(backCount, 1);
  });
}

Widget _testApp(Widget child) => MaterialApp(
  home: Theme(
    data: WindowsNeoTheme.apply(ThemeData.light()),
    child: Scaffold(body: child),
  ),
);

class _ContextHarness extends StatefulWidget {
  const _ContextHarness({super.key});

  @override
  State<_ContextHarness> createState() => _ContextHarnessState();
}

class _ContextHarnessState extends State<_ContextHarness> {
  bool _showContext = false;

  void showContext() => setState(() => _showContext = true);
  void hideContext() => setState(() => _showContext = false);

  @override
  Widget build(BuildContext context) => WindowsNeoContextStack(
    base: const _CounterPanel(key: ValueKey('base-panel')),
    contexts: _showContext ? const [Center(child: Text('context'))] : const [],
  );
}

class _CounterPanel extends StatefulWidget {
  const _CounterPanel({super.key});

  @override
  State<_CounterPanel> createState() => _CounterPanelState();
}

class _CounterPanelState extends State<_CounterPanel> {
  int _count = 0;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text('base:$_count'),
      IconButton(
        key: const ValueKey('increment-base'),
        onPressed: () => setState(() => _count += 1),
        icon: const Icon(Icons.add),
      ),
    ],
  );
}
