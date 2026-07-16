import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/common/widgets/view_safe_area.dart';
import 'package:PiliPlus/http/login.dart';
import 'package:PiliPlus/models/common/setting_type.dart';
import 'package:PiliPlus/pages/about/view.dart';
import 'package:PiliPlus/pages/login/controller.dart';
import 'package:PiliPlus/pages/setting/block_setting.dart';
import 'package:PiliPlus/pages/setting/dynamics_setting.dart';
import 'package:PiliPlus/pages/setting/extra_setting.dart';
import 'package:PiliPlus/pages/setting/play_setting.dart';
import 'package:PiliPlus/pages/setting/privacy_setting.dart';
import 'package:PiliPlus/pages/setting/recommend_setting.dart';
import 'package:PiliPlus/pages/setting/style_setting.dart';
import 'package:PiliPlus/pages/setting/video_setting.dart';
import 'package:PiliPlus/pages/setting/widgets/multi_select_dialog.dart';
import 'package:PiliPlus/pages/settings_search/view.dart';
import 'package:PiliPlus/pages/webdav/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/accounts.dart';
import 'package:PiliPlus/utils/accounts/account.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart' hide ListTile;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class _SettingsModel {
  final SettingType type;
  final String? subtitle;
  final Icon icon;

  const _SettingsModel({
    required this.type,
    this.subtitle,
    required this.icon,
  });
}

MediaQueryData windowsSettingsPaneMediaQuery(
  MediaQueryData parent,
  BoxConstraints constraints,
) => parent.copyWith(size: constraints.biggest);

class SettingPage extends StatefulWidget {
  const SettingPage({super.key});

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  late SettingType _type = SettingType.privacySetting;
  final RxBool _noAccount = Accounts.account.isEmpty.obs;
  late bool _isPortrait;

