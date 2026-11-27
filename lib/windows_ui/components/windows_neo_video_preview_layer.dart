import 'dart:async';
import 'dart:collection';
import 'dart:math' as math;

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models_new/video/video_shot/data.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:material_ui/material_ui.dart';

/// Displays a muted, low-overhead sprite-sheet keyframe preview when the user
/// intentionally hovers a desktop video card for 600 ms.
class WindowsNeoVideoPreviewLayer extends StatefulWidget {
  const WindowsNeoVideoPreviewLayer({
    super.key,
    required this.hovered,
    required this.bvid,
    required this.cid,
    required this.width,
    required this.height,
  });

  final bool hovered;
  final String? bvid;
  final int? cid;
  final double width;
  final double height;

  @override
  State<WindowsNeoVideoPreviewLayer> createState() =>
      _WindowsNeoVideoPreviewLayerState();
}

class _WindowsNeoVideoPreviewLayerState
    extends State<WindowsNeoVideoPreviewLayer> {
  static const int _maxCacheEntries = 48;
  static final LinkedHashMap<String, VideoShotData?> _shotCache =
      LinkedHashMap<String, VideoShotData?>();

  Timer? _delayTimer;
  Timer? _frameTimer;
  VideoShotData? _shot;
  int _frameIndex = 0;
  bool _active = false;

  String? get _cacheKey =>
      widget.bvid != null && widget.cid != null
          ? '${widget.bvid}:${widget.cid}'
          : null;

  @override
  void didUpdateWidget(covariant WindowsNeoVideoPreviewLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.bvid != widget.bvid || oldWidget.cid != widget.cid) {
      _stopPreview(clearShot: true);
    }
    if (widget.hovered != oldWidget.hovered) {
      if (widget.hovered) {
        _schedulePreview();
      } else {
        _stopPreview();
      }
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _frameTimer?.cancel();
    super.dispose();
  }

  void _schedulePreview() {
    if (!WindowsNeoThemeController.hoverPreview.value ||
        context.windowsNeoReduceMotion ||
        _cacheKey == null) {
      return;
    }
    _delayTimer?.cancel();
    _delayTimer = Timer(const Duration(milliseconds: 600), _loadAndPlay);
  }

  Future<void> _loadAndPlay() async {
    final key = _cacheKey;
    if (!mounted || !widget.hovered || key == null) return;

    VideoShotData? data;
    if (_shotCache.containsKey(key)) {
      data = _shotCache.remove(key);
      _shotCache[key] = data;
    } else {
      final res = await VideoHttp.videoshot(
        bvid: widget.bvid!,
        cid: widget.cid!,
      );
      if (res case Success(:final response)
          when response.image.isNotEmpty &&
              response.imgXLen > 0 &&
              response.imgYLen > 0) {
        data = response;
      }
      if (_shotCache.length >= _maxCacheEntries) {
        _shotCache.remove(_shotCache.keys.first);
      }
      _shotCache[key] = data;
    }

    if (!mounted || !widget.hovered || data == null) return;
    final totalFrames = _usableFrameCount(data);
    if (totalFrames <= 1) return;

    setState(() {
      _shot = data;
      _frameIndex = 0;
      _active = true;
    });

    _frameTimer?.cancel();
    _frameTimer = Timer.periodic(const Duration(milliseconds: 750), (_) {
      if (!mounted || !widget.hovered || _shot == null) {
        _stopPreview();
        return;
      }
      final count = _usableFrameCount(_shot!);
      setState(() {
        _frameIndex = (_frameIndex + 1) % count;
      });
    });
  }

  int _usableFrameCount(VideoShotData shot) {
    final firstSheetCapacity = shot.imgXLen * shot.imgYLen;
    final indexed = shot.index.isNotEmpty ? shot.index.length : firstSheetCapacity;
    return math.min(math.min(firstSheetCapacity, indexed), 18);
  }

  void _stopPreview({bool clearShot = false}) {
    _delayTimer?.cancel();
    _delayTimer = null;
    _frameTimer?.cancel();
    _frameTimer = null;
    if (_active || clearShot) {
      setState(() {
        _active = false;
        _frameIndex = 0;
        if (clearShot) _shot = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shot = _shot;
    final tokens = context.windowsNeo;
    if (!_active || shot == null || shot.image.isEmpty) {
      return const SizedBox.shrink();
    }
    final cols = shot.imgXLen;
    final rows = shot.imgYLen;
    final total = _usableFrameCount(shot);
    final idx = _frameIndex.clamp(0, math.max(0, total - 1));
    final col = idx % cols;
    final row = idx ~/ cols;
    final sheetWidth = widget.width * cols;
    final sheetHeight = widget.height * rows;
    final progress = total > 1 ? (idx + 1) / total : 1.0;

    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _active ? 1 : 0,
        duration: context.windowsNeoDuration(tokens.motionFast),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRect(
              child: OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: sheetWidth,
                maxWidth: sheetWidth,
                minHeight: sheetHeight,
                maxHeight: sheetHeight,
                child: Transform.translate(
                  offset: Offset(-col * widget.width, -row * widget.height),
                  child: CachedNetworkImage(
                    imageUrl: shot.image.first,
                    width: sheetWidth,
                    height: sheetHeight,
                    fit: BoxFit.fill,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    filterQuality: FilterQuality.low,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 2.5,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.35),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedFractionallySizedBox(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    widthFactor: progress,
                    child: ColoredBox(color: tokens.accentFill),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
