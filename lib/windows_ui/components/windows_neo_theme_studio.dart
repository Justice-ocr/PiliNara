import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:material_ui/material_ui.dart';

/// Visual theme gallery & depth selector displayed inside Windows appearance
/// settings so users can preview and switch all six Windows Neo families live.
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
            builder: (context, selectedDepth, _) {
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
                                fontFamilyFallback: tokens.displayFontFallback,
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
                            final columns = constraints.maxWidth >= 620 ? 3 : 2;
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
                      ],
                    ),
                  ),
                ),
              );
            },
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
                      ColoredBox(color: preview.chromeSurface),
                      Opacity(
                        opacity: 0.72,
                        child: Image.asset(
                          asset,
                          fit: BoxFit.cover,
                          alignment: Alignment.centerRight,
                          filterQuality: FilterQuality.low,
                        ),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              preview.chromeSurface.withValues(alpha: 0.88),
                              preview.chromeSurface.withValues(alpha: 0.25),
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
                        preview.identity.usesSquaredGeometry ? '直角' : '柔角',
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
