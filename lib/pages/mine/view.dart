import 'dart:async';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/flutter/refresh_indicator.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/player_bar.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/common/mine_tab_type.dart';
import 'package:PiliPlus/models/common/nav_bar_config.dart';
import 'package:PiliPlus/pages/common/common_page.dart';
import 'package:PiliPlus/pages/home/view.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/main/controller.dart';
import 'package:PiliPlus/pages/mine/controller.dart';
import 'package:PiliPlus/pages/mine/widgets/fav_item.dart';
import 'package:PiliPlus/pages/mine/widgets/history_item.dart';
import 'package:PiliPlus/pages/mine/widgets/later_item.dart';
import 'package:PiliPlus/pages/mine/widgets/sub_item.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_page.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_stage.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:material_ui/material_ui.dart' hide ListTile;

class MinePage extends StatefulWidget {
  const MinePage({super.key, this.showBackBtn = false});

  final bool showBackBtn;

  @override
  State<MinePage> createState() => _MediaPageState();
}

class _MediaPageState extends CommonPageState<MinePage>
    with AutomaticKeepAliveClientMixin {
  final MineController controller = Get.putOrFind(MineController.new);
  late final MainController _mainController = Get.find<MainController>();
  late ThemeData theme;

  @override
  bool get wantKeepAlive => true;

  bool get checkPage =>
      _mainController.navigationBars[0] != NavigationBarType.mine &&
      _mainController.selectedIndex.value == 0;

  @override
  bool onNotificationType1(UserScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType1(notification);
  }

  @override
  bool onNotificationType2(ScrollNotification notification) {
    if (checkPage) {
      return false;
    }
    return super.onNotificationType2(notification);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    theme = Theme.of(context);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final secondary = theme.colorScheme.secondary;
    if (WindowsVideoTabService.enabled) {
      return _buildWindowsPage(theme);
    }
    return Column(
      children: [
        Padding(
          padding: const .symmetric(vertical: 10),
          child: _buildHeaderActions,
        ),
        Expanded(
          child: Material(
            type: .transparency,
            child: refreshIndicator(
              key: controller.refreshKey,
              onRefresh: controller.onRefresh,
              child: onBuild(
                ListView(
                  controller: controller.scrollController,
                  padding: const .only(bottom: 150),
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    _buildUserInfo(theme, secondary),
                    _buildActions(secondary),
                    for (final tab in controller.mineTabs)
                      switch (tab) {
                        .favorite => Obx(_buildFav),
                        .history => Obx(_buildHistory),
                        .later => Obx(_buildLater),
                        .sub => Obx(_buildSub),
                      },
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWindowsPage(ThemeData theme) {
    final tokens = context.windowsNeo;
    return WindowsNeoPage(
      title: '\u6211\u7684',
      subtitle: '\u8d26\u6237\u3001\u6536\u85cf\u4e0e\u4e2a\u4eba\u5185\u5bb9',
      leading: widget.showBackBtn
          ? const BackButton()
          : Icon(Icons.person_outline, color: tokens.chromeAccent),
      actions: _windowsHeaderActions,
      stageMode: WindowsNeoStageMode.browse,
      stageScene: WindowsNeoStageScene.profile,
      child: refreshIndicator(
        onRefresh: controller.onRefresh,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
                      child: _buildWindowsProfileHero(theme),
                    ),
                    for (final tab in controller.mineTabs)
                      switch (tab) {
                        .favorite => Obx(_buildFav),
                        .history => Obx(_buildHistory),
                        .later => Obx(_buildLater),
                        .sub => Obx(_buildSub),
                      },
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowsProfileHero(ThemeData theme) {
    final tokens = context.windowsNeo;
    return Obx(() {
      final userInfo = controller.userInfo.value;
      final levelInfo = userInfo.levelInfo;
      final hasLevel = levelInfo != null && (levelInfo.nextExp ?? 0) > 0;
      final isVip = userInfo.vipStatus != null && userInfo.vipStatus! > 0;
      final userStat = controller.userStat.value;

      return DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.surface,
          borderRadius: tokens.cardRadius,
          border: Border.all(color: tokens.border.withValues(alpha: 0.48)),
          boxShadow: tokens.cardShadow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 680;
                  final profileRow = GestureDetector(
                    behavior: .opaque,
                    onTap: controller.onLogin,
                    onLongPress: () {
                      Feedback.forLongPress(context);
                      controller.onLogin(true);
                    },
                    onSecondaryTap: () => controller.onLogin(true),
                    child: Row(
                      children: [
                        userInfo.face != null
                            ? Stack(
                                clipBehavior: .none,
                                children: [
                                  NetworkImgLayer(
                                    src: userInfo.face,
                                    type: .avatar,
                                    width: 64,
                                    height: 64,
                                  ),
                                  if (isVip)
                                    Positioned(
                                      right: -1,
                                      bottom: -2,
                                      child: SvgPicture.asset(
                                        Assets.vipIcon,
                                        height: 20,
                                        semanticsLabel: '大会员',
                                      ),
                                    ),
                                ],
                              )
                            : ClipOval(
                                child: Image.asset(
                                  width: 64,
                                  height: 64,
                                  cacheHeight: 64.cacheSize(context),
                                  Assets.avatarPlaceHolder,
                                  semanticLabel: '默认头像',
                                ),
                              ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                spacing: 8,
                                children: [
                                  Flexible(
                                    child: Text(
                                      userInfo.uname ?? '点击登录',
                                      maxLines: 1,
                                      overflow: .ellipsis,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            height: 1.1,
                                            color:
                                                isVip && userInfo.vipType == 2
                                                ? theme.colorScheme.vipColor
                                                : tokens.ink,
                                          ),
                                    ),
                                  ),
                                  BiliUtils.levelPicture(
                                    levelInfo?.currentLevel ?? 0,
                                    isSeniorMember:
                                        userInfo.isSeniorMember == 1,
                                    height: 11,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text.rich(
                                TextSpan(
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: tokens.muted,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                  children: [
                                    const TextSpan(text: '硬币 '),
                                    TextSpan(
                                      text: userInfo.money?.toString() ?? '-',
                                      style: TextStyle(
                                        color: tokens.accentInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const TextSpan(text: '    经验 '),
                                    TextSpan(
                                      text:
                                          levelInfo?.currentExp?.toString() ??
                                          '-',
                                      style: TextStyle(
                                        color: tokens.accentInk,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '/${levelInfo?.nextExp ?? '-'}',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 260,
                                ),
                                child: ClipRRect(
                                  borderRadius: tokens.mediaBadgeRadius,
                                  child: LinearProgressIndicator(
                                    minHeight: 4,
                                    value: hasLevel
                                        ? (levelInfo.currentExp! /
                                                  levelInfo.nextExp!)
                                              .clamp(0.0, 1.0)
                                        : 0,
                                    backgroundColor: tokens.border.withValues(
                                      alpha: 0.35,
                                    ),
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      tokens.accentInk,
                                    ),
                                    stopIndicatorColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );

                  final kpis = Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _windowsStatKpi(
                        count: userStat.dynamicCount,
                        label: '动态',
                        onTap: () => controller.push('memberDynamics'),
                      ),
                      const SizedBox(width: 10),
                      _windowsStatKpi(
                        count: userStat.following,
                        label: '关注',
                        onTap: () => controller.push('follow'),
                      ),
                      const SizedBox(width: 10),
                      _windowsStatKpi(
                        count: userStat.follower,
                        label: '粉丝',
                        onTap: () => controller.push('fan'),
                      ),
                    ],
                  );

                  if (wide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: profileRow),
                        const SizedBox(width: 20),
                        kpis,
                      ],
                    );
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      profileRow,
                      const SizedBox(height: 16),
                      kpis,
                    ],
                  );
                },
              ),
              const SizedBox(height: 18),
              Divider(height: 1, color: tokens.border.withValues(alpha: 0.38)),
              const SizedBox(height: 14),
              _buildWindowsQuickActions(),
            ],
          ),
        ),
      );
    });
  }

  Widget _windowsStatKpi({
    required int? count,
    required String label,
    required VoidCallback onTap,
  }) {
    final tokens = context.windowsNeo;
    return Material(
      color: tokens.surfaceRaised,
      borderRadius: tokens.actionRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: tokens.hover,
        child: Container(
          constraints: const BoxConstraints(minWidth: 88),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: tokens.actionRadius,
            border: Border.all(color: tokens.border.withValues(alpha: 0.45)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                count?.toString() ?? '-',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: tokens.ink,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontFamilyFallback: tokens.displayFontFallback,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> get _windowsHeaderActions => [
    if (GStorage.reply != null)
      IconButton(
        tooltip: '\u8bc4\u8bba\u8bb0\u5f55',
        onPressed: () => PageUtils.openWorkspaceTab(
          route: '/myReply',
          title: '\u8bc4\u8bba\u8bb0\u5f55',
        ),
        icon: const Icon(Icons.message_outlined),
      ),
    Obx(() {
      final anonymity = MineController.anonymity.value;
      return IconButton(
        tooltip: anonymity
            ? '\u9000\u51fa\u65e0\u75d5\u6a21\u5f0f'
            : '\u8fdb\u5165\u65e0\u75d5\u6a21\u5f0f',
        onPressed: MineController.onChangeAnonymity,
        icon: Icon(
          anonymity ? MdiIcons.incognito : MdiIcons.incognitoOff,
        ),
      );
    }),
    IconButton(
      tooltip: '\u5207\u6362\u8d26\u53f7',
      onPressed: () => LoginPageController.switchAccountDialog(context),
      icon: const Icon(Icons.switch_account_outlined),
    ),
    Obx(
      () => IconButton(
        tooltip: '\u5207\u6362\u4e3b\u9898',
        onPressed: controller.onChangeTheme,
        icon: controller.themeType.value.icon,
      ),
    ),
    IconButton(
      tooltip: '\u5237\u65b0',
      onPressed: controller.onRefresh,
      icon: const Icon(Icons.refresh_outlined),
    ),
    IconButton(
      tooltip: '\u8bbe\u7f6e',
      onPressed: () => PageUtils.openToolTab(
        route: '/setting',
        title: '\u8bbe\u7f6e',
      ),
      icon: const Icon(Icons.settings_outlined),
    ),
    const SizedBox(width: 6),
  ];

  Widget _buildWindowsQuickActions() {
    final tokens = context.windowsNeo;
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: controller.list.indexed
            .map(
              (entry) => Material(
                color: tokens.surfaceRaised,
                borderRadius: tokens.actionRadius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  hoverColor: tokens.hover,
                  onTap: entry.$1 == 0
                      ? () => PageUtils.openToolTab(
                          route: '/download',
                          title: '\u4e0b\u8f7d',
                        )
                      : entry.$2.onTap,
                  child: Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: tokens.actionRadius,
                      border: Border.all(
                        color: tokens.border.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(entry.$2.icon, size: 17, color: tokens.accentInk),
                        const SizedBox(width: 8),
                        Text(
                          entry.$2.title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: tokens.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildActions(Color primary) {
    return Row(
      mainAxisAlignment: .spaceEvenly,
      children: controller.list
          .map(
            (e) => Flexible(
              child: InkWell(
                onTap: e.onTap,
                borderRadius: Style.mdRadius,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 80),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Column(
                      spacing: 6,
                      mainAxisSize: .min,
                      mainAxisAlignment: .center,
                      children: [
                        Icon(e.icon, color: primary),
                        Text(
                          e.title,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget get _buildHeaderActions {
    const iconSize = 22.0;
    const padding = EdgeInsets.all(8);
    const style = ButtonStyle(tapTargetSize: .shrinkWrap);
    return PlayerBar(
      left: widget.showBackBtn
          ? const Padding(
              padding: EdgeInsets.only(left: 8),
              child: BackButton(),
            )
          : const SizedBox.shrink(),
      right: Row(
        spacing: 5,
        mainAxisSize: .min,
        children: [
          if (!_mainController.hasHome) ...[
            IconButton(
              iconSize: iconSize,
              padding: padding,
              style: style,
              tooltip: '搜索',
              onPressed: () => PageUtils.toDupNamed('/search'),
              icon: const Icon(Icons.search),
            ),
            msgBadge(_mainController),
          ],
          if (GStorage.reply != null)
            IconButton(
              iconSize: iconSize,
              padding: padding,
              style: style,
              tooltip: '评论记录',
              onPressed: () => PageUtils.toDupNamed('/myReply'),
              icon: const Icon(Icons.message_outlined),
            ),
          Obx(
            () {
              final anonymity = MineController.anonymity.value;
              return IconButton(
                iconSize: iconSize,
                padding: padding,
                style: style,
                tooltip: "${anonymity ? '退出' : '进入'}无痕模式",
                onPressed: MineController.onChangeAnonymity,
                icon: anonymity
                    ? const Icon(MdiIcons.incognito)
                    : const Icon(MdiIcons.incognitoOff),
              );
            },
          ),
          IconButton(
            iconSize: iconSize,
            padding: padding,
            style: style,
            tooltip: '切换账号',
            onPressed: () => LoginPageController.switchAccountDialog(context),
            icon: const Icon(Icons.switch_account_outlined),
          ),
          Obx(
            () => IconButton(
              iconSize: iconSize,
              padding: padding,
              style: style,
              tooltip: '切换至${controller.nextThemeType.label}主题',
              onPressed: controller.onChangeTheme,
              icon: controller.themeType.value.icon,
            ),
          ),
          IconButton(
            iconSize: iconSize,
            padding: padding,
            style: style,
            tooltip: '设置',
            onPressed: () => PageUtils.toDupNamed('/setting'),
            icon: const Icon(Icons.settings_outlined),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildUserInfo(ThemeData theme, Color secondary) {
    final style = TextStyle(
      fontSize: theme.textTheme.titleMedium!.fontSize,
      fontWeight: FontWeight.bold,
    );
    final labelStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    final coinLabelStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      color: theme.colorScheme.outline,
    );
    final coinValStyle = TextStyle(
      fontSize: theme.textTheme.labelMedium!.fontSize,
      fontWeight: FontWeight.bold,
      color: secondary,
    );
    return Obx(() {
      final userInfo = controller.userInfo.value;
      final levelInfo = userInfo.levelInfo;
      final hasLevel = levelInfo != null;
      final isVip = userInfo.vipStatus != null && userInfo.vipStatus! > 0;
      final userStat = controller.userStat.value;
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: .opaque,
            onTap: controller.onLogin,
            onLongPress: () {
              Feedback.forLongPress(context);
              controller.onLogin(true);
            },
            onSecondaryTap: PlatformUtils.isMobile
                ? null
                : () => controller.onLogin(true),
            child: Row(
              mainAxisSize: .min,
              children: [
                const SizedBox(width: 20),
                userInfo.face != null
                    ? Stack(
                        clipBehavior: .none,
                        children: [
                          NetworkImgLayer(
                            src: userInfo.face,
                            type: .avatar,
                            width: 55,
                            height: 55,
                          ),
                          if (isVip)
                            Positioned(
                              right: -1,
                              bottom: -2,
                              child: SvgPicture.asset(
                                Assets.vipIcon,
                                height: 19,
                                semanticsLabel: "大会员",
                              ),
                            ),
                        ],
                      )
                    : ClipOval(
                        child: Image.asset(
                          width: 55,
                          height: 55,
                          cacheHeight: 55.cacheSize(context),
                          Assets.avatarPlaceHolder,
                          semanticLabel: "默认头像",
                        ),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: .min,
                    mainAxisAlignment: .center,
                    crossAxisAlignment: .start,
                    children: [
                      Row(
                        spacing: 6,
                        children: [
                          Flexible(
                            child: Text(
                              userInfo.uname ?? '点击登录',
                              style: theme.textTheme.titleMedium!.copyWith(
                                height: 1,
                                color: isVip && userInfo.vipType == 2
                                    ? theme.colorScheme.vipColor
                                    : null,
                              ),
                              maxLines: 1,
                              overflow: .ellipsis,
                            ),
                          ),
                          BiliUtils.levelPicture(
                            levelInfo?.currentLevel ?? 0,
                            isSeniorMember: userInfo.isSeniorMember == 1,
                            height: 10,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '硬币 ',
                              style: coinLabelStyle,
                            ),
                            TextSpan(
                              text: userInfo.money?.toString() ?? '-',
                              style: coinValStyle,
                            ),
                            TextSpan(
                              text: "      经验 ",
                              style: coinLabelStyle,
                            ),
                            TextSpan(
                              text: levelInfo?.currentExp?.toString() ?? '-',
                              style: coinValStyle,
                            ),
                            TextSpan(
                              text: "/${levelInfo?.nextExp ?? '-'}",
                              style: coinLabelStyle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 225),
                        child: LinearProgressIndicator(
                          minHeight: 2.25,
                          value: hasLevel
                              ? levelInfo.currentExp! / levelInfo.nextExp!
                              : 0,
                          backgroundColor: theme.colorScheme.outline.withValues(
                            alpha: 0.4,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(secondary),
                          stopIndicatorColor: Colors.transparent,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: .spaceEvenly,
            children: [
              _btn(
                count: userStat.dynamicCount,
                countStyle: style,
                name: '动态',
                labelStyle: labelStyle,
                onTap: () => controller.push('memberDynamics'),
              ),
              _btn(
                count: userStat.following,
                countStyle: style,
                name: '关注',
                labelStyle: labelStyle,
                onTap: () => controller.push('follow'),
              ),
              _btn(
                count: userStat.follower,
                countStyle: style,
                name: '粉丝',
                labelStyle: labelStyle,
                onTap: () => controller.push('fan'),
              ),
            ],
          ),
        ],
      );
    });
  }

  Widget _btn({
    required int? count,
    required TextStyle countStyle,
    required String name,
    required TextStyle? labelStyle,
    required VoidCallback onTap,
  }) {
    return Flexible(
      child: InkWell(
        onTap: onTap,
        borderRadius: Style.mdRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: AspectRatio(
            aspectRatio: 1,
            child: Column(
              spacing: 4,
              mainAxisSize: .min,
              mainAxisAlignment: .center,
              children: [
                Text(
                  count?.toString() ?? '-',
                  style: countStyle,
                ),
                Text(
                  name,
                  style: labelStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _autoRefresh(MineRefreshMixin tabCtr) => Timer(
    const Duration(milliseconds: 150),
    () => tabCtr.onRefresh(isManual: false),
  );

  Widget _buildFav() {
    return _buildTab(
      .favorite,
      controller.favCtr!,
      itemBuilder: (element) => FavFolderItem(
        item: element,
        onPop: () => _autoRefresh(controller.favCtr!),
      ),
      onPushDetail: () => PageUtils.toDupNamed(
        '/fav',
      )?.whenComplete(() => _autoRefresh(controller.favCtr!)),
    );
  }

  Widget _buildHistory() {
    return _buildTab(
      .history,
      controller.historyCtr!,
      itemBuilder: (element) => MineHistoryItem(
        item: element,
        onPop: () => _autoRefresh(controller.historyCtr!),
      ),
      onPushDetail: () => PageUtils.toDupNamed(
        '/history',
      )?.whenComplete(() => _autoRefresh(controller.historyCtr!)),
    );
  }

  Widget _buildLater() {
    return _buildTab(
      .later,
      controller.laterCtr!,
      itemBuilder: (element) => MineLaterItem(
        item: element,
        onPop: () => _autoRefresh(controller.laterCtr!),
      ),
      onPushDetail: () => PageUtils.toDupNamed(
        '/later',
      )?.whenComplete(() => _autoRefresh(controller.laterCtr!)),
    );
  }

  Widget _buildSub() {
    return _buildTab(
      .sub,
      controller.subCtr!,
      itemBuilder: (element) => MineSubItem(
        item: element,
        onPop: () => _autoRefresh(controller.subCtr!),
      ),
      onPushDetail: () => PageUtils.toDupNamed(
        '/subscription',
      )?.whenComplete(() => _autoRefresh(controller.subCtr!)),
    );
  }

  Widget _buildTab<R, T>(
    MineTabType tab,
    MineRefreshMixin<R, T> tabCtr, {
    required Widget Function(T element) itemBuilder,
    required VoidCallback onPushDetail,
  }) {
    final Widget child;
    switch (tabCtr.loadingState.value) {
      case Loading():
        return const SizedBox.shrink();
      case Success(:final response):
        if (response == null || response.isEmpty) {
          return const SizedBox.shrink();
        }
        child = SizedBox(
          height: 180,
          child: ListView.separated(
            itemCount: response.length,
            controller: tabCtr.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const .only(left: 20, top: 10, right: 20),
            itemBuilder: (context, index) {
              if (index == response.length - 1) {
                tabCtr.onLoadMore();
              }
              return SizedBox(width: 180, child: itemBuilder(response[index]));
            },
            scrollDirection: .horizontal,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
          ),
        );
      case Error(:final errMsg):
        if (errMsg == null) return const SizedBox.shrink();
        child = SizedBox(
          height: 160,
          child: Center(child: Text(errMsg, textAlign: .center)),
        );
    }
    final secondary = theme.colorScheme.secondary;
    return Column(
      children: [
        Divider(
          height: 20,
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
        ListTile(
          dense: true,
          onTap: onPushDetail,
          title: Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '${tab.label}  ',
                    style: const TextStyle(fontSize: 16, fontWeight: .bold),
                  ),
                  if (tabCtr.count != null)
                    TextSpan(
                      text: '${tabCtr.count}  ',
                      style: TextStyle(color: secondary),
                    ),
                  WidgetSpan(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: secondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          trailing: IconButton(
            tooltip: '刷新',
            onPressed: tabCtr.onRefresh,
            icon: const Icon(Icons.refresh, size: 20),
          ),
        ),
        child,
      ],
    );
  }
}
