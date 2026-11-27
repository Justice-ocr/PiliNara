import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_media_meta.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class _PaletteAction {
  const _PaletteAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.onRun,
    this.keywords = '',
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final VoidCallback onRun;
  final String keywords;
}

/// Raycast / VS Code inspired floating command palette & quick search overlay
/// triggered by `Ctrl+K` anywhere inside the Windows Neo workspace.
class WindowsNeoCommandPalette extends StatefulWidget {
  const WindowsNeoCommandPalette({
    super.key,
    this.onSplit,
    this.onToggleSidebar,
    this.initialHint,
  });

  final VoidCallback? onSplit;
  final VoidCallback? onToggleSidebar;
  final String? initialHint;

  static bool _isOpen = false;

  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSplit,
    VoidCallback? onToggleSidebar,
    String? initialHint,
  }) async {
    if (_isOpen) return;
    _isOpen = true;
    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: true,
        barrierLabel: '关闭命令面板',
        barrierColor: Colors.black.withValues(alpha: 0.36),
        transitionDuration: context.windowsNeoDuration(
          const Duration(milliseconds: 160),
        ),
        pageBuilder: (dialogContext, _, _) => WindowsNeoCommandPalette(
          onSplit: onSplit,
          onToggleSidebar: onToggleSidebar,
          initialHint: initialHint,
        ),
        transitionBuilder: (dialogContext, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1.0).animate(curved),
              alignment: Alignment.topCenter,
              child: child,
            ),
          );
        },
      );
    } finally {
      _isOpen = false;
    }
  }

  @override
  State<WindowsNeoCommandPalette> createState() =>
      _WindowsNeoCommandPaletteState();
}

class _WindowsNeoCommandPaletteState extends State<WindowsNeoCommandPalette> {
  final _inputController = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _suggestTimer;
  List<String> _suggestions = const [];
  int _selectedIndex = 0;

  static final _bvReg = RegExp(r'^BV[0-9A-Za-z]{10}$', caseSensitive: false);
  static final _avReg = RegExp(r'^av(\d+)$', caseSensitive: false);
  static final _uidReg = RegExp(r'^(?:uid[:：\s]?)(\d{4,12})$', caseSensitive: false);
  static final _urlReg = RegExp(
    r'^(?:https?://)?(?:www\.|m\.)?(?:bilibili\.com|b23\.tv)/\S+$',
    caseSensitive: false,
  );

