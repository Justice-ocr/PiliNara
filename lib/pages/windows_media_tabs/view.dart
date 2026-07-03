import 'package:PiliPlus/pages/live_room/view.dart';
import 'package:PiliPlus/pages/video/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WindowsMediaTabsPage extends StatefulWidget {
  const WindowsMediaTabsPage({super.key});

  @override
  State<WindowsMediaTabsPage> createState() => _WindowsMediaTabsPageState();
}

class _WindowsMediaTabsPageState extends State<WindowsMediaTabsPage> {
  final Map<String, GlobalKey<NavigatorState>> _navigatorKeys = {};

  @override
  void initState() {
    super.initState();
    WindowsVideoTabService.setHostMounted(true);
  }

  @override
  void dispose() {
    WindowsVideoTabService.setHostMounted(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabs = WindowsVideoTabService.tabs.toList(growable: false);
      if (tabs.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });
        return const Scaffold(body: SizedBox.shrink());
      }

      final ids = tabs.map((item) => item.id).toSet();
      _navigatorKeys.removeWhere((id, _) => !ids.contains(id));

      var activeIndex = tabs.indexWhere(
        (item) => item.id == WindowsVideoTabService.activeId.value,
      );
      if (activeIndex == -1) {
        activeIndex = tabs.length - 1;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && tabs.isNotEmpty) {
            WindowsVideoTabService.select(tabs[activeIndex].id);
          }
        });
      }

      return Scaffold(
        body: Column(
          children: [
            const WindowsMediaTabBar(),
            Expanded(
              child: IndexedStack(
                index: activeIndex,
                children: [
                  for (final item in tabs) _buildTabNavigator(item),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabNavigator(WindowsVideoTabItem item) {
    final key = _navigatorKeys.putIfAbsent(
      item.id,
      () => GlobalKey<NavigatorState>(),
    );
    return Navigator(
      key: key,
      onGenerateRoute: (_) => GetPageRoute(
        settings: RouteSettings(
          name: item.type == WindowsMediaTabType.live ? '/liveRoom' : '/videoV',
          arguments: item.arguments,
        ),
        page: () => item.type == WindowsMediaTabType.live
            ? LiveRoomPage(arguments: item.arguments)
            : VideoDetailPageV(arguments: item.arguments),
      ),
    );
  }
}
