import 'dart:math' show max;

import 'package:PiliPlus/common/skeleton/msg_feed_top.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models_new/blacklist/list.dart';
import 'package:PiliPlus/pages/blacklist/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/date_utils.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BlackListPage extends StatefulWidget {
  const BlackListPage({super.key});

  @override
  State<BlackListPage> createState() => _BlackListPageState();
}

class _BlackListPageState extends State<BlackListPage> {
  final _blackListController = Get.put(BlackListController());

  @override
  void dispose() {
    if (_blackListController.loadingState.value case Success(:final response)) {
      final blackMids = response?.map((e) => e.mid!).toSet() ?? {};
      GlobalData().blackMids = blackMids;
      Pref.blackMids = blackMids;
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final horizontalPadding = max(
      18.0,
      (MediaQuery.sizeOf(context).width - 820) / 2,
    );
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Obx(
          () => Text(
            '黑名单管理${_blackListController.total.value == -1 ? '' : ': ${_blackListController.total.value}'}',
          ),
        ),
      ),
      body: refreshIndicator(
        onRefresh: _blackListController.onRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          controller: _blackListController.scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                left: isWindowsNeo ? horizontalPadding : 0,
                top: isWindowsNeo ? 16 : 0,
                right: isWindowsNeo ? horizontalPadding : 0,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
              ),
              sliver: Obx(
                () => _buildBody(_blackListController.loadingState.value),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(LoadingState<List<BlackListItem>?> loadingState) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    late final style = TextStyle(color: Theme.of(context).colorScheme.outline);
    return switch (loadingState) {
      Loading() => SliverList.builder(
        itemCount: 12,
        itemBuilder: (context, index) => const MsgFeedTopSkeleton(),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverList.separated(
                itemCount: response.length,
                itemBuilder: (BuildContext context, int index) {
                  if (index == response.length - 1) {
                    _blackListController.onLoadMore();
                  }
                  final item = response[index];
                  final child = ListTile(
                    visualDensity: .standard,
                    onTap: () => PageUtils.toMember(item.mid),
                    leading: NetworkImgLayer(
                      width: 45,
                      height: 45,
                      type: ImageType.avatar,
                      src: item.face,
                    ),
                    title: Text(
                      item.uname!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '添加时间: ${DateFormatUtils.format(item.mtime, format: DateFormatUtils.longFormatDs)}',
                      maxLines: 1,
                      style: style,
                      overflow: TextOverflow.ellipsis,
                    ),
                    dense: true,
                    trailing: isWindowsNeo
                        ? IconButton(
                            tooltip: '移出黑名单',
                            onPressed: () => _blackListController.onRemove(
                              context,
                              index,
                              item.uname,
                              item.mid,
                            ),
                            icon: const Icon(Icons.person_remove_outlined),
                          )
                        : TextButton(
                            onPressed: () => _blackListController.onRemove(
                              context,
                              index,
                              item.uname,
                              item.mid,
                            ),
                            child: const Text('移除'),
                          ),
                  );
                  if (!isWindowsNeo) return child;
                  return Material(
                    color: context.windowsNeo.surface,
                    child: child,
                  );
                },
                separatorBuilder: (_, _) => isWindowsNeo
                    ? Divider(height: 1, color: context.windowsNeo.border)
                    : const SizedBox.shrink(),
              )
            : HttpError(onReload: _blackListController.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _blackListController.onReload,
      ),
    };
  }
}
