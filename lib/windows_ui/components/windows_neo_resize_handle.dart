import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:material_ui/material_ui.dart';

/// Desktop vertical split-pane resize handle with hover accent feedback,
/// centered grip indicator, and double-click width reset.
class WindowsNeoResizeHandle extends StatefulWidget {
  const WindowsNeoResizeHandle({
    super.key,
    required this.onDragDelta,
    this.onReset,
    this.width = 6,
  });

  final ValueChanged<double> onDragDelta;
  final VoidCallback? onReset;
  final double width;

  @override
  State<WindowsNeoResizeHandle> createState() => _WindowsNeoResizeHandleState();
}

class _WindowsNeoResizeHandleState extends State<WindowsNeoResizeHandle> {
  bool _hovered = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final active = _hovered || _dragging;

    return Tooltip(
      message: widget.onReset != null ? '拖动调整宽度 · 双击重置' : '拖动调整宽度',
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onDoubleTap: widget.onReset,
          onHorizontalDragStart: (_) => setState(() => _dragging = true),
          onHorizontalDragUpdate: (details) =>
              widget.onDragDelta(details.delta.dx),
          onHorizontalDragEnd: (_) => setState(() => _dragging = false),
          onHorizontalDragCancel: () => setState(() => _dragging = false),
          child: SizedBox(
            width: widget.width,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedContainer(
                  duration: context.windowsNeoDuration(tokens.motionFast),
                  width: active ? 2 : 1,
                  color: active
                      ? tokens.accentInk.withValues(alpha: 0.78)
                      : tokens.border.withValues(alpha: 0.65),
                ),
                AnimatedOpacity(
                  duration: context.windowsNeoDuration(tokens.motionFast),
                  opacity: active ? 1 : 0,
                  child: Container(
                    width: 4,
                    height: 30,
                    decoration: BoxDecoration(
                      color: tokens.accentInk,
                      borderRadius: tokens.mediaBadgeRadius,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
