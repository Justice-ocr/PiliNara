import 'package:PiliPlus/common/skeleton/whisper_item.dart';
import 'package:PiliPlus/common/widgets/flutter/popup_menu.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/whisper/widgets/item.dart';
import 'package:PiliPlus/pages/whisper_secondary/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/three_dot_ext.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WhisperSecPage extends StatefulWidget {
  const WhisperSecPage({
    super.key,
    required this.name,
    required this.sessionPageType,
  });

  final String name;
  final SessionPageType sessionPageType;

  @override
  State<WhisperSecPage> createState() => _WhisperSecPageState();
}

class _WhisperSecPageState extends State<WhisperSecPage> {
  late final WhisperSecController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      WhisperSecController(sessionPageType: widget.sessionPageType),
      tag: widget.sessionPageType.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WindowsVideoTabService.enabled
          ? context.windowsNeo.background
          : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
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
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWindowsNeo = WindowsVideoTabService.enabled;
          final horizontal = isWindowsNeo && constraints.maxWidth > 1000
              ? (constraints.maxWidth - 960) / 2
              : isWindowsNeo
              ? 20.0
              : 0.0;
          return refreshIndicator(
            onRefresh: _controller.onRefresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(
                    left: horizontal,
                    top: isWindowsNeo ? 16 : 0,
                    right: horizontal,
                    bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
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
                    onSetTop: (isTop, talkerId) =>
                        _controller.onSetTop(item, index, isTop, talkerId),
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
}
