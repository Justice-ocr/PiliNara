import 'package:PiliPlus/common/widgets/appbar/appbar.dart';
import 'package:PiliPlus/common/widgets/flutter/page/tabs.dart';
import 'package:PiliPlus/common/widgets/flutter/popup_menu.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:PiliPlus/common/widgets/keep_alive_wrapper.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/history/list.dart';
import 'package:PiliPlus/models_new/history/tab.dart';
import 'package:PiliPlus/pages/history/base_controller.dart';
import 'package:PiliPlus/pages/history/controller.dart';
import 'package:PiliPlus/pages/history/widgets/item.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart' hide TabBarView;
import 'package:get/get.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key, this.type});

  final String? type;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with AutomaticKeepAliveClientMixin, GridMixin {
  late final HistoryController _historyController;

  @override
  void initState() {
    super.initState();
    _historyController = Get.put(
      HistoryController(widget.type),
      tag: widget.type ?? 'all',
    );
  }

  HistoryController currCtr([int? index]) {
    try {
      index ??= _historyController.tabController!.index;
      if (index != 0) {
        return Get.find<HistoryController>(
          tag: _historyController.tabs[index - 1].type,
        );
      }
    } catch (_) {}
    return _historyController;
  }

  @override
  void dispose() {
    Get.delete<HistoryBaseController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    Widget child = refreshIndicator(
      onRefresh: _historyController.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _historyController.scrollController,
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: isWindowsNeo ? 18 : 0,
              top: isWindowsNeo ? 16 : 7,
              right: isWindowsNeo ? 18 : 0,
              bottom: padding.bottom + 100,
            ),
            sliver: Obx(
              () => WindowsNeoSliverContentTransition(
                token: _historyController.loadingState.value,
                sliver: _buildBody(_historyController.loadingState.value),
                enabled: isWindowsNeo,
              ),
            ),
          ),
        ],
      ),
    );
    if (widget.type != null) {
      return child;
    }
    return Obx(
      () {
        final enableMultiSelect =
            _historyController.baseCtr.enableMultiSelect.value;
        return popScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              currCtr().handleSelect();
            }
          },
          child: isWindowsNeo && !enableMultiSelect
              ? _buildWindowsPage(child, _historyController.tabs)
              : Scaffold(
                  backgroundColor: isWindowsNeo
                      ? context.windowsNeo.background
                      : null,
                  resizeToAvoidBottomInset: false,
                  appBar: MultiSelectAppBarWidget(
                    visible: enableMultiSelect,
                    ctr: currCtr(),
                    child: _buildAppBar,
                  ),
                  body: Padding(
                    padding: EdgeInsets.only(
                      left: padding.left,
                      right: padding.right,
                    ),
                    child: Obx(() {
                      final tabs = _historyController.tabs;
                      if (tabs.isEmpty) {
                        return child;
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTabs(tabs, enableMultiSelect, isWindowsNeo),
                          Expanded(
                            child:
                                TabBarView<
                                  CustomHorizontalDragGestureRecognizer
                                >(
                                  physics: enableMultiSelect
                                      ? const NeverScrollableScrollPhysics()
                                      : clampingScrollPhysics,
                                  controller: _historyController.tabController,
                                  horizontalDragGestureRecognizer:
                                      CustomHorizontalDragGestureRecognizer.new,
                                  children: [
                                    KeepAliveWrapper(child: child),
                                    ...tabs.map(
                                      (item) => HistoryPage(type: item.type),
                                    ),
                                  ],
                                ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildWindowsPage(Widget child, List<HistoryTab> tabs) {
    final tabView = tabs.isEmpty
        ? child
        : TabBarView<CustomHorizontalDragGestureRecognizer>(
            physics: clampingScrollPhysics,
            controller: _historyController.tabController,
            horizontalDragGestureRecognizer:
                CustomHorizontalDragGestureRecognizer.new,
            children: [
              KeepAliveWrapper(child: child),
              ...tabs.map((item) => HistoryPage(type: item.type)),
            ],
          );
    return WindowsNeoPage(
      title: '\u89c2\u770b\u8bb0\u5f55',
      subtitle:
          '\u7ee7\u7eed\u4f60\u7684\u89c6\u9891\u4e0e\u4e13\u680f\u6d4f\u89c8',
      leading: Icon(Icons.history_outlined, color: context.windowsNeo.accent),
      actions: [
        IconButton(
          tooltip: '\u641c\u7d22\u8bb0\u5f55',
          onPressed: () => Get.toNamed('/historySearch'),
          icon: const Icon(Icons.search_outlined),
        ),
        StaticPopupMenuButton(
          icon: const Icon(Icons.more_horiz),
          tooltip: '\u66f4\u591a\u64cd\u4f5c',
          itemBuilder: (_) => [
            PopupMenuItem(
              onTap: () => _historyController.baseCtr.onPauseHistory(context),
              child: Obx(
                () => Text(
                  !_historyController.baseCtr.pauseStatus.value
                      ? '\u6682\u505c\u89c2\u770b\u8bb0\u5f55'
                      : '\u6062\u590d\u89c2\u770b\u8bb0\u5f55',
                ),
              ),
            ),
            PopupMenuItem(
              onTap: () => _historyController.baseCtr.onClearHistory(
                context,
                () {
                  _historyController.loadingState.value = const Success(null);
                  if (_historyController.tabController != null) {
                    for (final item in _historyController.tabs) {
                      try {
                        Get.find<HistoryController>(
                          tag: item.type,
                        ).loadingState.value = const Success(
                          null,
                        );
                      } catch (_) {}
                    }
                  }
                },
              ),
              child: const Text('\u6e05\u7a7a\u89c2\u770b\u8bb0\u5f55'),
            ),
            PopupMenuItem(
              onTap: currCtr().onDelViewedHistory,
              child: const Text('\u5220\u9664\u5df2\u770b\u8bb0\u5f55'),
            ),
          ],
        ),
        const SizedBox(width: 6),
      ],
      commandBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ?_buildPauseTip,
          if (tabs.isNotEmpty) _buildTabs(tabs, false, true),
        ],
      ),
      child: tabView,
    );
  }

  Widget _buildTabs(
    List<HistoryTab> tabs,
    bool enableMultiSelect,
    bool isWindowsNeo,
  ) {
    final tabBar = TabBar(
      controller: _historyController.tabController,
      onTap: (index) {
        if (!_historyController.tabController!.indexIsChanging) {
          currCtr().scrollController.animToTop();
        } else if (enableMultiSelect) {
          currCtr(
            _historyController.tabController!.previousIndex,
          ).handleSelect();
        }
      },
      tabs: [
        const Tab(text: '全部'),
        ...tabs.map((item) => Tab(text: item.name)),
      ],
      isScrollable: isWindowsNeo,
      tabAlignment: isWindowsNeo ? TabAlignment.start : null,
      dividerColor: isWindowsNeo ? Colors.transparent : null,
      dividerHeight: isWindowsNeo ? 0 : null,
      indicatorSize: isWindowsNeo
          ? TabBarIndicatorSize.label
          : TabBarIndicatorSize.tab,
      indicator: isWindowsNeo
          ? UnderlineTabIndicator(
              borderSide: BorderSide(
                color: context.windowsNeo.accent,
                width: 2.5,
              ),
            )
          : null,
      unselectedLabelColor: isWindowsNeo ? context.windowsNeo.muted : null,
    );
    if (!isWindowsNeo) return tabBar;
    return Container(
      height: 48,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: context.windowsNeo.surface,
        border: Border(bottom: BorderSide(color: context.windowsNeo.border)),
      ),
      alignment: Alignment.centerLeft,
      child: tabBar,
    );
  }

  AppBar get _buildAppBar => AppBar(
    title: const Text('观看记录'),
    bottom: _buildPauseTip,
    actions: [
      IconButton(
        tooltip: '搜索',
        onPressed: () => Get.toNamed('/historySearch'),
        icon: const Icon(Icons.search_outlined),
      ),
      StaticPopupMenuButton(
        itemBuilder: (_) => [
          PopupMenuItem(
            onTap: () => _historyController.baseCtr.onPauseHistory(context),
            child: Text(
              !_historyController.baseCtr.pauseStatus.value
                  ? '暂停观看记录'
                  : '恢复观看记录',
            ),
          ),
          PopupMenuItem(
            onTap: () => _historyController.baseCtr.onClearHistory(
              context,
              () {
                _historyController.loadingState.value = const Success(null);
                if (_historyController.tabController != null) {
                  for (final item in _historyController.tabs) {
                    try {
                      Get.find<HistoryController>(
                        tag: item.type,
                      ).loadingState.value = const Success(
                        null,
                      );
                    } catch (_) {}
                  }
                }
              },
            ),
            child: const Text('清空观看记录'),
          ),
          PopupMenuItem(
            onTap: currCtr().onDelViewedHistory,
            child: const Text('删除已看记录'),
          ),
        ],
      ),
      const SizedBox(width: 6),
    ],
  );

  Widget _buildBody(LoadingState<List<HistoryItemModel>?> loadingState) {
    return switch (loadingState) {
      Loading() => gridSkeleton,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverGrid.builder(
                gridDelegate: WindowsVideoTabService.enabled
                    ? SliverGridDelegateWithExtentAndRatio(
                        maxCrossAxisExtent: 520,
                        childAspectRatio: 4.2,
                        minHeight: 112,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      )
                    : gridDelegate,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _historyController.onLoadMore();
                  }
                  final item = response[index];
                  final card = HistoryItem(
                    item: item,
                    ctr: _historyController,
                    onDelete: (kid, business) =>
                        _historyController.delHistory(item),
                  );
                  return WindowsVideoTabService.enabled
                      ? WindowsNeoStaggeredReveal(
                          order: index,
                          enabled: index < 8,
                          child: card,
                        )
                      : card;
                },
                itemCount: response.length,
              )
            : HttpError(onReload: _historyController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _historyController.onReload,
      ),
    };
  }

  PreferredSizeWidget? get _buildPauseTip {
    if (_historyController.baseCtr.pauseStatus.value) {
      final theme = Theme.of(context).colorScheme;
      return PreferredSize(
        preferredSize: const Size.fromHeight(38),
        child: Container(
          height: 38,
          color: theme.secondaryContainer.withValues(alpha: 0.8),
          padding: const EdgeInsets.only(left: 16, right: 6),
          child: Row(
            children: [
              Expanded(
                child: Text.rich(
                  strutStyle: const StrutStyle(height: 1, leading: 0),
                  style: TextStyle(
                    height: 1,
                    color: theme.onSecondaryContainer,
                  ),
                  TextSpan(
                    children: [
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: Icon(
                          Icons.info_outline,
                          size: 18,
                          color: theme.onSecondaryContainer,
                        ),
                      ),
                      const TextSpan(text: ' 历史记录功能已关闭'),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _historyController.baseCtr.onPauseHistory(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 10,
                  ),
                  child: Text(
                    '点击开启',
                    strutStyle: const StrutStyle(height: 1, leading: 0),
                    style: TextStyle(height: 1, color: theme.primary),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }

  @override
  bool get wantKeepAlive => widget.type != null;
}
