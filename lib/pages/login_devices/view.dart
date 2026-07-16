import 'dart:math' show max;

import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/view_sliver_safe_area.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models_new/login_devices/device.dart';
import 'package:PiliPlus/pages/login_devices/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart' hide ListTile;
import 'package:get/get.dart';

class LoginDevicesPage extends StatefulWidget {
  const LoginDevicesPage({super.key});

  @override
  State<LoginDevicesPage> createState() => LoginDevicesPageState();
}

class LoginDevicesPageState extends State<LoginDevicesPage> {
  final _controller = Get.put(LoginDevicesController());

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final horizontalPadding = max(
      18.0,
      (MediaQuery.sizeOf(context).width - 820) / 2,
    );
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('登录设备')),
      body: refreshIndicator(
        onRefresh: _controller.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (isWindowsNeo)
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  16,
                  horizontalPadding,
                  MediaQuery.viewPaddingOf(context).bottom + 100,
                ),
                sliver: Obx(
                  () => _buildBody(
                    colorScheme,
                    _controller.loadingState.value,
                  ),
                ),
              )
            else
              ViewSliverSafeArea(
                sliver: Obx(
                  () => _buildBody(
                    colorScheme,
                    _controller.loadingState.value,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    ColorScheme colorScheme,
    LoadingState<List<LoginDevice>?> loadingState,
  ) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final divider = Divider(
      height: 1,
      color: isWindowsNeo
          ? context.windowsNeo.border
          : colorScheme.outline.withValues(alpha: 0.1),
    );
    return switch (loadingState) {
      Loading() => const SliverToBoxAdapter(),
      Success<List<LoginDevice>?>(:final response) =>
        response != null && response.isNotEmpty
            ? SliverList.separated(
                itemBuilder: (context, index) {
                  final child = _buildItem(colorScheme, response[index]);
                  if (!isWindowsNeo) return child;
                  return Material(
                    color: context.windowsNeo.surface,
                    child: child,
                  );
                },
                itemCount: response.length,
                separatorBuilder: (_, _) => divider,
              )
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  Widget _buildItem(ColorScheme colorScheme, LoginDevice item) {
    final style = TextStyle(fontSize: 13, color: colorScheme.outline);
    return ListTile(
      dense: true,
      visualDensity: WindowsVideoTabService.enabled
          ? VisualDensity.standard
          : null,
      title: Text(
        item.deviceName ?? '',
        style: const TextStyle(fontSize: 14),
      ),
      subtitle: Text(
        '${item.latestLoginAt} ${item.source}',
        style: style,
      ),
      trailing: item.isCurrentDevice == true
          ? Text('(本机)', style: style)
          : null,
    );
  }
}
