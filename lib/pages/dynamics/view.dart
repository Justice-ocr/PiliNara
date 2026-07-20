import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/dynamic/dynamics_type.dart';
import 'package:PiliPlus/models/common/dynamic/up_panel_position.dart';
import 'package:PiliPlus/models/dynamics/up.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/dynamics/controller.dart';
import 'package:PiliPlus/pages/dynamics/widgets/up_panel.dart';
import 'package:PiliPlus/pages/dynamics_create/view.dart';
import 'package:PiliPlus/pages/dynamics_tab/view.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_section_tabs.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart' hide DraggableScrollableSheet;
import 'package:get/get.dart';

class DynamicsPage extends StatefulWidget {
  const DynamicsPage({super.key});

  @override
  State<DynamicsPage> createState() => _DynamicsPageState();
}

class _DynamicsPageState extends CommonPageState<DynamicsPage>
    with AutomaticKeepAliveClientMixin {
  final _dynamicsController = Get.putOrFind(DynamicsController.new);
  UpPanelPosition get upPanelPosition => _dynamicsController.upPanelPosition;
  late final MainController _mainController = Get.find<MainController>();

  @override
  bool get wantKeepAlive => true;

  Widget _createDynamicBtn(ThemeData theme, {bool isRight = true}) => Center(
    child: Container(
      width: 34,
      height: 34,
      margin: EdgeInsets.only(left: !isRight ? 16 : 0, right: isRight ? 16 : 0),
      child: IconButton(
        tooltip: '发布动态',
        style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          backgroundColor: WidgetStatePropertyAll(
            theme.colorScheme.secondaryContainer,
          ),
        ),
        onPressed: () => CreateDynPanel.onCreateDyn(context),
        icon: Icon(
          Icons.add,
          size: 18,
          color: theme.colorScheme.onSecondaryContainer,
        ),
      ),
    ),
  );

  Widget upPanelPart(ThemeData theme, {bool? horizontal}) {
    final isTop = horizontal ?? upPanelPosition == .top;
    final needBg = upPanelPosition.index > 2;
    return Material(
      type: needBg ? .canvas : .transparency,
      color: needBg ? theme.colorScheme.surface : null,
      child: SizedBox(
        width: isTop
            ? null
            : horizontal == false
            ? 82
            : 64,
        height: isTop ? (horizontal == true ? 84 : 76) : null,
        child: NotificationListener<ScrollEndNotification>(
          onNotification: (notification) {
            final metrics = notification.metrics;
            if (metrics.pixels >= metrics.maxScrollExtent - 300) {
              _dynamicsController.onLoadMoreUp();
            }
            return false;
          },
          child: Obx(() => _buildUpPanel(_dynamicsController.upState.value)),
        ),
      ),
    );
  }

  Widget _buildUpPanel(LoadingState<FollowUpModel> upState) {
    return switch (upState) {
      Loading() => const SizedBox.shrink(),
      Success<FollowUpModel>() => UpPanel(
        dynamicsController: _dynamicsController,
        horizontal: WindowsVideoTabService.enabled
            ? MediaQuery.sizeOf(context).width < 800
            : null,
      ),
      Error() => Center(
        child: IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _dynamicsController
            ..upState.value = LoadingState<FollowUpModel>.loading()
            ..queryFollowUp(),
        ),
      ),
    };
  }

  bool get checkPage =>
      _mainController.navigationBars[0] != .dynamics &&
      _mainController.selectedIndex.value == 0;

  @override
  bool onNotificationType1(UserScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType1(notification);
  }

  @override
  bool onNotificationType2(ScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType2(notification);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    Widget? drawer;
    Widget? endDrawer;

    Widget? leading;
    List<Widget>? actions;

    Widget child = tabBarView(
      controller: _dynamicsController.tabController,
      children: DynamicsTabType.values
          .map((e) => DynamicsTabPage(dynamicsType: e))
          .toList(),
    );

    if (WindowsVideoTabService.enabled) {
      return _buildWindowsPage(context, theme, child);
    }

    switch (upPanelPosition) {
      case UpPanelPosition.top:
        child = Column(
          children: [
            upPanelPart(theme),
            Expanded(child: child),
          ],
        );
        actions = [_createDynamicBtn(theme)];
      case UpPanelPosition.leftFixed:
        child = Row(
          children: [
            upPanelPart(theme),
            Expanded(child: child),
          ],
        );
        actions = [_createDynamicBtn(theme)];
      case UpPanelPosition.rightFixed:
        child = Row(
          children: [
            Expanded(child: child),
            upPanelPart(theme),
          ],
        );
        actions = [_createDynamicBtn(theme)];
      case UpPanelPosition.leftDrawer:
        drawer = upPanelPart(theme);
        actions = [_createDynamicBtn(theme)];
      case UpPanelPosition.rightDrawer:
        endDrawer = upPanelPart(theme);
        leading = _createDynamicBtn(theme, isRight: false);
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        primary: false,
        leading: leading,
        leadingWidth: 50,
        toolbarHeight: 50,
        backgroundColor: Colors.transparent,
        title: SizedBox(
          height: 50,
          child: TabBar(
            dividerHeight: 0,
            isScrollable: true,
            tabAlignment: .center,
            dividerColor: Colors.transparent,
            labelColor: theme.colorScheme.primary,
            indicatorColor: theme.colorScheme.primary,
            controller: _dynamicsController.tabController,
            unselectedLabelColor: theme.colorScheme.onSurface,
            labelStyle:
                TabBarTheme.of(context).labelStyle?.copyWith(fontSize: 13) ??
                const TextStyle(fontSize: 13),
            tabs: DynamicsTabType.values
                .map((e) => Tab(text: e.label))
                .toList(),
            onTap: (index) {
              if (!_dynamicsController.tabController.indexIsChanging) {
                _dynamicsController.animateToTop();
              }
            },
          ),
        ),
        actions: actions,
      ),
      drawer: drawer,
      endDrawer: endDrawer,
      body: onBuild(child),
    );
  }

  Widget _buildWindowsPage(
    BuildContext context,
    ThemeData theme,
    Widget tabView,
  ) {
    return WindowsNeoPage(
      title: '\u52a8\u6001',
      subtitle: '\u5173\u6ce8\u5185\u5bb9\u4e0e\u6700\u65b0\u66f4\u65b0',
      leading: Icon(
        Icons.motion_photos_on_outlined,
        color: context.windowsNeo.accent,
      ),
      actions: [
        IconButton(
          tooltip: '\u5237\u65b0',
          onPressed: _dynamicsController.onRefresh,
          icon: const Icon(Icons.refresh_outlined),
        ),
        IconButton(
          tooltip: '\u53d1\u5e03\u52a8\u6001',
          onPressed: () => CreateDynPanel.onCreateDyn(context),
          icon: const Icon(Icons.add_circle_outline),
        ),
        const SizedBox(width: 6),
      ],
      commandBar: _buildWindowsTabs(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final horizontal = constraints.maxWidth < 800;
          if (horizontal) {
            return Column(
              children: [
                ColoredBox(
                  color: context.windowsNeo.surface.withValues(alpha: 0.62),
                  child: upPanelPart(theme, horizontal: true),
                ),
                const SizedBox(height: 12),
                Expanded(child: tabView),
              ],
            );
          }
          return Row(
            children: [
              ColoredBox(
                color: context.windowsNeo.surface.withValues(alpha: 0.62),
                child: upPanelPart(theme, horizontal: false),
              ),
              const SizedBox(width: 12),
              Expanded(child: tabView),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWindowsTabs() {
    return WindowsNeoSectionTabs(
      controller: _dynamicsController.tabController,
      tabs: DynamicsTabType.values
          .map((item) => Tab(text: item.label))
          .toList(),
      horizontalPadding: 14,
      onTap: (_) {
        if (!_dynamicsController.tabController.indexIsChanging) {
          _dynamicsController.animateToTop();
        }
      },
    );
  }
}
