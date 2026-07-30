import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

class WindowsBackShortcutListener extends StatefulWidget {
  const WindowsBackShortcutListener({
    super.key,
    required this.onBack,
    this.onCloseTab,
    this.onNextTab,
    this.onPreviousTab,
    this.onRestoreTab,
    this.onSearch,
    required this.child,
  });

  final bool Function() onBack;
  final VoidCallback? onCloseTab;
  final VoidCallback? onNextTab;
  final VoidCallback? onPreviousTab;
  final VoidCallback? onRestoreTab;
  final VoidCallback? onSearch;
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
    if (event is! KeyDownEvent) return false;
    final keyboard = HardwareKeyboard.instance;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
        keyboard.isAltPressed) {
      return widget.onBack();
    }
    if (!keyboard.isControlPressed) return false;
    if (event.logicalKey == LogicalKeyboardKey.keyW) {
      widget.onCloseTab?.call();
      return widget.onCloseTab != null;
    }
    if (event.logicalKey == LogicalKeyboardKey.tab) {
      (keyboard.isShiftPressed ? widget.onPreviousTab : widget.onNextTab)
          ?.call();
      return keyboard.isShiftPressed
          ? widget.onPreviousTab != null
          : widget.onNextTab != null;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyT &&
        keyboard.isShiftPressed) {
      widget.onRestoreTab?.call();
      return widget.onRestoreTab != null;
    }
    if (event.logicalKey == LogicalKeyboardKey.keyL) {
      widget.onSearch?.call();
      return widget.onSearch != null;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