  static const List<_SettingsModel> _items = [
    _SettingsModel(
      type: SettingType.privacySetting,
      subtitle: '黑名单、隐私保护',
      icon: Icon(Icons.privacy_tip_outlined),
    ),
    _SettingsModel(
      type: SettingType.blockSetting,
      subtitle: '屏蔽用户、白名单、Tag 屏蔽',
      icon: Icon(Icons.shield_outlined),
    ),
    _SettingsModel(
      type: SettingType.recommendSetting,
      subtitle: '推荐来源（web/app）、刷新保留内容、过滤器',
      icon: Icon(Icons.explore_outlined),
    ),
    _SettingsModel(
      type: SettingType.dynamicsSetting,
      subtitle: '关键词过滤、屏蔽用户、带货动态屏蔽',
      icon: Icon(Icons.dynamic_feed_outlined),
    ),
    _SettingsModel(
      type: SettingType.videoSetting,
      subtitle: '画质、音质、解码、缓冲、音频输出等',
      icon: Icon(Icons.video_settings_outlined),
    ),
    _SettingsModel(
      type: SettingType.playSetting,
      subtitle: '双击/长按、全屏、后台播放、弹幕、字幕、底部进度条等',
      icon: Icon(Icons.touch_app_outlined),
    ),
    _SettingsModel(
      type: SettingType.styleSetting,
      subtitle: '横屏适配（平板）、侧栏、列宽、首页、动态红点、主题、字号、图片、帧率等',
      icon: Icon(Icons.style_outlined),
    ),
    _SettingsModel(
      type: SettingType.extraSetting,
      subtitle: '震动、搜索、收藏、ai、评论、代理、更新检查等',
      icon: Icon(Icons.extension_outlined),
    ),
    _SettingsModel(
      type: SettingType.webdavSetting,
      icon: Icon(MdiIcons.databaseCogOutline),
    ),
    _SettingsModel(
      type: SettingType.about,
      icon: Icon(Icons.info_outline),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    _isPortrait = WindowsVideoTabService.enabled
        ? size.width < 760
        : size.isPortrait;
    if (WindowsVideoTabService.enabled && !_isPortrait) {
      return _buildWindowsNeo(theme);
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: _isPortrait ? const Text('设置') : Text(_type.title),
      ),
      body: ViewSafeArea(
        child: _isPortrait
            ? _buildList(theme)
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildList(theme),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                  ),
                  Expanded(
                    flex: 6,
                    child: _buildSettingPage(_type, showAppBar: false),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWindowsNeo(ThemeData theme) {
    final tokens = context.windowsNeo;
    final selected = _items.firstWhere((item) => item.type == _type);
    return Scaffold(
      backgroundColor: tokens.background,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('设置')),
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: ColoredBox(
              color: tokens.sidebar,
              child: _buildWindowsList(theme),
            ),
          ),
          VerticalDivider(width: 1, color: tokens.border),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  color: tokens.surface,
                  child: Row(
                    children: [
                      IconTheme.merge(
                        data: IconThemeData(color: tokens.accent, size: 21),
                        child: selected.icon,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.type.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (selected.subtitle case final subtitle?)
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: tokens.muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: tokens.border),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: Material(
                          color: tokens.surface,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: tokens.border),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Theme(
                            data: theme.copyWith(
                              scaffoldBackgroundColor: tokens.surface,
                              canvasColor: tokens.surface,
                            ),
                            child: LayoutBuilder(
                              builder: (context, constraints) => MediaQuery(
                                data: windowsSettingsPaneMediaQuery(
                                  MediaQuery.of(context),
                                  constraints,
                                ),
                                child: _buildSettingPage(
                                  _type,
                                  showAppBar: false,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsList(ThemeData theme) {
    final tokens = context.windowsNeo;
    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 24),
      children: [
        _buildWindowsSearch(theme),
        const SizedBox(height: 10),
        ..._items.take(_items.length - 1).map(_buildWindowsNavItem),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Divider(height: 1, color: tokens.border),
        ),
        _buildWindowsActionItem(
          icon: Icons.switch_account_outlined,
          title: '切换账号',
          onTap: () => LoginPageController.switchAccountDialog(context),
        ),
        Obx(
          () => _noAccount.value
              ? const SizedBox.shrink()
              : _buildWindowsActionItem(
                  icon: Icons.logout_outlined,
                  title: '退出登录',
                  onTap: () => _logoutDialog(context),
                  foregroundColor: theme.colorScheme.error,
                ),
        ),
        _buildWindowsNavItem(_items.last),
      ],
    );
  }

  Widget _buildWindowsSearch(ThemeData theme) {
    final tokens = context.windowsNeo;
    return Material(
      color: tokens.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: tokens.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SettingsSearchPage(),
          ),
        ),
        child: SizedBox(
          height: 38,
          child: Row(
            children: [
              const SizedBox(width: 12),
              Icon(Icons.search, size: 18, color: tokens.muted),
              const SizedBox(width: 8),
              Text(
                '搜索设置',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowsNavItem(_SettingsModel item) {
    final tokens = context.windowsNeo;
    final selected = item.type == _type;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: selected ? tokens.accentSurface : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _toPage(item.type),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: selected ? tokens.accent : Colors.transparent,
                  width: 2.5,
                ),
              ),
            ),
            child: Row(
              children: [
                IconTheme.merge(
                  data: IconThemeData(
                    color: selected ? tokens.accent : tokens.muted,
                    size: 19,
                  ),
                  child: item.icon,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.type.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item.subtitle case final subtitle?)
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, color: tokens.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWindowsActionItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? foregroundColor,
  }) {
    final tokens = context.windowsNeo;
    final color = foregroundColor ?? tokens.muted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            height: 42,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, size: 19, color: color),
                  const SizedBox(width: 10),
                  Text(title, style: TextStyle(color: foregroundColor)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _noAccount.close();
    super.dispose();
  }

  void _toPage(SettingType type) {
    if (_isPortrait) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => _buildSettingPage(type)),
      );
    } else {
      _type = type;
      setState(() {});
    }
  }

  Widget _buildSettingPage(
    SettingType type, {
    bool showAppBar = true,
  }) => switch (type) {
    SettingType.privacySetting => PrivacySetting(showAppBar: showAppBar),
    SettingType.blockSetting => BlockSetting(showAppBar: showAppBar),
    SettingType.recommendSetting => RecommendSetting(showAppBar: showAppBar),
    SettingType.dynamicsSetting => DynamicsSetting(showAppBar: showAppBar),
    SettingType.videoSetting => VideoSetting(showAppBar: showAppBar),
    SettingType.playSetting => PlaySetting(showAppBar: showAppBar),
    SettingType.styleSetting => StyleSetting(showAppBar: showAppBar),
    SettingType.extraSetting => ExtraSetting(showAppBar: showAppBar),
    SettingType.webdavSetting => WebDavSettingPage(showAppBar: showAppBar),
    SettingType.about => AboutPage(showAppBar: showAppBar),
  };

  Color? _getTileColor(ThemeData theme, SettingType type) {
    if (_isPortrait) {
      return null;
    } else {
      return type == _type ? theme.colorScheme.onInverseSurface : null;
    }
  }

  Widget _buildList(ThemeData theme) {
    final padding = MediaQuery.viewPaddingOf(context);
    TextStyle titleStyle = theme.textTheme.titleMedium!;
    TextStyle subTitleStyle = theme.textTheme.labelMedium!.copyWith(
      color: theme.colorScheme.outline,
    );
    return ListView(
      padding: EdgeInsets.only(bottom: padding.bottom + 100),
      children: [
        _buildSearchItem(theme),
        ..._items
            .take(_items.length - 1)
            .map(
              (item) => ListTile(
                tileColor: _getTileColor(theme, item.type),
                onTap: () => _toPage(item.type),
                leading: item.icon,
                title: Text(item.type.title, style: titleStyle),
                subtitle: item.subtitle == null
                    ? null
                    : Text(item.subtitle!, style: subTitleStyle),
              ),
            ),
        ListTile(
          onTap: () => LoginPageController.switchAccountDialog(context),
          leading: const Icon(Icons.switch_account_outlined),
          title: Text('切换账号', style: titleStyle),
        ),
        Obx(
          () => _noAccount.value
              ? const SizedBox.shrink()
              : ListTile(
                  leading: const Icon(Icons.logout_outlined),
                  onTap: () => _logoutDialog(context),
                  title: Text('退出登录', style: titleStyle),
                ),
        ),
        ListTile(
          tileColor: _getTileColor(theme, _items.last.type),
          onTap: () => _toPage(_items.last.type),
          leading: _items.last.icon,
          title: Text(_items.last.type.title, style: titleStyle),
        ),
      ],
    );
  }

  Future<void> _logoutDialog(BuildContext context) async {
    final result = await showDialog<Set<LoginAccount>>(
      context: context,
      builder: (context) => MultiSelectDialog<LoginAccount>(
        title: '选择要登出的账号uid',
        initValues: const Iterable.empty(),
        values: {
          for (final i in Accounts.account.values) i: i.mid.toString(),
        },
      ),
    );
    if (!context.mounted || result == null || result.isEmpty) return;
    Future<void> logout() {
      _noAccount.value = result.length == Accounts.account.length;
      return Accounts.deleteAll(result);
    }

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('提示'),
          content: Text(
            "确认要退出以下账号登录吗\n\n${result.map((i) => i.mid.toString()).join('\n')}",
          ),
          actions: [
            TextButton(
              onPressed: Get.back,
              child: Text(
                '点错了',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Get.back();
                logout();
              },
              child: Text(
                '仅登出',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            TextButton(
              onPressed: () async {
                SmartDialog.showLoading();
                final res = await LoginHttp.logout(Accounts.main);
                if (res['status']) {
                  SmartDialog.dismiss();
                  logout();
                  Get.back();
                } else {
                  SmartDialog.dismiss();
                  SmartDialog.showToast(res['msg'].toString());
                }
              },
              child: const Text('确认'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchItem(ThemeData theme) => Padding(
    padding: const EdgeInsets.only(
      left: 16,
      right: 16,
      bottom: 8,
    ),
    child: Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const SettingsSearchPage(),
          ),
        ),
        borderRadius: const BorderRadius.all(Radius.circular(50)),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(50)),
            color: theme.colorScheme.onInverseSurface,
          ),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  size: 18,
                  applyTextScaling: true,
                  Icons.search,
                ),
                Text(
                  ' 搜索',
                  style: TextStyle(height: 1),
                  strutStyle: StrutStyle(height: 1, leading: 0),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
