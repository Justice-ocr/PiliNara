import 'package:PiliPlus/models/common/home_tab_type.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_account_actions.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_section_tabs.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_stage.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:material_ui/material_ui.dart';

class WindowsNeoHome extends StatelessWidget {
  const WindowsNeoHome({
    super.key,
    required this.homeController,
    required this.mainController,
  });

  final HomeController homeController;
  final MainController mainController;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: homeController.tabController,
    builder: (context, _) {
      final index = homeController.tabController.index;
      final tokens = context.windowsNeo;
      final isWide = MediaQuery.sizeOf(context).width >= 960;
      return WindowsNeoPage(
        title: '\u9996\u9875',
        compactHeader: true,
        stageMode: WindowsNeoStageMode.browse,
        stageScene: WindowsNeoStageScene.home,
        stageIndex: index,
        stageState: homeController.tabs[index].label,
        leading: Icon(Icons.home_outlined, color: tokens.chromeAccent),
        actions: [
          if (isWide) ...[
            _HomeSearchTrigger(
              hintText: homeController.enableSearchWord &&
                      homeController.defaultSearch.value.isNotEmpty
                  ? homeController.defaultSearch.value
                  : '\u641c\u7d22\u89c6\u9891\u3001\u756a\u5267\u3001UP\u4e3b',
              onTap: () => PageUtils.toSearch(
                parameters: homeController.enableSearchWord
                    ? {'hintText': homeController.defaultSearch.value}
                    : null,
              ),
            ),
            const SizedBox(width: 6),
          ] else
            IconButton(
              tooltip: '\u641c\u7d22',
              onPressed: () => PageUtils.toSearch(
                parameters: homeController.enableSearchWord
                    ? {'hintText': homeController.defaultSearch.value}
                    : null,
              ),
              icon: const Icon(Icons.search_outlined),
            ),
          IconButton(
            tooltip: '\u5237\u65b0\u5f53\u524d\u5206\u533a',
            onPressed: homeController.onRefresh,
            icon: const Icon(Icons.refresh_outlined),
          ),
          WindowsNeoMessageButton(mainController: mainController),
          const SizedBox(width: 4),
          WindowsNeoAccountAvatar(mainController: mainController),
          const SizedBox(width: 4),
        ],
        commandBar: _HomeSectionTabs(homeController: homeController),
        child: TabBarView(
          controller: homeController.tabController,
          children: homeController.tabs.map((item) => item.page).toList(),
        ),
      );
    },
  );
}

class _HomeSectionTabs extends StatelessWidget {
  const _HomeSectionTabs({required this.homeController});

  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    return WindowsNeoSectionTabs(
      controller: homeController.tabController,
      horizontalPadding: 4,
      tabs: homeController.tabs
          .map((HomeTabType item) => Tab(text: item.label))
          .toList(),
      onTap: (_) {
        feedBack();
        if (!homeController.tabController.indexIsChanging) {
          homeController.animateToTop();
        }
      },
    );
  }
}

class _HomeSearchTrigger extends StatelessWidget {
  const _HomeSearchTrigger({required this.hintText, required this.onTap});

  final String hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final darkChrome = switch (tokens.family) {
      WindowsNeoThemeFamily.ark ||
      WindowsNeoThemeFamily.exAstris ||
      WindowsNeoThemeFamily.popucom ||
      WindowsNeoThemeFamily.corporate => true,
      _ => false,
    };
    final fill = darkChrome
        ? Colors.white.withValues(alpha: 0.08)
        : tokens.background.withValues(alpha: 0.85);
    final border = darkChrome
        ? Colors.white.withValues(alpha: 0.16)
        : tokens.border.withValues(alpha: 0.65);
    final fg = darkChrome
        ? Colors.white.withValues(alpha: 0.72)
        : tokens.muted;

    return Tooltip(
      message: '\u641c\u7d22 (Ctrl+K)',
      child: Material(
        color: fill,
        borderRadius: tokens.actionRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: tokens.accent.withValues(alpha: 0.10),
          child: Container(
            width: 210,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              borderRadius: tokens.actionRadius,
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Icon(Icons.search_outlined, size: 15, color: fg),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    hintText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: fg,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: darkChrome
                        ? Colors.white.withValues(alpha: 0.10)
                        : tokens.surfaceRaised,
                    borderRadius: tokens.mediaBadgeRadius,
                    border: Border.all(color: border, width: 0.8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    child: Text(
                      'Ctrl K',
                      style: TextStyle(
                        color: fg,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        fontFamilyFallback: tokens.displayFontFallback,
                      ),
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
