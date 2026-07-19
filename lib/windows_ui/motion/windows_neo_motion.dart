import 'dart:async';

import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

extension WindowsNeoMotionContext on BuildContext {
  bool get windowsNeoReduceMotion =>
      MediaQuery.maybeOf(this)?.disableAnimations ?? false;

  Duration windowsNeoDuration(Duration duration) =>
      windowsNeoReduceMotion ? Duration.zero : duration;
}

/// Uses one composited opacity pulse for an entire loading sliver instead of
/// running a shimmer controller on every placeholder card.
class WindowsNeoSliverLoadingPulse extends StatefulWidget {
  const WindowsNeoSliverLoadingPulse({
    super.key,
    required this.sliver,
  });

  final Widget sliver;

  @override
  State<WindowsNeoSliverLoadingPulse> createState() =>
      _WindowsNeoSliverLoadingPulseState();
}

class _WindowsNeoSliverLoadingPulseState
    extends State<WindowsNeoSliverLoadingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final Animation<double> _opacity =
      Tween<double>(
        begin: 0.72,
        end: 1,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
      );
  bool _running = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.windowsNeo.motionLoading;
    if (context.windowsNeoReduceMotion) {
      _controller
        ..stop()
        ..value = 1;
      _running = false;
    } else if (!_running) {
      _controller.repeat(reverse: true);
      _running = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SliverFadeTransition(opacity: _opacity, sliver: widget.sliver);
  }
}

/// Preserves inactive tab state while giving newly selected content a quiet
/// fade and short vertical settle.
class WindowsNeoPageStage extends StatefulWidget {
  const WindowsNeoPageStage({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<WindowsNeoPageStage> createState() => _WindowsNeoPageStageState();
}

class _WindowsNeoPageStageState extends State<WindowsNeoPageStage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
    value: widget.active ? 1 : 0,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.86, curve: Curves.easeOutCubic),
  );
  late final Animation<Offset> _offset =
      Tween<Offset>(
        begin: const Offset(0, 0.012),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.windowsNeo.motionPage;
    if (context.windowsNeoReduceMotion) {
      _controller.value = widget.active ? 1 : 0;
    }
  }

  @override
  void didUpdateWidget(covariant WindowsNeoPageStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active == widget.active) return;
    if (!widget.active) {
      _controller.value = 0;
    } else if (context.windowsNeoReduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.active,
      child: FadeTransition(
        opacity: _opacity,
        child: SlideTransition(
          position: _offset,
          child: TickerMode(enabled: widget.active, child: widget.child),
        ),
      ),
    );
  }
}

/// Animates only the first visible items. Long lists remain still after their
/// initial reveal, avoiding continuous GPU work while scrolling.
class WindowsNeoStaggeredReveal extends StatefulWidget {
  const WindowsNeoStaggeredReveal({
    super.key,
    required this.order,
    required this.child,
    this.enabled = true,
  });

  final int order;
  final Widget child;
  final bool enabled;

  @override
  State<WindowsNeoStaggeredReveal> createState() =>
      _WindowsNeoStaggeredRevealState();
}

class _WindowsNeoStaggeredRevealState extends State<WindowsNeoStaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _offset =
      Tween<Offset>(
        begin: const Offset(0, 0.018),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
  Timer? _timer;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = context.windowsNeo.motionStandard;
    if (context.windowsNeoReduceMotion) {
      _timer?.cancel();
      _controller.value = 1;
      _scheduled = true;
      return;
    }
    if (_scheduled) return;
    _scheduled = true;
    if (!widget.enabled) {
      _controller.value = 1;
      return;
    }
    final step = context.windowsNeo.motionStagger.inMilliseconds;
    final delay = Duration(
      milliseconds: widget.order.clamp(0, 8).toInt() * step,
    );
    _timer = Timer(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}
