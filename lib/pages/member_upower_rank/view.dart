import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/keep_alive_wrapper.dart';
import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/image_type.dart';
import 'package:PiliPlus/models_new/upower_rank/rank_info.dart';
import 'package:PiliPlus/pages/member_upower_rank/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/widget_ext.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart' hide ListTile;
import 'package:get/get.dart';

class UpowerRankPage extends StatefulWidget {
  const UpowerRankPage({
    super.key,
    this.privilegeType,
  });

  final int? privilegeType;

  @override
  State<UpowerRankPage> createState() => _UpowerRankPageState();

  static Future<void>? toUpowerRank({
    required Object mid,
    required String name,
    required Object? count,
  }) {
    return Get.toNamed(
      '/upowerRank',
      arguments: {
        'mid': mid,
        'name': name,
        'count': count,
      },
    );
  }
}

class _UpowerRankPageState extends State<UpowerRankPage>
    with AutomaticKeepAliveClientMixin {
  String? _name;
  Object? _count;
  late final String _upMid;
  late final UpowerRankController _controller;

  @override
  void initState() {
    super.initState();
    final params = Get.arguments;
    _upMid = params['mid']!.toString();
    if (widget.privilegeType == null) {
      _name = params['name'];
      _count = params['count'];
    }
    _controller = Get.put(
      UpowerRankController(
        privilegeType: widget.privilegeType,
        upMid: _upMid,
      ),
      tag: '$_upMid${widget.privilegeType}',
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final padding = MediaQuery.viewPaddingOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final child = refreshIndicator(
      onRefresh: _controller.onRefresh,
      child: CustomScrollView(
        controller: _controller.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              left: isWindowsNeo ? 18 : 0,
              top: isWindowsNeo ? 16 : 0,
              right: isWindowsNeo ? 18 : 0,
              bottom: padding.bottom + 100,
            ),
            sliver: Obx(
              () => _buildBody(theme, _controller.loadingState.value),
            ),
          ),
        ],
      ),
    );
    if (widget.privilegeType == null) {
      return Scaffold(
        backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: Text('$_name的充电排行榜${_count == null ? '' : '($_count)'}'),
          actions: [
            if (isWindowsNeo)
              IconButton(
                tooltip: '充电',
                onPressed: _openCharge,
                icon: const Icon(Icons.bolt_outlined),
              )
            else
              TextButton(
                onPressed: _openCharge,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('充电'),
              ),
            const SizedBox(width: 12),
          ],
        ),
        body:
            Padding(
              padding: EdgeInsets.only(
                left: isWindowsNeo ? 0 : padding.left,
                right: isWindowsNeo ? 0 : padding.right,
              ),
              child: Obx(
                () {
                  final tabs = _controller.tabs.value;
                  return tabs != null
                      ? DefaultTabController(
                          length: tabs.length,
                          child: Builder(
                            builder: (context) {
                              final tabBar = TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                tabs: tabs
                                    .map(
                                      (e) => Tab(
                                        text:
                                            '${e.name!}(${e.memberTotal ?? 0})',
                                      ),
                                    )
                                    .toList(),
                                dividerColor: isWindowsNeo
                                    ? Colors.transparent
                                    : null,
                                dividerHeight: isWindowsNeo ? 0 : null,
                                indicatorSize: isWindowsNeo
                                    ? TabBarIndicatorSize.label
                                    : TabBarIndicatorSize.tab,
                                indicator: isWindowsNeo
                                    ? UnderlineTabIndicator(
                                        borderSide: BorderSide(
                                          color: context.windowsNeo.accent,
                                          width: 2.5,
                                        ),
                                      )
                                    : null,
                                unselectedLabelColor: isWindowsNeo
                                    ? context.windowsNeo.muted
                                    : null,
                                onTap: (index) {
                                  if (!DefaultTabController.of(
                                    context,
                                  ).indexIsChanging) {
                                    try {
                                      if (index == 0) {
                                        _controller.animateToTop();
                                      } else {
                                        Get.find<UpowerRankController>(
                                          tag:
                                              '$_upMid${tabs[index].privilegeType}',
                                        ).animateToTop();
                                      }
                                    } catch (_) {}
                                  }
                                },
                              );
                              return Column(
                                children: [
                                  if (isWindowsNeo)
                                    Container(
                                      height: 48,
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 18,
                                      ),
                                      decoration: BoxDecoration(
                                        color: context.windowsNeo.surface,
                                        border: Border(
                                          bottom: BorderSide(
                                            color: context.windowsNeo.border,
                                          ),
                                        ),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: tabBar,
                                    )
                                  else
                                    tabBar,
                                  Expanded(
                                    child: tabBarView(
                                      children: [
                                        KeepAliveWrapper(child: child),
                                        ...tabs
                                            .skip(1)
                                            .map(
                                              (e) => UpowerRankPage(
                                                privilegeType: e.privilegeType,
                                              ),
                                            ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        )
                      : child;
                },
              ),
            ).constraintWidth(
              constraints: BoxConstraints(maxWidth: isWindowsNeo ? 820 : 625),
            ),
      );
    } else {
      return child;
    }
  }

  Widget _buildBody(
    ThemeData theme,
    LoadingState<List<UpowerRankInfo>?> loadingState,
  ) {
    late final width = MediaQuery.textScalerOf(context).scale(32);
    return switch (loadingState) {
      Loading() => const SliverFillRemaining(child: m3eLoading),
      Success<List<UpowerRankInfo>?>(:final response) =>
        response != null && response.isNotEmpty
            ? SliverList.separated(
                itemCount: response.length,
                itemBuilder: (context, index) {
                  if (index == response.length - 1) {
                    _controller.onLoadMore();
                  }
                  final item = response[index];
                  return Material(
                    type: WindowsVideoTabService.enabled
                        ? MaterialType.canvas
                        : MaterialType.transparency,
                    color: WindowsVideoTabService.enabled
                        ? context.windowsNeo.surface
                        : null,
                    child: ListTile(
                      onTap: () => PageUtils.toMember(item.mid),
                      leading: SizedBox(
                        width: width,
                        child: Center(
                          child: Text(
                            (index + 1).toString(),
                            style: TextStyle(
                              fontSize: 16,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
                              color: switch (index) {
                                0 => const Color(0xFFfdad13),
                                1 => const Color(0xFF8aace1),
                                2 => const Color(0xFFdfa777),
                                _ => theme.colorScheme.outline,
                              },
                            ),
                          ),
                        ),
                      ),
                      title: Row(
                        spacing: 12,
                        children: [
                          NetworkImgLayer(
                            width: 38,
                            height: 38,
                            src: item.avatar,
                            type: ImageType.avatar,
                          ),
                          Text(
                            item.nickname!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                      trailing: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: item.day!.toString(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const TextSpan(
                              text: ' 天',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, _) => WindowsVideoTabService.enabled
                    ? Divider(height: 1, color: context.windowsNeo.border)
                    : const SizedBox.shrink(),
              )
            : HttpError(onReload: _controller.onReload),
      Error(:final errMsg) => HttpError(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  @override
  bool get wantKeepAlive => widget.privilegeType != null;

  void _openCharge() => Get.toNamed(
    '/webview',
    parameters: {
      'url':
          'https://member.bilibili.com/mall/upower-pay?mid=$_upMid&oid=$_upMid',
    },
  );
}
