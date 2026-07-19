import 'dart:io' show Platform;

import 'package:PiliPlus/plugin/pl_player/widgets/app_bar_ani.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Windows player controls combine fade and slide motion', (
    tester,
  ) async {
    final controller = AnimationController(
      vsync: const TestVSync(),
      duration: const Duration(milliseconds: 180),
      value: 1,
    );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AppBarAni(
          controller: controller,
          isTop: true,
          isFullScreen: false,
          removeSafeArea: true,
          child: const SizedBox(width: 100, height: 40),
        ),
      ),
    );

    final appBar = find.byType(AppBarAni);
    expect(
      find.descendant(of: appBar, matching: find.byType(SlideTransition)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: appBar, matching: find.byType(FadeTransition)),
      Platform.isWindows ? findsOneWidget : findsNothing,
    );
  });
}
