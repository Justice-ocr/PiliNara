import 'package:PiliPlus/common/skeleton/whisper_item.dart';
import 'package:PiliPlus/common/widgets/flutter/popup_menu.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/whisper/controller.dart';
import 'package:PiliPlus/pages/whisper/widgets/item.dart';
import 'package:PiliPlus/pages/whisper_detail/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/extension/three_dot_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_resize_handle.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_state.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class WhisperPage extends StatefulWidget {
  const WhisperPage({super.key});

  @override
  State<WhisperPage> createState() => _WhisperPageState();
}

class _WhisperPageState extends State<WhisperPage> {
  final _controller = Get.put(WhisperController());
  Map<String, dynamic>? _selectedSessionArgs;
  double _listPaneWidth = 356;

  List<Widget> _buildHeaderActions(ThemeData theme) => [
    IconButton(
      tooltip: '新增粉丝',
      onPressed: () => PageUtils.toDupNamed(
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
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final headerActions = _buildHeaderActions(theme);

    if (isWindowsNeo) {
      final tokens = context.windowsNeo;
      return Scaffold(
        backgroundColor: tokens.background,
        resizeToAvoidBottomInset: false,
        body: WindowsNeoPage(
          title: '消息',
          subtitle: '私信会话与互动通知',
          leading: Icon(
            Icons.chat_bubble_outline,
            size: 20,
            color: tokens.chromeAccent,
          ),
          actions: headerActions,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dualPane = constraints.maxWidth >= 860;
              if (!dualPane) {
                return _buildSessionScrollView(
                  theme,
                  padding,
                  horizontalPadding: 20.0,
                  dualPane: false,
                );
              }
              final maxPaneWidth = (constraints.maxWidth * 0.48).clamp(
                320.0,
                480.0,
              );
              final paneWidth = _listPaneWidth.clamp(280.0, maxPaneWidth);
              final activeTalkerId = _selectedSessionArgs?['talkerId'] as int?;
              return Row(
                children: [
                  SizedBox(
                    width: paneWidth,
                    child: ColoredBox(
                      color: tokens.surface,
                      child: _buildSessionScrollView(
                        theme,
                        padding,
                        horizontalPadding: 10.0,
                        dualPane: true,
                      ),
                    ),
                  ),
                  WindowsNeoResizeHandle(
                    onDragDelta: (dx) => setState(
                      () => _listPaneWidth = (_listPaneWidth + dx).clamp(
                        280.0,
                        maxPaneWidth,
                      ),
                    ),
                    onReset: () => setState(() => _listPaneWidth = 356),
                  ),
                  Expanded(
                    child: _selectedSessionArgs != null && activeTalkerId != null
                        ? WhisperDetailPage(
                            key: ValueKey('whisper-pane-$activeTalkerId'),
                            arguments: _selectedSessionArgs,
                            controllerTag: 'whisper-embedded-$activeTalkerId',
                            embedded: true,
                          )
                        : const Center(
                            child: WindowsNeoState(
                              icon: Icons.forum_outlined,
                              title: '选择左侧会话开始聊天',
                              message: '可拖拽中轴调整会话列表宽度，右键会话可置顶或免打扰',
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('消息'),
        actions: headerActions,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) => _buildSessionScrollView(
          theme,
          padding,
          horizontalPadding: 0.0,
          dualPane: false,
        ),
      ),
    );
  }

  Widget _buildSessionScrollView(
    ThemeData theme,
    EdgeInsets padding, {
    required double horizontalPadding,
    required bool dualPane,
  }) {
    return refreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          _buildTopItems(
            theme,
            padding,
            horizontalPadding: horizontalPadding,
            compact: dualPane,
          ),
          SliverPadding(
            padding: EdgeInsets.only(
              left: horizontalPadding,
              right: horizontalPadding,
              bottom: padding.bottom + 100,
            ),
            sliver: Obx(
              () => _buildBody(
                _controller.loadingState.value,
                dualPane: dualPane,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    LoadingState<List<Session>?> loadingState, {
    required bool dualPane,
  }) {
    late final divider = Divider(
      indent: 72,
      endIndent: 20,
      height: 1,
      color: WindowsVideoTabService.enabled
          ? context.windowsNeo.border.withValues(alpha: 0.55)
          : Colors.grey.withValues(alpha: 0.1),
    );
    final activeTalkerId = _selectedSessionArgs?['talkerId'] as int?;
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
                  final talkerId = item.id.privateId.hasTalkerUid()
                      ? item.id.privateId.talkerUid.toInt()
                      : null;
                  return WhisperSessionItem(
                    item: item,
                    selected:
                        dualPane &&
                        talkerId != null &&
                        talkerId == activeTalkerId,
                    onOpenPrivate: dualPane
                        ? (args) => setState(() => _selectedSessionArgs = args)
                        : null,
                    onSetTop: (isTop, id) =>
                        _controller.onSetTop(item, index, isTop, id),
                    onSetMute: (isMuted, talkerUid) =>
                        _controller.onSetMute(item, isMuted, talkerUid),
                    onRemove: (talkerId) {
                      if (activeTalkerId == talkerId) {
                        setState(() => _selectedSessionArgs = null);
                      }
                      _controller.onRemove(index, talkerId);
                    },
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
    bool compact = false,
  }) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final tokens = isWindowsNeo ? context.windowsNeo : null;
    return SliverPadding(
      padding: EdgeInsets.only(
        left: isWindowsNeo ? horizontalPadding : padding.left,
        top: isWindowsNeo ? (compact ? 10 : 16) : 0,
        right: isWindowsNeo ? horizontalPadding : padding.right,
        bottom: isWindowsNeo ? (compact ? 10 : 14) : 0,
      ),
      sliver: SliverToBoxAdapter(
        child: Material(
          type: isWindowsNeo ? MaterialType.card : MaterialType.transparency,
          color: isWindowsNeo ? tokens!.surfaceRaised : null,
          elevation: 0,
          shape: isWindowsNeo
              ? RoundedRectangleBorder(
                  borderRadius: tokens!.cardRadius,
                  side: BorderSide(
                    color: tokens.border.withValues(alpha: 0.6),
                  ),
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
                PageUtils.toDupNamed(item.route);
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
                  hoverColor: tokens!.hover,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 4 : 12,
                      vertical: compact ? 9 : 12,
                    ),
                    child: compact
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(
                                () => _buildWindowsTopIcon(index, item.icon),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: tokens.ink,
                                ),
                              ),
                            ],
                          )
                        : Row(
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
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: tokens.ink,
                                  ),
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
    final tokens = context.windowsNeo;
    final count = _controller.unreadCounts[index];
    return Badge(
      isLabelVisible: count > 0,
      label: Text(" $count "),
      alignment: Alignment.topRight,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: tokens.accentSurface,
          borderRadius: tokens.mediaBadgeRadius,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 17, color: tokens.accentInk),
      ),
    );
  }
}
