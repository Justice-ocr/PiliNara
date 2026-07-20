import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

/// Shared secondary navigation for Windows workspaces.
class WindowsNeoSectionTabs extends StatelessWidget {
  const WindowsNeoSectionTabs({
    super.key,
    required this.controller,
    required this.tabs,
    this.onTap,
    this.horizontalPadding,
  });

  final TabController controller;
  final List<Widget> tabs;
  final ValueChanged<int>? onTap;
  final double? horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    final padding = horizontalPadding ?? tokens.pagePadding - 4;
    return SizedBox(
      height: tokens.sectionTabHeight,
      child: Stack(
        children: [
          Positioned(
            left: padding,
            right: padding,
            bottom: 1,
            child: const WindowsNeoRhythmRail(),
          ),
          TabBar(
            controller: controller,
            tabs: tabs,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            padding: EdgeInsets.symmetric(horizontal: padding),
            labelPadding: const EdgeInsets.symmetric(horizontal: 14),
            dividerColor: Colors.transparent,
            dividerHeight: 0,
            indicatorSize: TabBarIndicatorSize.label,
            indicator: const WindowsNeoTabIndicator(),
            labelColor: tokens.ink,
            unselectedLabelColor: tokens.muted,
            labelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
            unselectedLabelStyle: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
            overlayColor: WidgetStatePropertyAll(
              tokens.accent.withValues(alpha: 0.06),
            ),
            splashFactory: NoSplash.splashFactory,
            onTap: onTap,
          ),
        ],
      ),
    );
  }
}
