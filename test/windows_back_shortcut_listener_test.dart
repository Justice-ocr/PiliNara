import 'package:PiliPlus/windows_ui/components/windows_back_shortcut_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Alt+Left reaches desktop back while a text field has focus', (
    tester,
  ) async {
    var backCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: WindowsBackShortcutListener(
          onBack: () {
            backCount += 1;
            return true;
          },
          child: const Scaffold(body: TextField(autofocus: true)),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);

    expect(backCount, 1);
  });

  testWidgets('plain Left remains available to the focused text field', (
    tester,
  ) async {
    var backCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: WindowsBackShortcutListener(
          onBack: () {
            backCount += 1;
            return true;
          },
          child: const Scaffold(body: TextField(autofocus: true)),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);

    expect(backCount, 0);
  });

  testWidgets('Ctrl+W and Ctrl+Shift+T work while a text field has focus', (
    tester,
  ) async {
    var closeCount = 0;
    var restoreCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: WindowsBackShortcutListener(
          onBack: () => false,
          onCloseTab: () => closeCount += 1,
          onRestoreTab: () => restoreCount += 1,
          child: const Scaffold(body: TextField(autofocus: true)),
        ),
      ),
    );
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyW);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyT);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

    expect(closeCount, 1);
    expect(restoreCount, 1);
  });
}
