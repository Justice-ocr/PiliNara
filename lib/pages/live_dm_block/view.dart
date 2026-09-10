import 'dart:math' show max, min;

import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/common/widgets/keep_alive_wrapper.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/sliver/sliver_pinned_header.dart';
import 'package:PiliPlus/models/common/live/live_dm_silent_type.dart';
import 'package:PiliPlus/models_new/live/live_dm_block/shield_user_list.dart';
import 'package:PiliPlus/pages/live_dm_block/controller.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:extended_nested_scroll_view/extended_nested_scroll_view.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:get/get.dart';

class LiveDmBlockPage extends StatefulWidget {
  const LiveDmBlockPage({super.key});

  @override
  State<LiveDmBlockPage> createState() => _LiveDmBlockPageState();
}

class _LiveDmBlockPageState extends State<LiveDmBlockPage> {
  final _controller = Get.put(
    LiveDmBlockController(),
    tag: Utils.generateRandomString(8),
  );
  late EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final isPortrait = isWindowsNeo ? size.width < 760 : size.isPortrait;
    final theme = Theme.of(context);
    padding = MediaQuery.viewPaddingOf(context);
    Widget tabBar = TabBar(
      isScrollable: isWindowsNeo,
      tabAlignment: isWindowsNeo ? TabAlignment.start : null,
      dividerColor: isWindowsNeo ? context.windowsNeo.border : null,
      controller: _controller.tabController,
      tabs: const [
        Tab(text: '关键词'),
        Tab(text: '用户'),
      ],
    );

    Widget view = tabBarView(
      controller: _controller.tabController,
      children: [
        KeepAliveWrapper(
          child: Obx(() => _buildKeyword(_controller.keywordList)),
        ),
        KeepAliveWrapper(
          child: Obx(() => _buildKeyword(_controller.shieldUserList)),
        ),
      ],
    );

    Widget title = Padding(
      padding: EdgeInsets.only(
        top: isPortrait ? 18 : 0,
        left: isPortrait ? 0 : 12,
        bottom: 12,
      ),
      child: const Text(
        '关键词屏蔽',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
      ),
    );

    Widget left = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '直播屏蔽规则',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text('添加关键词或用户后，匹配的消息将不再显示在直播聊天中。'),
          if (isPortrait) title,
        ],
      ),
    );

    Widget content = Stack(
      clipBehavior: Clip.none,
      children: [
        isPortrait
            ? ExtendedNestedScrollView(
                onlyOneScrollInBody: true,
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverToBoxAdapter(child: left),
                    SliverOverlapAbsorber(
                      handle:
                          ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(
                            context,
                          ),
                      sliver: SliverPinnedHeader(child: tabBar),
                    ),
                  ];
                },
                body: LayoutBuilder(
                  builder: (context, _) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top:
                            ExtendedNestedScrollView.sliverOverlapAbsorberHandleFor(
                              context,
                            ).layoutExtent ??
                            0,
                      ),
                      child: view,
                    );
                  },
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: left),
                  VerticalDivider(
                    width: 1,
                    color: isWindowsNeo
                        ? context.windowsNeo.border
                        : theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        title,
                        tabBar,
                        Expanded(child: view),
                      ],
                    ),
                  ),
                ],
              ),
        Positioned(
          right: kFloatingActionButtonMargin,
          bottom: kFloatingActionButtonMargin + padding.bottom,
          child: FloatingActionButton(
            tooltip: '添加',
            onPressed: _addShieldKeyword,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('弹幕屏蔽')),
      body: isWindowsNeo
          ? LayoutBuilder(
              builder: (context, constraints) => Center(
                child: SizedBox(
                  width: max(
                    0.0,
                    min(1100.0, constraints.maxWidth - 36),
                  ),
                  height: max(0.0, constraints.maxHeight - 32),
                  child: Material(
                    color: context.windowsNeo.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: context.windowsNeo.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: content,
                  ),
                ),
              ),
            )
          : Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                right: padding.right,
              ),
              child: content,
            ),
    );
  }

  Widget _buildKeyword(List list) {
    if (list.isEmpty) {
      return scrollableError;
    }
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        top: 12,
        left: 12,
        right: 12,
        bottom: padding.bottom + 100,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: list.indexed.map(
          (e) {
            final item = e.$2;
            return SearchText(
              text: item is ShieldUserList ? item.uname! : item as String,
              onTap: (value) => showConfirmDialog(
                context: context,
                title: const Text('确定删除该规则？'),
                onConfirm: () => _controller.onRemove(e.$1, item),
              ),
            );
          },
        ).toList(),
      ),
    );
  }

  void _addShieldKeyword() {
    bool isKeyword = _controller.tabController.index == 0;
    String value = '';
    showConfirmDialog(
      context: context,
      title: Text('${isKeyword ? '关键词' : '用户'}屏蔽'),
      content: TextFormField(
        autofocus: true,
        initialValue: value,
        onChanged: (val) => value = val,
        decoration: isKeyword ? null : const InputDecoration(hintText: 'UID'),
        keyboardType: isKeyword ? null : TextInputType.number,
        inputFormatters: isKeyword
            ? null
            : [FilteringTextInputFormatter.digitsOnly],
      ),
      onConfirm: () {
        if (value.isNotEmpty) {
          _controller.addShieldKeyword(isKeyword, value);
        }
      },
    );
  }
}