  @override
  void dispose() {
    _suggestTimer?.cancel();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    setState(() => _selectedIndex = 0);
    _suggestTimer?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.startsWith('>')) {
      if (_suggestions.isNotEmpty) {
        setState(() => _suggestions = const []);
      }
      return;
    }
    _suggestTimer = Timer(const Duration(milliseconds: 220), () async {
      final res = await SearchHttp.searchSuggest(term: trimmed);
      if (!mounted || _inputController.text.trim() != trimmed) return;
      if (res case Success(:final response)) {
        final tags = response.tag
                ?.map((e) => e.term)
                .whereType<String>()
                .where((s) => s.isNotEmpty)
                .take(6)
                .toList(growable: false) ??
            const <String>[];
        setState(() {
          _suggestions = tags;
          _selectedIndex = 0;
        });
      }
    });
  }

  void _closeAndRun(VoidCallback action) {
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) => action());
  }

  void _cycleBrightness() {
    final current = Pref.themeType;
    final next = switch (current) {
      ThemeType.light => ThemeType.dark,
      ThemeType.dark => ThemeType.system,
      ThemeType.system => ThemeType.light,
    };
    GStorage.setting.put(SettingBoxKey.themeMode, next.index);
    Get.changeThemeMode(ThemeUtils.themeMode = next.toThemeMode);
  }

  List<_PaletteAction> _buildBuiltinCommands() {
    return [
      for (final def in WindowsNeoThemeRegistry.values)
        _PaletteAction(
          icon: Icons.palette_outlined,
          title: '切换主题：${def.label}',
          subtitle: def.description,
          badge: '主题',
          keywords: 'theme ${def.label} ${def.description} ${def.family.name}',
          onRun: () => WindowsNeoThemeController.select(def.family),
        ),
      for (final depth in WindowsNeoThemeDepth.values)
        _PaletteAction(
          icon: Icons.layers_outlined,
          title: '视觉深度：${depth.label}',
          subtitle: '调整背景插画、矢量网格与页头装饰强度',
          badge: '深度',
          keywords: 'depth ${depth.label} 深度',
          onRun: () => WindowsNeoThemeController.selectDepth(depth),
        ),
      _PaletteAction(
        icon: Icons.brightness_6_outlined,
        title: '切换亮色 / 深色 / 跟随系统',
        subtitle: '循环切换全局明暗模式并同步 Win11 窗口边框',
        badge: '外观',
        keywords: 'dark light theme 深色 亮色 夜间 模式',
        onRun: _cycleBrightness,
      ),
      if (widget.onSplit != null)
        _PaletteAction(
          icon: Icons.splitscreen_outlined,
          title: '打开分屏工作台',
          subtitle: '选择 2–4 个视频或直播标签同屏观看',
          badge: '工作区',
          keywords: 'split 分屏 多屏',
          onRun: widget.onSplit!,
        ),
      if (widget.onToggleSidebar != null)
        _PaletteAction(
          icon: Icons.view_sidebar_outlined,
          title: '折叠 / 展开左侧导航栏',
          subtitle: '宽屏下释放更多横向内容视野',
          badge: '工作区',
          keywords: 'sidebar 侧栏 折叠 展开',
          onRun: widget.onToggleSidebar!,
        ),
      _PaletteAction(
        icon: Icons.download_outlined,
        title: '打开离线缓存中心',
        subtitle: '管理本地缓存视频与离线文件夹',
        badge: '导航',
        keywords: 'download 下载 缓存',
        onRun: () => PageUtils.openToolTab(route: '/download', title: '下载'),
      ),
      _PaletteAction(
        icon: Icons.chat_bubble_outline,
        title: '打开消息与私信',
        subtitle: '查看站内私信、回复与系统通知',
        badge: '导航',
        keywords: 'whisper message 消息 私信',
        onRun: () => PageUtils.openToolTab(route: '/whisper', title: '消息'),
      ),
      _PaletteAction(
        icon: Icons.settings_outlined,
        title: '打开应用设置',
        subtitle: '调整主题工作室、播放器、弹幕与过滤偏好',
        badge: '导航',
        keywords: 'setting 设置 外观 播放',
        onRun: () => PageUtils.openToolTab(route: '/setting', title: '设置'),
      ),
      _PaletteAction(
        icon: Icons.manage_search_rounded,
        title: '打开完整搜索页（热搜与历史）',
        subtitle: '查看完整热搜榜、搜索发现与历史记录',
        badge: '搜索',
        keywords: 'search 热搜 历史',
        onRun: () => PageUtils.toSearch(),
      ),
    ];
  }

  List<_PaletteAction> _buildActions() {
    final raw = _inputController.text.trim();
    final commands = _buildBuiltinCommands();

    if (raw.isEmpty) {
      return [
        if (widget.initialHint != null && widget.initialHint!.isNotEmpty)
          _PaletteAction(
            icon: Icons.search_rounded,
            title: '搜索「${widget.initialHint!}」',
            subtitle: '按回车快速搜索当前推荐词',
            badge: '推荐',
            onRun: () => PageUtils.toSearchResult(widget.initialHint!),
          ),
        ...commands.take(7),
      ];
    }

    if (raw.startsWith('>')) {
      final q = raw.substring(1).trim().toLowerCase();
      if (q.isEmpty) return commands;
      return commands
          .where(
            (c) =>
                c.title.toLowerCase().contains(q) ||
                c.subtitle.toLowerCase().contains(q) ||
                c.keywords.toLowerCase().contains(q),
          )
          .toList(growable: false);
    }

    final results = <_PaletteAction>[];

    // Direct link / BV / av / UID recognition
    if (_bvReg.hasMatch(raw)) {
      results.add(
        _PaletteAction(
          icon: Icons.play_circle_outline_rounded,
          title: '直达视频 $raw',
          subtitle: '跳过搜索页，在新标签直接打开该稿件',
          badge: 'BV直达',
          onRun: () => PiliScheme.routePushFromUrl('https://www.bilibili.com/video/$raw'),
        ),
      );
    } else if (_avReg.firstMatch(raw) case final m?) {
      final aid = m.group(1)!;
      results.add(
        _PaletteAction(
          icon: Icons.play_circle_outline_rounded,
          title: '直达视频 av$aid',
          subtitle: '跳过搜索页，直接解析并打开稿件',
          badge: 'AV直达',
          onRun: () => PiliScheme.routePushFromUrl('https://www.bilibili.com/video/av$aid'),
        ),
      );
    } else if (_urlReg.hasMatch(raw)) {
      final normalized = raw.startsWith('http') ? raw : 'https://$raw';
      results.add(
        _PaletteAction(
          icon: Icons.link_rounded,
          title: '解析并打开链接',
          subtitle: normalized,
          badge: '直链',
          onRun: () => PiliScheme.routePushFromUrl(normalized),
        ),
      );
    } else if (_uidReg.firstMatch(raw) case final m?) {
      final uid = m.group(1)!;
      results.add(
        _PaletteAction(
          icon: Icons.person_outline_rounded,
          title: '访问 UP 主空间 (UID: $uid)',
          subtitle: '直接打开该用户主页',
          badge: '用户',
          onRun: () => PageUtils.toMember(uid),
        ),
      );
    }

    results.add(
      _PaletteAction(
        icon: Icons.search_rounded,
        title: '搜索「$raw」',
        subtitle: '在 B 站全站搜索视频、番剧、直播与 UP 主',
        badge: '回车搜索',
        onRun: () => PageUtils.toSearchResult(raw),
      ),
    );

    for (final term in _suggestions) {
      if (term == raw) continue;
      results.add(
        _PaletteAction(
          icon: Icons.north_west_rounded,
          title: term,
          subtitle: '搜索联想词',
          badge: '联想',
          onRun: () => PageUtils.toSearchResult(term),
        ),
      );
    }

    final lower = raw.toLowerCase();
    final matchedCommands = commands.where(
      (c) =>
          c.title.toLowerCase().contains(lower) ||
          c.keywords.toLowerCase().contains(lower),
    );
    results.addAll(matchedCommands.take(3));
    return results;
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final actions = _buildActions();
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (actions.isNotEmpty) {
        setState(() => _selectedIndex = (_selectedIndex + 1) % actions.length);
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      if (actions.isNotEmpty) {
        setState(
          () => _selectedIndex =
              (_selectedIndex - 1 + actions.length) % actions.length,
        );
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final theme = Theme.of(context);
    final actions = _buildActions();
    final safeIndex = actions.isEmpty
        ? 0
        : _selectedIndex.clamp(0, actions.length - 1);

    return Align(
      alignment: const Alignment(0, -0.62),
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 480),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: tokens.panelRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.surface.withValues(alpha: 0.94),
                    borderRadius: tokens.panelRadius,
                    border: Border.all(
                      color: tokens.accentBorder.withValues(alpha: 0.52),
                      width: 1.2,
                    ),
                    boxShadow: tokens.cardHoverShadow,
                  ),
                  child: Focus(
                    onKeyEvent: _handleKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search_rounded,
                                size: 20,
                                color: tokens.accentInk,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _inputController,
                                  focusNode: _focusNode,
                                  autofocus: true,
                                  onChanged: _onQueryChanged,
                                  onSubmitted: (_) {
                                    if (actions.isNotEmpty) {
                                      _closeAndRun(actions[safeIndex].onRun);
                                    }
                                  },
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: tokens.ink,
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        '搜索视频 / 粘贴 BV 号或链接 / 输入 > 执行命令…',
                                    hintStyle: theme.textTheme.bodyMedium
                                        ?.copyWith(color: tokens.muted),
                                    filled: false,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                              if (_inputController.text.isNotEmpty)
                                IconButton(
                                  tooltip: '清空',
                                  iconSize: 17,
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    _inputController.clear();
                                    _onQueryChanged('');
                                  },
                                  icon: Icon(Icons.close, color: tokens.muted),
                                ),
                              const WindowsNeoTag(
                                text: 'ESC',
                                tone: WindowsNeoTagTone.neutral,
                              ),
                            ],
                          ),
                        ),
                        Divider(
                          height: 1,
                          color: tokens.border.withValues(alpha: 0.45),
                        ),
                        if (actions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 28),
                            child: Text(
                              '没有匹配的命令，去掉 > 可直接搜索全站',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: tokens.muted,
                              ),
                            ),
                          )
                        else
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: const EdgeInsets.all(8),
                              itemCount: actions.length,
                              itemBuilder: (context, index) {
                                final item = actions[index];
                                final selected = index == safeIndex;
                                return Material(
                                  color: selected
                                      ? tokens.accentSurface
                                      : Colors.transparent,
                                  borderRadius: tokens.actionRadius,
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => _closeAndRun(item.onRun),
                                    onHover: (hovered) {
                                      if (hovered && _selectedIndex != index) {
                                        setState(() => _selectedIndex = index);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        borderRadius: tokens.actionRadius,
                                        border: selected
                                            ? Border.all(
                                                color: tokens.accentBorder
                                                    .withValues(alpha: 0.48),
                                              )
                                            : null,
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            item.icon,
                                            size: 18,
                                            color: selected
                                                ? tokens.accentInk
                                                : tokens.muted,
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item.title,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .bodyMedium
                                                      ?.copyWith(
                                                        color: tokens.ink,
                                                        fontWeight: selected
                                                            ? FontWeight.w600
                                                            : FontWeight.w500,
                                                      ),
                                                ),
                                                Text(
                                                  item.subtitle,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: theme
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: tokens.muted,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          WindowsNeoTag(
                                            text: item.badge,
                                            tone: selected
                                                ? WindowsNeoTagTone.accent
                                                : WindowsNeoTagTone.neutral,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: tokens.background.withValues(alpha: 0.72),
                            border: Border(
                              top: BorderSide(
                                color: tokens.border.withValues(alpha: 0.42),
                              ),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '↑↓ 选择 · Enter 执行 · 输入 > 切换主题与控制工作区',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: tokens.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
