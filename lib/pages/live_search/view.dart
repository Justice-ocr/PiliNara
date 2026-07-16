import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/models/common/live/live_search_type.dart';
import 'package:PiliPlus/pages/live_search/child/view.dart';
import 'package:PiliPlus/pages/live_search/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LiveSearchPage extends StatefulWidget {
  const LiveSearchPage({super.key});

  @override
  State<LiveSearchPage> createState() => _LiveSearchPageState();
}

class _LiveSearchPageState extends State<LiveSearchPage> {
  final _controller = Get.put(
    LiveSearchController(),
    tag: Utils.generateRandomString(8),
  );

  @override
  Widget build(BuildContext context) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final content = Obx(() {
      return Opacity(
        opacity: _controller.hasData.value ? 1 : 0,
        child: Column(
          children: [
            TabBar(
              isScrollable: isWindowsNeo,
              tabAlignment: isWindowsNeo ? TabAlignment.start : null,
              dividerColor: isWindowsNeo ? context.windowsNeo.border : null,
              controller: _controller.tabController,
              tabs: [
                Obx(
                  () => Tab(
                    text:
                        '正在直播 ${_controller.counts[0] != -1 ? _controller.counts[0] : ''}',
                  ),
                ),
                Obx(
                  () => Tab(
                    text:
                        '主播 ${_controller.counts[1] != -1 ? _controller.counts[1] : ''}',
                  ),
                ),
              ],
              onTap: (index) {
                if (!_controller.tabController.indexIsChanging) {
                  if (index == 0) {
                    _controller.roomCtr.animateToTop();
                  } else {
                    _controller.userCtr.animateToTop();
                  }
                }
              },
            ),
            Expanded(
              child: tabBarView(
                controller: _controller.tabController,
                children: [
                  LiveSearchChildPage(
                    controller: _controller.roomCtr,
                    searchType: LiveSearchType.room,
                  ),
                  LiveSearchChildPage(
                    controller: _controller.userCtr,
                    searchType: LiveSearchType.user,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: '搜索',
            onPressed: _controller.submit,
            icon: const Icon(Icons.search, size: 22),
          ),
          const SizedBox(width: 10),
        ],
        title: TextField(
          autofocus: true,
          focusNode: _controller.focusNode,
          controller: _controller.editingController,
          textInputAction: TextInputAction.search,
          textAlignVertical: TextAlignVertical.center,
          decoration: InputDecoration(
            hintText: '搜索房间或主播',
            visualDensity: .standard,
            border: InputBorder.none,
            suffixIcon: IconButton(
              tooltip: '清空',
              icon: const Icon(Icons.clear, size: 22),
              onPressed: _controller.onClear,
            ),
          ),
          onSubmitted: (value) => _controller.submit(),
          onChanged: (value) {
            if (value.isEmpty) {
              _controller.hasData.value = false;
            }
          },
        ),
      ),
      body: isWindowsNeo
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Center(
                child: SizedBox(width: 1100, child: content),
              ),
            )
          : ViewSafeArea(child: content),
    );
  }
}
