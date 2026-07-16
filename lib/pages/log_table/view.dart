import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/log_table/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/widget_ext.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LogPage<T> extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage<T>> createState() => _LogPageState<T>();
}

class _LogPageState<T> extends State<LogPage<T>> {
  final _controller = Get.put<LogController<dynamic, T>>(Get.arguments);

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.viewPaddingOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(_controller.title)),
      body:
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: EdgeInsets.only(
                  left: isWindowsNeo ? 18 : 10 + padding.left,
                  top: isWindowsNeo ? 16 : 0,
                  right: isWindowsNeo ? 18 : 10 + padding.right,
                  bottom: padding.bottom + 100,
                ),
                sliver: Obx(() => _buildBody(_controller.loadingState.value)),
              ),
            ],
          ).constraintWidth(
            constraints: BoxConstraints(maxWidth: isWindowsNeo ? 996 : 680),
          ),
    );
  }

  Widget _buildBody(LoadingState<List<T>?> loadingState) {
    return switch (loadingState) {
      Loading() => linearLoading,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? Builder(
                builder: (context) {
                  final them = Theme.of(context);
                  final outline = WindowsVideoTabService.enabled
                      ? context.windowsNeo.border
                      : them.colorScheme.outline.withValues(alpha: 0.1);
                  final divider = Divider(
                    height: 1,
                    color: outline,
                  );
                  final sliverDivider = SliverToBoxAdapter(
                    child: divider,
                  );
                  final dividerV = VerticalDivider(
                    width: 1,
                    color: outline,
                  );
                  return SliverMainAxisGroup(
                    slivers: [
                      sliverDivider,
                      SliverToBoxAdapter(
                        child: ColoredBox(
                          color: WindowsVideoTabService.enabled
                              ? context.windowsNeo.surfaceRaised
                              : them.colorScheme.onInverseSurface,
                          child: _item(
                            _controller.header,
                            dividerV,
                            isHeader: true,
                          ),
                        ),
                      ),
                      sliverDivider,
                      SliverList.separated(
                        itemCount: response.length,
                        itemBuilder: (context, index) {
                          return _item(response[index], dividerV);
                        },
                        separatorBuilder: (context, index) => divider,
                      ),
                      sliverDivider,
                    ],
                  );
                },
              )
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  Widget _item(T item, Widget divider, {bool isHeader = false}) {
    Widget text(int flex, String text) => Expanded(
      flex: flex,
      child: Padding(
        padding: isHeader
            ? const EdgeInsets.symmetric(vertical: 6)
            : const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: isHeader
                ? const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)
                : const TextStyle(fontSize: 13),
          ),
        ),
      ),
    );

    Widget content = Row(
      children: [
        divider,
        for (final (i, j) in _controller.getFlexAndText(item)) ...[
          text(i, j),
          divider,
        ],
      ],
    );
    return IntrinsicHeight(
      child: isHeader ? content : SelectionArea(child: content),
    );
  }
}
