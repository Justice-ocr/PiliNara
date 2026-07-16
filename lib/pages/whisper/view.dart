import 'package:PiliPlus/common/skeleton/whisper_item.dart';
import 'package:PiliPlus/common/widgets/flutter/popup_menu.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/whisper/controller.dart';
import 'package:PiliPlus/pages/whisper/widgets/item.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/extension/three_dot_ext.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class WhisperPage extends StatefulWidget {
  const WhisperPage({super.key});

  @override
  State<WhisperPage> createState() => _WhisperPageState();
}

class _WhisperPageState extends State<WhisperPage> {
  final _controller = Get.put(WhisperController());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('消息'),
        actions: [
          IconButton(
            tooltip: '新增粉丝',
            onPressed: () => Get.toNamed(
              '/webview',
              parameters: {
                'url':
                    'https://www.bilibili.com/h5/follow/newFans?navhide=1&${ThemeUtils.themeUrl(theme.isDark)}',
              },
            ),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          Obx(() {
            final outsideItem = _controller.outsideItem.value;
            if (outsideItem != null && outsideItem.isNotEmpty) {
              return Row(
                mainAxisSize: .min,
                children: outsideItem.map((e) {
                  return IconButton(
                    tooltip: e.hasTitle() ? e.title : null,
                    onPressed: () => e.type.action(
                      context: context,
                      controller: _controller,
                      item: e,
                    ),
                    icon: e.type.icon,
                  );
                }).toList(),
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() {
            final threeDotItems = _controller.threeDotItems.value;
            if (threeDotItems != null && threeDotItems.isNotEmpty) {
              return StaticPopupMenuButton(
                itemBuilder: (context) {
                  return threeDotItems
                      .map(
                        (e) => PopupMenuItem(
                          onTap: () => e.type.action(
                            context: context,
                            controller: _controller,
                            item: e,
                          ),
                          child: Row(
                            children: [
                              e.type.icon,
                              Text('  ${e.title}'),
                            ],
                          ),
                        ),
                      )
                      .toList();
                },
              );
            }
            return const SizedBox.shrink();
          }),
          const SizedBox(width: 5),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final horizontalPadding = isWindowsNeo
              ? constraints.maxWidth > 1000
                    ? (constraints.maxWidth - 960) / 2
                    : 20.0
              : 0.0;
          return refreshIndicator(
            onRefresh: _controller.onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _buildTopItems(
                  theme,
                  padding,
                  horizontalPadding: horizontalPadding,
                ),
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: horizontalPadding,
                    right: horizontalPadding,
                    bottom: padding.bottom + 100,
                  ),
                  sliver: Obx(
                    () => _buildBody(_controller.loadingState.value),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(LoadingState<List<Session>?> loadingState) {
    late final divider = Divider(
      indent: 72,
      endIndent: 20,
      height: 1,
      color: WindowsVideoTabService.enabled
          ? context.windowsNeo.border
          : Colors.grey.withValues(alpha: 0.1),
    );
    return switch (loadingState) {
      Loading() => SliverList.builder(
        itemCount: 12,
        itemBuilder: (context, index) => const WhisperItemSkeleton(),
      ),
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? SliverList.separated(
                itemCount: response.length,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _controller.onLoadMore();
                  }
                  final item = response[index];
                  return WhisperSessionItem(
                    item: item,
                    onSetTop: (isTop, id) =>
                        _controller.onSetTop(item, index, isTop, id),
                    onSetMute: (isMuted, talkerUid) =>
                        _controller.onSetMute(item, isMuted, talkerUid),
                    onRemove: (talkerId) =>
                        _controller.onRemove(index, talkerId),
                  );
                },
                separatorBuilder: (context, index) => divider,
              )
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  Widget _buildTopItems(
    ThemeData theme,
    EdgeInsets padding, {
    required double horizontalPadding,
  }) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    return SliverPadding(
      padding: EdgeInsets.only(
        left: isWindowsNeo ? horizontalPadding : padding.left,
        top: isWindowsNeo ? 16 : 0,
        right: isWindowsNeo ? horizontalPadding : padding.right,
        bottom: isWindowsNeo ? 14 : 0,
      ),
      sliver: SliverToBoxAdapter(
        child: Material(
          type: isWindowsNeo ? MaterialType.card : MaterialType.transparency,
          color: isWindowsNeo ? context.windowsNeo.surface : null,
          elevation: 0,
          shape: isWindowsNeo
              ? RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: BorderSide(color: context.windowsNeo.border),
                )
              : null,
          clipBehavior: isWindowsNeo ? Clip.antiAlias : Clip.none,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(_controller.msgFeedTopItems.length, (
              index,
            ) {
              final item = _controller.msgFeedTopItems[index];
              void onTap() {
                if (!item.enabled) {
                  SmartDialog.showToast('已禁用');
                  return;
                }
                _controller.unreadCounts[index] = 0;
                Get.toNamed(item.route);
              }

              if (!isWindowsNeo) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Obx(
                          () {
                            final count = _controller.unreadCounts[index];
                            return Badge(
                              isLabelVisible: count > 0,
                              label: Text(" $count "),
                              alignment: Alignment.topRight,
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor:
                                    theme.colorScheme.onInverseSurface,
                                child: Icon(
                                  item.icon,
                                  size: 20,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Expanded(
                child: InkWell(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Obx(
                          () => _buildWindowsTopIcon(index, item.icon),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Text(
                            item.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowsTopIcon(int index, IconData icon) {
    final count = _controller.unreadCounts[index];
    return Badge(
      isLabelVisible: count > 0,
      label: Text(" $count "),
      alignment: Alignment.topRight,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: context.windowsNeo.accentSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: context.windowsNeo.accent),
      ),
    );
  }
}
