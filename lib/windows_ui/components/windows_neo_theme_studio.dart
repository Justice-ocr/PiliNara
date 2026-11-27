import 'dart:io' show File;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;

/// Visual theme gallery, depth selector, and Custom workshop displayed inside
/// Windows appearance settings so users can preview and configure every
/// Windows Neo theme family live.
class WindowsNeoThemeStudio extends StatelessWidget {
  const WindowsNeoThemeStudio({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;

    return ValueListenableBuilder<WindowsNeoThemeFamily>(
      valueListenable: WindowsNeoThemeController.family,
      builder: (context, selectedFamily, _) =>
          ValueListenableBuilder<WindowsNeoThemeDepth>(
            valueListenable: WindowsNeoThemeController.depth,
            builder: (context, selectedDepth, _) => ValueListenableBuilder<int>(
              valueListenable: WindowsNeoThemeController.customVersion,
              builder: (context, _, _) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: tokens.surfaceRaised,
                      borderRadius: tokens.cardRadius,
                      border: Border.all(
                        color: tokens.border.withValues(alpha: 0.52),
                      ),
                      boxShadow: tokens.cardShadow,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 3,
                                height: 18,
                                color: tokens.accentInk,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Windows Neo 主题工作室',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: tokens.ink,
                                  fontWeight: FontWeight.w700,
                                  fontFamilyFallback:
                                      tokens.displayFontFallback,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                '点击即时预览切换',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: tokens.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.maxWidth >= 620
                                  ? 3
                                  : 2;
                              const spacing = 10.0;
                              final itemWidth =
                                  (constraints.maxWidth -
                                      spacing * (columns - 1)) /
                                  columns;
                              return Wrap(
                                spacing: spacing,
                                runSpacing: spacing,
                                children: [
                                  for (final def
                                      in WindowsNeoThemeRegistry.values)
                                    SizedBox(
                                      width: itemWidth,
                                      child: _ThemeFamilyCard(
                                        definition: def,
                                        selected: def.family == selectedFamily,
                                        onTap: () =>
                                            WindowsNeoThemeController.select(
                                              def.family,
                                            ),
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),
                          if (selectedFamily ==
                              WindowsNeoThemeFamily.custom) ...[
                            const SizedBox(height: 16),
                            Divider(
                              height: 1,
                              color: tokens.border.withValues(alpha: 0.42),
                            ),
                            const SizedBox(height: 14),
                            const _CustomThemeWorkshopPanel(),
                          ],
                          const SizedBox(height: 16),
                          Divider(
                            height: 1,
                            color: tokens.border.withValues(alpha: 0.42),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Text(
                                '视觉深度',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: tokens.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _depthDescription(selectedDepth),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: tokens.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              for (
                                var i = 0;
                                i < WindowsNeoThemeDepth.values.length;
                                i++
                              ) ...[
                                if (i > 0) const SizedBox(width: 8),
                                Expanded(
                                  child: _DepthSegment(
                                    depth: WindowsNeoThemeDepth.values[i],
                                    selected:
                                        WindowsNeoThemeDepth.values[i] ==
                                        selectedDepth,
                                    onTap: () =>
                                        WindowsNeoThemeController.selectDepth(
                                          WindowsNeoThemeDepth.values[i],
                                        ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 14),
                          Divider(
                            height: 1,
                            color: tokens.border.withValues(alpha: 0.42),
                          ),
                          const SizedBox(height: 10),
                          ValueListenableBuilder<bool>(
                            valueListenable:
                                WindowsNeoThemeController.hoverPreview,
                            builder: (context, hoverPreviewEnabled, _) => Row(
                              children: [
                                Icon(
                                  Icons.slow_motion_video_rounded,
                                  size: 18,
                                  color: tokens.accentInk,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '首页视频卡片悬停预览',
                                        style: theme.textTheme.labelLarge
                                            ?.copyWith(
                                              color: tokens.ink,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      Text(
                                        '鼠标悬停 0.6 秒后随指针横向滑动预览视频关键帧',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(color: tokens.muted),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: hoverPreviewEnabled,
                                  onChanged:
                                      WindowsNeoThemeController.setHoverPreview,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
    );
  }

  static String _depthDescription(WindowsNeoThemeDepth depth) => switch (depth) {
    WindowsNeoThemeDepth.minimal => '纯净内容模式，隐藏背景插画、网格与装饰线',
    WindowsNeoThemeDepth.moderate => '平衡轻量氛围，保留微弱插画与页头标识',
    WindowsNeoThemeDepth.complex => '丰富桌面视觉，启用插画、矢量网格与页头波形',
    WindowsNeoThemeDepth.maximal => '完整世界观舞台，开启全套 HUD 刻度与状态标牌',
  };
}

class _CustomThemeWorkshopPanel extends StatefulWidget {
  const _CustomThemeWorkshopPanel();

  @override
  State<_CustomThemeWorkshopPanel> createState() =>
      _CustomThemeWorkshopPanelState();
}

class _CustomThemeWorkshopPanelState extends State<_CustomThemeWorkshopPanel> {
  static const _swatches = <(String, Color)>[
    ('Miku 青', Color(0xFF39C5BB)),
    ('哔哩粉', Color(0xFFFB7299)),
    ('深海蓝', Color(0xFF2563EB)),
    ('赛博紫', Color(0xFF8B5CF6)),
    ('翡翠绿', Color(0xFF10B981)),
    ('琥珀金', Color(0xFFF59E0B)),
    ('珊瑚红', Color(0xFFF43F5E)),
    ('极光靛', Color(0xFF4F46E5)),
    ('天空蓝', Color(0xFF0EA5E9)),
    ('石墨灰', Color(0xFF475569)),
  ];

  bool _extracting = false;

  Future<void> _pickWallpaperAndExtract({bool extractColor = true}) async {
    if (_extracting) return;
    try {
      final files = await FilePicker.pickFiles(type: FileType.image);
      if (files.isEmpty) return;
      final path = files.first.path;
      if (path == null || path.isEmpty) return;
      final file = File(path);
      if (!file.existsSync()) return;

      await WindowsNeoThemeController.setCustomWallpaper(path);

      if (extractColor) {
        if (mounted) setState(() => _extracting = true);
        final extracted = await _extractDominantAccent(file);
        if (extracted != null) {
          await WindowsNeoThemeController.setCustomAccent(extracted);
          SmartDialog.showToast('已应用壁纸并自动提取主题色');
        } else {
          SmartDialog.showToast('已应用自定义壁纸');
        }
      } else {
        SmartDialog.showToast('已应用自定义壁纸');
      }
    } catch (_) {
      SmartDialog.showToast('读取图片失败，请重试');
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  Future<void> _extractFromCurrentWallpaper() async {
    final path = WindowsNeoThemeController.customWallpaper.value;
    if (path.isEmpty) return;
    final file = File(path);
    if (!file.existsSync()) return;
    setState(() => _extracting = true);
    try {
      final extracted = await _extractDominantAccent(file);
      if (extracted != null) {
        await WindowsNeoThemeController.setCustomAccent(extracted);
        SmartDialog.showToast('已从当前壁纸重新提取主题色');
      }
    } finally {
      if (mounted) setState(() => _extracting = false);
    }
  }

  /// Downscales the wallpaper to 64px wide and extracts the highest-scoring
  /// vibrant accent hue via 36-bin HSL vibrancy weighting.
  static Future<Color?> _extractDominantAccent(File file) async {
    try {
      final Uint8List bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      image.dispose();
      codec.dispose();
      if (byteData == null) return null;

      final data = byteData.buffer.asUint8List();
      final binWeight = List<double>.filled(36, 0);
      final binR = List<double>.filled(36, 0);
      final binG = List<double>.filled(36, 0);
      final binB = List<double>.filled(36, 0);

      for (var i = 0; i + 3 < data.length; i += 4) {
        final a = data[i + 3];
        if (a < 180) continue;
        final r = data[i];
        final g = data[i + 1];
        final b = data[i + 2];
        final hsl = HSLColor.fromColor(Color.fromARGB(255, r, g, b));
        if (hsl.saturation < 0.18 ||
            hsl.lightness < 0.12 ||
            hsl.lightness > 0.88) {
          continue;
        }
        final vibrancy =
            hsl.saturation * (1.0 - (hsl.lightness - 0.5).abs() * 1.35);
        if (vibrancy <= 0.05) continue;
        final bin = ((hsl.hue / 10).floor()) % 36;
        binWeight[bin] += vibrancy;
        binR[bin] += r * vibrancy;
        binG[bin] += g * vibrancy;
        binB[bin] += b * vibrancy;
      }

      var bestBin = -1;
      var bestWeight = 0.0;
      for (var i = 0; i < 36; i++) {
        if (binWeight[i] > bestWeight) {
          bestWeight = binWeight[i];
          bestBin = i;
        }
      }
      if (bestBin < 0 || bestWeight <= 0) return null;

      final avgColor = Color.fromARGB(
        255,
        (binR[bestBin] / bestWeight).round().clamp(0, 255),
        (binG[bestBin] / bestWeight).round().clamp(0, 255),
        (binB[bestBin] / bestWeight).round().clamp(0, 255),
      );
      final tuned = HSLColor.fromColor(avgColor);
      return tuned
          .withSaturation(tuned.saturation.clamp(0.42, 0.88))
          .withLightness(tuned.lightness.clamp(0.42, 0.62))
          .toColor();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    final currentAccent = WindowsNeoThemeController.customAccent.value;
    final wallpaperPath = WindowsNeoThemeController.customWallpaper.value;
    final hasWallpaper =
        wallpaperPath.isNotEmpty && File(wallpaperPath).existsSync();
    final opacity = WindowsNeoThemeController.customOpacity.value;
    final squared = WindowsNeoThemeController.customSquared.value;
    final hexLabel =
        '#${(currentAccent.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: tokens.cardRadius,
        border: Border.all(
          color: tokens.accentBorder.withValues(alpha: 0.42),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune_rounded, size: 16, color: tokens.accentInk),
              const SizedBox(width: 8),
              Text(
                '自定义主题工坊',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: tokens.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: tokens.accentSurface,
                  borderRadius: tokens.mediaBadgeRadius,
                ),
                child: Text(
                  hexLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.accentInk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '强调色预设',
            style: theme.textTheme.labelMedium?.copyWith(color: tokens.muted),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (name, color) in _swatches)
                Tooltip(
                  message: name,
                  child: InkWell(
                    onTap: () =>
                        WindowsNeoThemeController.setCustomAccent(color),
                    borderRadius: tokens.actionRadius,
                    child: AnimatedContainer(
                      duration: context.windowsNeoDuration(tokens.motionFast),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: squared
                            ? BorderRadius.zero
                            : BorderRadius.circular(14),
                        border: Border.all(
                          color: currentAccent.toARGB32() == color.toARGB32()
                              ? tokens.ink
                              : Colors.white.withValues(alpha: 0.4),
                          width: currentAccent.toARGB32() == color.toARGB32()
                              ? 2.2
                              : 1,
                        ),
                      ),
                      child: currentAccent.toARGB32() == color.toARGB32()
                          ? Icon(
                              Icons.check,
                              size: 14,
                              color: color.computeLuminance() > 0.5
                                  ? const Color(0xFF111111)
                                  : Colors.white,
                            )
                          : null,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '背景壁纸与智能取色',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: tokens.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasWallpaper ? p.basename(wallpaperPath) : '未设置自定义壁纸',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _extracting ? null : _pickWallpaperAndExtract,
                icon: Icon(
                  _extracting
                      ? Icons.hourglass_top_rounded
                      : Icons.wallpaper_rounded,
                  size: 16,
                ),
                label: Text(_extracting ? '取色中...' : '选图并取色'),
              ),
              if (hasWallpaper) ...[
                const SizedBox(width: 6),
                IconButton(
                  tooltip: '重新提取壁纸主色',
                  onPressed: _extracting ? null : _extractFromCurrentWallpaper,
                  icon: const Icon(Icons.colorize_rounded, size: 18),
                ),
                IconButton(
                  tooltip: '清除自定义壁纸',
                  onPressed: () =>
                      WindowsNeoThemeController.setCustomWallpaper(''),
                  icon: const Icon(Icons.delete_outline, size: 18),
                ),
              ],
            ],
          ),
          if (hasWallpaper) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  '壁纸透明度',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.muted,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: opacity,
                    min: 0.05,
                    max: 0.30,
                    divisions: 25,
                    onChanged: WindowsNeoThemeController.setCustomOpacity,
                  ),
                ),
                SizedBox(
                  width: 38,
                  child: Text(
                    '${(opacity * 100).round()}%',
                    textAlign: TextAlign.right,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '几何风格',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.muted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _GeometrySegment(
                        label: '柔圆角 · Win11',
                        selected: !squared,
                        onTap: () =>
                            WindowsNeoThemeController.setCustomSquared(false),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _GeometrySegment(
                        label: '工业直角 · 终端',
                        selected: squared,
                        onTap: () =>
                            WindowsNeoThemeController.setCustomSquared(true),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GeometrySegment extends StatelessWidget {
  const _GeometrySegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return Material(
      color: selected ? tokens.accentSurface : tokens.surfaceRaised,
      borderRadius: tokens.actionRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: tokens.hover,
        child: Container(
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: tokens.actionRadius,
            border: Border.all(
              color: selected
                  ? tokens.accentBorder
                  : tokens.border.withValues(alpha: 0.55),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? tokens.accentInk : tokens.muted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeFamilyCard extends StatefulWidget {
  const _ThemeFamilyCard({
    required this.definition,
    required this.selected,
    required this.onTap,
  });

  final WindowsNeoThemeDefinition definition;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_ThemeFamilyCard> createState() => _ThemeFamilyCardState();
}

class _ThemeFamilyCardState extends State<_ThemeFamilyCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeTokens = context.windowsNeo;
    final preview = widget.definition.buildTokens(
      theme,
      widget.definition.defaultDepth,
    );
    final isCustom = widget.definition.family == WindowsNeoThemeFamily.custom;
    final customPath = isCustom
        ? WindowsNeoThemeController.customWallpaper.value
        : '';
    final customFile = customPath.isNotEmpty ? File(customPath) : null;
    final hasCustomFile = customFile != null && customFile.existsSync();
    final asset =
        widget.definition.family.backdropAsset ??
        'assets/images/windows_neo_miku_sidebar.png';
    final cardRadius = preview.cardRadius;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: context.windowsNeoDuration(activeTokens.motionFast),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: preview.surface,
          borderRadius: cardRadius,
          border: Border.all(
            color: widget.selected
                ? activeTokens.accentBorder
                : _hovered
                ? activeTokens.border
                : activeTokens.border.withValues(alpha: 0.45),
            width: widget.selected ? 1.8 : 1.0,
          ),
          boxShadow: widget.selected || _hovered
              ? activeTokens.cardShadow
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: cardRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 62,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (isCustom && !hasCustomFile)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                preview.accent.withValues(alpha: 0.85),
                                preview.secondaryAccent.withValues(alpha: 0.52),
                                preview.surfaceRaised,
                              ],
                            ),
                          ),
                        )
                      else ...[
                        ColoredBox(color: preview.chromeSurface),
                        Opacity(
                          opacity: 0.72,
                          child: hasCustomFile
                              ? Image.file(
                                  customFile,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.center,
                                  filterQuality: FilterQuality.low,
                                  errorBuilder: (_, _, _) =>
                                      const SizedBox.shrink(),
                                )
                              : Image.asset(
                                  asset,
                                  fit: BoxFit.cover,
                                  alignment: Alignment.centerRight,
                                  filterQuality: FilterQuality.low,
                                ),
                        ),
                      ],
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              preview.chromeSurface.withValues(alpha: 0.84),
                              preview.chromeSurface.withValues(alpha: 0.22),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        top: 8,
                        child: Text(
                          preview.shellMark,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: preview.usesDarkChrome
                                ? Colors.white.withValues(alpha: 0.92)
                                : preview.ink,
                            fontWeight: FontWeight.w900,
                            fontFamilyFallback: preview.displayFontFallback,
                          ),
                        ),
                      ),
                      if (widget.selected)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: preview.accentFill,
                              borderRadius: preview.mediaBadgeRadius,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 13,
                              color: preview.onAccentFill,
                            ),
                          ),
                        ),
                      Positioned(
                        left: 10,
                        bottom: 7,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _SwatchDot(color: preview.background),
                            const SizedBox(width: 4),
                            _SwatchDot(color: preview.surfaceRaised),
                            const SizedBox(width: 4),
                            _SwatchDot(color: preview.accentFill),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 9),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.definition.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: preview.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              widget.definition.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: preview.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        preview.usesRoundedGeometry ? '柔角' : '直角',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: preview.muted,
                          fontSize: 10,
                        ),
                      ),
                    ],
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

class _SwatchDot extends StatelessWidget {
  const _SwatchDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 10,
    height: 10,
    decoration: BoxDecoration(
      color: color,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.55),
        width: 0.8,
      ),
    ),
  );
}

class _DepthSegment extends StatelessWidget {
  const _DepthSegment({
    required this.depth,
    required this.selected,
    required this.onTap,
  });

  final WindowsNeoThemeDepth depth;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return Material(
      color: selected ? tokens.accentSurface : tokens.surface,
      borderRadius: tokens.actionRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: tokens.hover,
        child: Container(
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: tokens.actionRadius,
            border: Border.all(
              color: selected
                  ? tokens.accentBorder
                  : tokens.border.withValues(alpha: 0.55),
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            depth.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? tokens.accentInk : tokens.muted,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              fontFamilyFallback: tokens.displayFontFallback,
            ),
          ),
        ),
      ),
    );
  }
}
