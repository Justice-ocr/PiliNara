import 'package:PiliPlus/common/widgets/appbar/appbar.dart';
import 'package:PiliPlus/common/widgets/flutter/page/tabs.dart';
import 'package:PiliPlus/common/widgets/flutter/popup_menu.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/models/common/later_view_type.dart';
import 'package:PiliPlus/models_new/later/list.dart';
import 'package:PiliPlus/pages/common/fab_mixin.dart'
    show NoRightMarginFabLocation;
import 'package:PiliPlus/pages/later/base_controller.dart';
import 'package:PiliPlus/pages/later/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/request_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_section_tabs.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart' hide TabBarView;
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class LaterPage extends StatefulWidget {
  const LaterPage({super.key});

  @override
  State<LaterPage> createState() => _LaterPageState();
}

class _LaterPageState extends State<LaterPage>
    with SingleTickerProviderStateMixin {
  final LaterBaseController _baseCtr = Get.put(LaterBaseController());
  late final TabController _tabController;

  LaterController currCtr([int? index]) {
    final type = LaterViewType.values[index ?? _tabController.index];
    return Get.putOrFind(
      () => LaterController(type),
      tag: type.type.toString(),
    );
  }

  final _sortKey = GlobalKey();
  void listener() {
    (_sortKey.currentContext as Element?)?.markNeedsBuild();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: LaterViewType.values.length,
      vsync: this,
    )..addListener(listener);
  }

  @override
  void dispose() {
    _tabController
      ..removeListener(listener)
      ..dispose();
    Get.delete<LaterBaseController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () {
        final enableMultiSelect = _baseCtr.enableMultiSelect.value;
        final tabView = TabBarView<CustomHorizontalDragGestureRecognizer>(
          physics: enableMultiSelect
              ? const NeverScrollableScrollPhysics()
              : clampingScrollPhysics,
          controller: _tabController,
          horizontalDragGestureRecognizer:
              CustomHorizontalDragGestureRecognizer.new,
          children: LaterViewType.values.map((item) => item.page).toList(),
        );
        if (WindowsVideoTabService.enabled && !enableMultiSelect) {
          return popScope(
            canPop: true,
            onPopInvokedWithResult: (_, _) {},
            child: WindowsNeoPage(
              title: '\u7a0d\u540e\u518d\u770b',
              subtitle:
                  '\u628a\u60f3\u770b\u7684\u5185\u5bb9\u7559\u5728\u624b\u8fb9',
              leading: Icon(
                Icons.watch_later_outlined,
                color: context.windowsNeo.accent,
              ),
              actions: _windowsHeaderActions(),
              commandBar: _buildTabs(false),
              child: Stack(
                children: [
                  ViewSafeArea(child: tabView),
                  Positioned(
                    right: 18,
                    bottom: 18,
                    child: _buildPlayAllFab(),
                  ),
                ],
              ),
            ),
          );
        }
        return popScope(
          canPop: !enableMultiSelect,
          onPopInvokedWithResult: (didPop, result) {
            if (enableMultiSelect) {
              currCtr().handleSelect();
            }
          },
          child: Scaffold(
            backgroundColor: WindowsVideoTabService.enabled
                ? context.windowsNeo.background
                : null,
            resizeToAvoidBottomInset: false,
            appBar: _buildAppbar(enableMultiSelect),
            floatingActionButtonLocation: const NoRightMarginFabLocation(),
            floatingActionButton: Padding(
              padding: const .only(right: kFloatingActionButtonMargin),
              child: Obx(
                () => currCtr().loadingState.value.isSuccess
                    ? AnimatedSlide(
                        offset: _baseCtr.isPlayAll.value
                            ? Offset.zero
                            : const Offset(0.75, 0),
                        duration: const Duration(milliseconds: 120),
                        child: GestureDetector(
                          onHorizontalDragDown: (details) =>
                              _baseCtr.dx = details.localPosition.dx,
                          onHorizontalDragStart: (details) =>
                              _baseCtr.setIsPlayAll(
                                details.localPosition.dx < _baseCtr.dx,
                              ),
                          child: FloatingActionButton.extended(
                            onPressed: () {
                              if (_baseCtr.isPlayAll.value) {
                                currCtr().toViewPlayAll();
                              } else {
                                _baseCtr.setIsPlayAll(true);
                              }
                            },
                            label: const Text('播放全部'),
                            icon: const Icon(Icons.playlist_play),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
            body: ViewSafeArea(
              child: Column(
                children: [
                  _buildTabs(enableMultiSelect),
                  Expanded(child: tabView),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _windowsHeaderActions() => [
    IconButton(
      tooltip: '\u641c\u7d22\u7a0d\u540e\u518d\u770b',
      onPressed: () {
        final mid = Accounts.main.mid;
        Get.toNamed(
          '/laterSearch',
          arguments: {
            'type': 0,
            'mediaId': mid,
            'mid': mid,
            'title': '\u7a0d\u540e\u518d\u770b',
            'count': _baseCtr.counts[LaterViewType.all.index],
          },
        );
      },
      icon: const Icon(Icons.search_outlined),
    ),
    Builder(
      key: _sortKey,
      builder: (context) {
        final value = currCtr().asc.value;
        return StaticPopupMenuButton<bool>(
          initialValue: value,
          tooltip: '\u6392\u5e8f',
          onSelected: (value) => currCtr()
            ..asc.value = value
            ..onReload(),
          itemBuilder: (_) => [
            const PopupMenuItem(
              value: true,
              child: Text('\u6700\u65e9\u6dfb\u52a0'),
            ),
            const PopupMenuItem(
              value: false,
              child: Text('\u6700\u8fd1\u6dfb\u52a0'),
            ),
          ],
          icon: const Icon(Icons.sort_outlined),
        );
      },
    ),
    const SizedBox(width: 6),
  ];

  Widget _buildPlayAllFab() => Obx(
    () => currCtr().loadingState.value.isSuccess
        ? AnimatedSlide(
            offset: _baseCtr.isPlayAll.value
                ? Offset.zero
                : const Offset(0.75, 0),
            duration: const Duration(milliseconds: 120),
            child: GestureDetector(
              onHorizontalDragDown: (details) =>
                  _baseCtr.dx = details.localPosition.dx,
              onHorizontalDragStart: (details) => _baseCtr.setIsPlayAll(
                details.localPosition.dx < _baseCtr.dx,
              ),
              child: FloatingActionButton.extended(
                onPressed: () {
                  if (_baseCtr.isPlayAll.value) {
                    currCtr().toViewPlayAll();
                  } else {
                    _baseCtr.setIsPlayAll(true);
                  }
                },
                label: const Text('\u64ad\u653e\u5168\u90e8'),
                icon: const Icon(Icons.playlist_play),
              ),
            ),
          )
        : const SizedBox.shrink(),
  );

  Widget _buildTabs(bool enableMultiSelect) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final tabs = LaterViewType.values.map((item) {
      final count = _baseCtr.counts[item.index];
      return Tab(text: '${item.title}${count != -1 ? '($count)' : ''}');
    }).toList();
    void onTap(int _) {
      if (!_tabController.indexIsChanging) {
        currCtr().scrollController.animToTop();
      } else if (enableMultiSelect) {
        currCtr(_tabController.previousIndex).handleSelect();
      }
    }

    if (isWindowsNeo) {
      return WindowsNeoSectionTabs(
        controller: _tabController,
        tabs: tabs,
        onTap: onTap,
      );
    }
    return TabBar(controller: _tabController, tabs: tabs, onTap: onTap);
  }

  PreferredSizeWidget _buildAppbar(bool enableMultiSelect) {
    final theme = Theme.of(context);
    Color color = theme.colorScheme.secondary;
    final btnStyle = TextButton.styleFrom(visualDensity: .compact);
    final textStyle = TextStyle(color: theme.colorScheme.onSurfaceVariant);
    return MultiSelectAppBarWidget(
      visible: enableMultiSelect,
      ctr: currCtr(),
      actions: [
        TextButton(
          style: btnStyle,
          onPressed: () {
            final ctr = currCtr();
            RequestUtils.onCopyOrMove<LaterItemModel>(
              context: context,
              isCopy: true,
              ctr: ctr,
              mediaId: null,
              mid: ctr.mid,
            );
          },
          child: Text('复制', style: textStyle),
        ),
        TextButton(
          style: btnStyle,
          onPressed: () {
            final ctr = currCtr();
            RequestUtils.onCopyOrMove<LaterItemModel>(
              context: context,
              isCopy: false,
              ctr: ctr,
              mediaId: null,
              mid: ctr.mid,
            );
          },
          child: Text('移动', style: textStyle),
        ),
      ],
      child: AppBar(
        title: const Text('稍后再看'),
        actions: [
          IconButton(
            tooltip: '搜索',
            onPressed: () {
              final mid = Accounts.main.mid;
              Get.toNamed(
                '/laterSearch',
                arguments: {
                  'type': 0,
                  'mediaId': mid,
                  'mid': mid,
                  'title': '稍后再看',
                  'count': _baseCtr.counts[LaterViewType.all.index],
                },
              );
            },
            icon: const Icon(Icons.search),
          ),
          Builder(
            key: _sortKey,
            builder: (context) {
              final value = currCtr().asc.value;
              return StaticPopupMenuButton(
                initialValue: value,
                tooltip: '排序',
                onSelected: (value) => currCtr()
                  ..asc.value = value
                  ..onReload(),
                borderRadius: const .all(.circular(20)),
                child: Padding(
                  padding: const .symmetric(horizontal: 12, vertical: 6),
                  child: Text.rich(
                    style: TextStyle(fontSize: 14, height: 1, color: color),
                    strutStyle: const StrutStyle(
                      leading: 0,
                      height: 1,
                      fontSize: 14,
                    ),
                    TextSpan(
                      children: [
                        TextSpan(text: value ? '最早添加' : '最近添加'),
                        WidgetSpan(
                          alignment: .middle,
                          child: Icon(
                            size: 14,
                            MdiIcons.unfoldMoreHorizontal,
                            color: color,
                          ),
                        ),
                      ],
                      style: TextStyle(color: color),
                    ),
                  ),
                ),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: false,
                    child: Text('最近添加'),
                  ),
                  const PopupMenuItem(
                    value: true,
                    child: Text('最早添加'),
                  ),
                ],
              );
            },
          ),
          StaticPopupMenuButton(
            tooltip: '清空',
            borderRadius: const .all(.circular(20)),
            child: Padding(
              padding: const .symmetric(horizontal: 12, vertical: 6),
              child: Text.rich(
                style: TextStyle(fontSize: 14, height: 1, color: color),
                strutStyle: const StrutStyle(
                  leading: 0,
                  height: 1,
                  fontSize: 14,
                ),
                TextSpan(
                  children: [
                    const TextSpan(text: '清空'),
                    WidgetSpan(
                      alignment: .middle,
                      child: Icon(
                        size: 14,
                        MdiIcons.unfoldMoreHorizontal,
                        color: color,
                      ),
                    ),
                  ],
                  style: TextStyle(color: color),
                ),
              ),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                onTap: () => currCtr().toViewClear(context, 1),
                child: const Text('清空失效'),
              ),
              PopupMenuItem(
                onTap: () => currCtr().toViewClear(context, 2),
                child: const Text('清空看完'),
              ),
              PopupMenuItem(
                onTap: () => currCtr().toViewClear(context),
                child: const Text('清空全部'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
