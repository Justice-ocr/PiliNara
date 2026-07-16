import 'package:PiliPlus/models/common/home_tab_type.dart';
import 'package:PiliPlus/pages/home/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/utils/feed_back.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_account_actions.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class WindowsNeoHome extends StatelessWidget {
  const WindowsNeoHome({
    super.key,
    required this.homeController,
    required this.mainController,
  });

  final HomeController homeController;
  final MainController mainController;

  @override
  Widget build(BuildContext context) {
    return WindowsNeoPage(
      title: '\u9996\u9875',
      compactHeader: true,
      leading: Icon(Icons.home_outlined, color: context.windowsNeo.accent),
      actions: [
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
  }
}

class _HomeSectionTabs extends StatelessWidget {
  const _HomeSectionTabs({required this.homeController});

  final HomeController homeController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = context.windowsNeo;
    return SizedBox(
      height: tokens.sectionTabHeight,
      child: TabBar(
        controller: homeController.tabController,
        tabs: homeController.tabs
            .map(
              (HomeTabType item) =>
                  Tab(text: item.label, height: tokens.sectionTabHeight - 2),
            )
            .toList(),
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        padding: EdgeInsets.symmetric(horizontal: tokens.pagePadding - 4),
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        indicatorSize: TabBarIndicatorSize.label,
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: tokens.accent, width: 2.4),
          borderRadius: BorderRadius.circular(2),
        ),
        labelColor: tokens.ink,
        unselectedLabelColor: tokens.muted,
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.bodySmall,
        overlayColor: WidgetStatePropertyAll(
          tokens.accent.withValues(alpha: 0.06),
        ),
        splashFactory: NoSplash.splashFactory,
        onTap: (_) {
          feedBack();
          if (!homeController.tabController.indexIsChanging) {
            homeController.animateToTop();
          }
        },
      ),
    );
  }
}
