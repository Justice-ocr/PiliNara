import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class WindowsBackShortcutListener extends StatefulWidget {
  const WindowsBackShortcutListener({
    super.key,
    required this.onBack,
    required this.child,
  });

  final bool Function() onBack;
  final Widget child;

  @override
  State<WindowsBackShortcutListener> createState() =>
      _WindowsBackShortcutListenerState();
}

class _WindowsBackShortcutListenerState
    extends State<WindowsBackShortcutListener> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.arrowLeft ||
        !HardwareKeyboard.instance.isAltPressed) {
      return false;
    }
    return widget.onBack();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
