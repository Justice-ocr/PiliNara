import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/http/search.dart';
import 'package:PiliPlus/models/common/theme/theme_type.dart';
import 'package:PiliPlus/models_new/search/search_trending/data.dart';
import 'package:PiliPlus/models_new/search/search_trending/list.dart';
import 'package:PiliPlus/utils/app_scheme.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_media_meta.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_trending_kit.dart';
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

enum _PaletteHomeTab { discover, commands }

/// Raycast / VS Code inspired floating search hub & command palette triggered
/// by `Ctrl+K` anywhere inside the Windows Neo workspace.
///
/// Directly integrates native search history chips, a redesigned real-time
/// desktop trending board, live search suggestions, BV/av/link/UID routing,
/// and `>` workspace commands.
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
        barrierLabel: '关闭搜索与命令面板',
        barrierColor: Colors.black.withValues(alpha: 0.38),
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
  List<String> _history = const [];
  LoadingState<SearchTrendingData> _trendingState =
      LoadingState<SearchTrendingData>.loading();
  bool _refreshingTrending = false;
  _PaletteHomeTab _homeTab = _PaletteHomeTab.discover;
  int _selectedIndex = 0;

  static final _bvReg = RegExp(r'^BV[0-9A-Za-z]{10}$', caseSensitive: false);
  static final _avReg = RegExp(r'^av(\d+)$', caseSensitive: false);
  static final _uidReg = RegExp(
    r'^(?:uid[:：\s]?)(\d{4,12})$',
    caseSensitive: false,
  );
  static final _urlReg = RegExp(
    r'^(?:https?://)?(?:www\.|m\.)?(?:bilibili\.com|b23\.tv)/\S+$',
    caseSensitive: false,
  );

  @override
  void initState() {
    super.initState();
    _history = WindowsNeoSearchHistoryStore.load();
    final cached = WindowsNeoTrendingCache.validData;
    if (cached != null) {
      _trendingState = Success(cached);
    } else {
      _loadTrending();
    }
  }

  @override
  void dispose() {
    _suggestTimer?.cancel();
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadTrending({bool force = false}) async {
    if (_refreshingTrending) return;
    if (mounted) {
      setState(() {
        _refreshingTrending = true;
        if (force && _trendingState is! Success) {
          _trendingState = LoadingState<SearchTrendingData>.loading();
        }
      });
    }
    final res = await WindowsNeoTrendingCache.fetch(limit: 12, force: force);
    if (!mounted) return;
    setState(() {
      _trendingState = res;
      _refreshingTrending = false;
    });
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
    _suggestTimer = Timer(const Duration(milliseconds: 200), () async {
      final res = await SearchHttp.searchSuggest(term: trimmed);
      if (!mounted || _inputController.text.trim() != trimmed) return;
      if (res case Success(:final response)) {
        final tags =
            response.tag
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

  void _searchKeyword(String keyword) {
    final trimmed = keyword.trim();
    if (trimmed.isEmpty) return;
    WindowsNeoSearchHistoryStore.record(trimmed);
    _closeAndRun(() => PageUtils.toSearchResult(trimmed));
  }

  void _removeHistoryItem(String word) {
    WindowsNeoSearchHistoryStore.remove(word);
    setState(() => _history = WindowsNeoSearchHistoryStore.load());
  }

  void _clearHistory() {
    WindowsNeoSearchHistoryStore.clear();
    setState(() => _history = const []);
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
      _PaletteAction(
        icon: Icons.local_fire_department_rounded,
        title: '打开完整实时热搜榜',
        subtitle: '浏览 B 站全站 TOP 30 原生桌面热搜榜单',
        badge: '热搜榜',
        keywords: 'trending hot 热搜 榜单',
        onRun: () => PageUtils.openToolTab(
          route: '/searchTrending',
          title: '实时热搜榜',
        ),
      ),
      _PaletteAction(
        icon: Icons.manage_search_rounded,
        title: '打开完整搜索页（搜索发现与历史管理）',
        subtitle: '支持搜索历史导入导出与搜索发现词',
        badge: '搜索页',
        keywords: 'search 搜索 发现 历史',
        onRun: () => PageUtils.toSearch(),
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
        subtitle: '桌面双栏 IM 工作台，查看私信与互动通知',
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
    ];
  }

  bool get _isDiscoverHome {
    final raw = _inputController.text.trim();
    return raw.isEmpty && _homeTab == _PaletteHomeTab.discover;
  }

  List<_PaletteAction> _buildListActions() {
    final raw = _inputController.text.trim();
    final commands = _buildBuiltinCommands();

    if (raw.isEmpty) {
      return commands;
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

    if (_bvReg.hasMatch(raw)) {
      results.add(
        _PaletteAction(
          icon: Icons.play_circle_outline_rounded,
          title: '直达视频 $raw',
          subtitle: '跳过搜索页，在新标签直接打开该稿件',
          badge: 'BV直达',
          onRun: () => PiliScheme.routePushFromUrl(
            'https://www.bilibili.com/video/$raw',
          ),
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
          onRun: () => PiliScheme.routePushFromUrl(
            'https://www.bilibili.com/video/av$aid',
          ),
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
        onRun: () {
          WindowsNeoSearchHistoryStore.record(raw);
          PageUtils.toSearchResult(raw);
        },
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
          onRun: () {
            WindowsNeoSearchHistoryStore.record(term);
            PageUtils.toSearchResult(term);
          },
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
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      Navigator.of(context).pop();
      return KeyEventResult.handled;
    }
    if (_isDiscoverHome) {
      return KeyEventResult.ignored;
    }
    final actions = _buildListActions();
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
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final theme = Theme.of(context);
    final raw = _inputController.text.trim();
    final isCommandInput = raw.startsWith('>');
    final actions = _isDiscoverHome ? const <_PaletteAction>[] : _buildListActions();
    final safeIndex = actions.isEmpty
        ? 0
        : _selectedIndex.clamp(0, actions.length - 1);

    return Align(
      alignment: const Alignment(0, -0.52),
      child: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680, maxHeight: 560),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ClipRRect(
              borderRadius: tokens.panelRadius,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tokens.surface.withValues(alpha: 0.95),
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
                        _buildInputHeader(
                          tokens,
                          theme,
                          isCommandInput: isCommandInput,
                          actions: actions,
                          safeIndex: safeIndex,
                        ),
                        Divider(
                          height: 1,
                          color: tokens.border.withValues(alpha: 0.45),
                        ),
                        if (raw.isEmpty) _buildModeBar(tokens, theme),
                        if (_isDiscoverHome)
                          Flexible(child: _buildDiscoverView(tokens, theme))
                        else if (actions.isEmpty)
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
                            child: _buildActionList(
                              tokens,
                              theme,
                              actions,
                              safeIndex,
                            ),
                          ),
                        _buildFooter(tokens, theme),
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

  Widget _buildInputHeader(
    WindowsNeoTokens tokens,
    ThemeData theme, {
    required bool isCommandInput,
    required List<_PaletteAction> actions,
    required int safeIndex,
  }) {
    final hint = widget.initialHint != null && widget.initialHint!.isNotEmpty
        ? '搜索「${widget.initialHint!}」 / 粘贴 BV 号 / 输入 > 执行命令…'
        : '搜索视频、UP 主 / 粘贴 BV 号或链接 / 输入 > 执行命令…';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 10),
      child: Row(
        children: [
          Icon(
            isCommandInput ? Icons.terminal_rounded : Icons.search_rounded,
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
              onSubmitted: (value) {
                final trimmed = value.trim();
                if (_isDiscoverHome) {
                  if (trimmed.isNotEmpty) {
                    _searchKeyword(trimmed);
                  } else if (widget.initialHint != null &&
                      widget.initialHint!.isNotEmpty) {
                    _searchKeyword(widget.initialHint!);
                  }
                  return;
                }
                if (actions.isNotEmpty) {
                  _closeAndRun(actions[safeIndex].onRun);
                }
              },
              style: theme.textTheme.bodyLarge?.copyWith(
                color: tokens.ink,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                  color: tokens.muted,
                ),
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
    );
  }

  Widget _buildModeBar(WindowsNeoTokens tokens, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
      decoration: BoxDecoration(
        color: tokens.background.withValues(alpha: 0.45),
        border: Border(
          bottom: BorderSide(color: tokens.border.withValues(alpha: 0.36)),
        ),
      ),
      child: Row(
        children: [
          _ModePill(
            icon: Icons.local_fire_department_rounded,
            label: '历史与热搜',
            selected: _homeTab == _PaletteHomeTab.discover,
            onTap: () => setState(() {
              _homeTab = _PaletteHomeTab.discover;
              _selectedIndex = 0;
            }),
          ),
          const SizedBox(width: 6),
          _ModePill(
            icon: Icons.terminal_rounded,
            label: '快捷指令',
            selected: _homeTab == _PaletteHomeTab.commands,
            onTap: () => setState(() {
              _homeTab = _PaletteHomeTab.commands;
              _selectedIndex = 0;
            }),
          ),
          const Spacer(),
          if (_homeTab == _PaletteHomeTab.discover) ...[
            Tooltip(
              message: '刷新实时热搜',
              child: InkWell(
                borderRadius: tokens.actionRadius,
                onTap: _refreshingTrending
                    ? null
                    : () => _loadTrending(force: true),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: _refreshingTrending
                        ? tokens.accentInk
                        : tokens.muted,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          InkWell(
            borderRadius: tokens.actionRadius,
            onTap: () => _closeAndRun(
              () => PageUtils.openToolTab(
                route: '/searchTrending',
                title: '实时热搜榜',
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '完整热搜榜',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.accentInk,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    Icons.north_east_rounded,
                    size: 13,
                    color: tokens.accentInk,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoverView(WindowsNeoTokens tokens, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.initialHint != null && widget.initialHint!.isNotEmpty) ...[
            _QuickRecommendBanner(
              keyword: widget.initialHint!,
              onTap: () => _searchKeyword(widget.initialHint!),
            ),
            const SizedBox(height: 12),
          ],
          if (_history.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.history_rounded, size: 15, color: tokens.muted),
                const SizedBox(width: 6),
                Text(
                  '搜索历史',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${_history.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: tokens.muted,
                  ),
                ),
                const Spacer(),
                InkWell(
                  borderRadius: tokens.actionRadius,
                  onTap: _clearHistory,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    child: Text(
                      '清空',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: tokens.muted,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final word in _history.take(12))
                  _HistoryChip(
                    label: word,
                    onTap: () => _searchKeyword(word),
                    onDelete: () => _removeHistoryItem(word),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: tokens.border.withValues(alpha: 0.36)),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 16,
                color: Color(0xFFFF5A5F),
              ),
              const SizedBox(width: 6),
              Text(
                '实时热搜榜',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.ink,
                  fontWeight: FontWeight.w800,
                  fontFamilyFallback: tokens.displayFontFallback,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: tokens.accentInk,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'LIVE',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.accentInk,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              InkWell(
                borderRadius: tokens.actionRadius,
                onTap: () => _closeAndRun(() => PageUtils.toSearch()),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  child: Text(
                    '高级搜索页',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: tokens.muted,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildTrendingBody(tokens, theme),
        ],
      ),
    );
  }

  Widget _buildTrendingBody(WindowsNeoTokens tokens, ThemeData theme) {
    return switch (_trendingState) {
      Loading() => _buildTrendingSkeleton(tokens),
      Error() => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        decoration: BoxDecoration(
          color: tokens.surfaceRaised,
          borderRadius: tokens.cardRadius,
          border: Border.all(color: tokens.border.withValues(alpha: 0.45)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_outlined, size: 18, color: tokens.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '热搜榜暂时加载失败',
                style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
              ),
            ),
            TextButton(
              onPressed: () => _loadTrending(force: true),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
      Success(:final response) => () {
        final items = response.list ?? const <SearchTrendingItemModel>[];
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '暂无热搜数据',
              style: theme.textTheme.bodySmall?.copyWith(color: tokens.muted),
            ),
          );
        }
        final topCount = response.topCount;
        return LayoutBuilder(
          builder: (context, constraints) {
            final twoCol = constraints.maxWidth >= 460;
            const gap = 8.0;
            final itemWidth = twoCol
                ? (constraints.maxWidth - gap) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (var i = 0; i < items.length && i < 12; i++)
                  SizedBox(
                    width: itemWidth,
                    child: _PaletteTrendingCell(
                      item: items[i],
                      isPinned: i < topCount,
                      rank: i + 1 - topCount,
                      onTap: () => _searchKeyword(items[i].keyword),
                    ),
                  ),
              ],
            );
          },
        );
      }(),
    };
  }

  Widget _buildTrendingSkeleton(WindowsNeoTokens tokens) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCol = constraints.maxWidth >= 460;
        const gap = 8.0;
        final itemWidth = twoCol
            ? (constraints.maxWidth - gap) / 2
            : constraints.maxWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < 10; i++)
              Container(
                width: itemWidth,
                height: 36,
                decoration: BoxDecoration(
                  color: tokens.hover.withValues(alpha: 0.55),
                  borderRadius: tokens.actionRadius,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildActionList(
    WindowsNeoTokens tokens,
    ThemeData theme,
    List<_PaletteAction> actions,
    int safeIndex,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(8),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final item = actions[index];
        final selected = index == safeIndex;
        return Material(
          color: selected ? tokens.accentSurface : Colors.transparent,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: tokens.actionRadius,
                border: selected
                    ? Border.all(
                        color: tokens.accentBorder.withValues(alpha: 0.48),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Icon(
                    item.icon,
                    size: 18,
                    color: selected ? tokens.accentInk : tokens.muted,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: tokens.ink,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                          ),
                        ),
                        Text(
                          item.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
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
    );
  }

  Widget _buildFooter(WindowsNeoTokens tokens, ThemeData theme) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.background.withValues(alpha: 0.72),
        border: Border(
          top: BorderSide(color: tokens.border.withValues(alpha: 0.42)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '直接输入搜索 · 支持 BV / av / 链接直达 · 输入 > 切换主题与控制工作区',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return Material(
      color: selected ? tokens.accentSurface : Colors.transparent,
      borderRadius: tokens.actionRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        hoverColor: tokens.hover,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            borderRadius: tokens.actionRadius,
            border: Border.all(
              color: selected
                  ? tokens.accentBorder.withValues(alpha: 0.55)
                  : tokens.border.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: selected ? tokens.accentInk : tokens.muted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: selected ? tokens.accentInk : tokens.muted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickRecommendBanner extends StatelessWidget {
  const _QuickRecommendBanner({required this.keyword, required this.onTap});

  final String keyword;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return Material(
      color: tokens.accentSurface,
      borderRadius: tokens.actionRadius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: tokens.actionRadius,
            border: Border.all(
              color: tokens.accentBorder.withValues(alpha: 0.48),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome_rounded, size: 15, color: tokens.accentInk),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '猜你想搜：$keyword',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: tokens.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const WindowsNeoTag(text: 'Enter', tone: WindowsNeoTagTone.accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryChip extends StatefulWidget {
  const _HistoryChip({
    required this.label,
    required this.onTap,
    required this.onDelete,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  State<_HistoryChip> createState() => _HistoryChipState();
}

class _HistoryChipState extends State<_HistoryChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? tokens.accentSurface : tokens.surfaceRaised,
        borderRadius: tokens.actionRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 180),
            padding: const EdgeInsets.fromLTRB(9, 5, 6, 5),
            decoration: BoxDecoration(
              borderRadius: tokens.actionRadius,
              border: Border.all(
                color: _hovered
                    ? tokens.accentBorder.withValues(alpha: 0.65)
                    : tokens.border.withValues(alpha: 0.48),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: tokens.ink,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: widget.onDelete,
                  child: Icon(
                    Icons.close_rounded,
                    size: 13,
                    color: _hovered ? tokens.accentInk : tokens.muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PaletteTrendingCell extends StatefulWidget {
  const _PaletteTrendingCell({
    required this.item,
    required this.isPinned,
    required this.rank,
    required this.onTap,
  });

  final SearchTrendingItemModel item;
  final bool isPinned;
  final int rank;
  final VoidCallback onTap;

  @override
  State<_PaletteTrendingCell> createState() => _PaletteTrendingCellState();
}

class _PaletteTrendingCellState extends State<_PaletteTrendingCell> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final theme = Theme.of(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: _hovered ? tokens.accentSurface : tokens.surfaceRaised,
        borderRadius: tokens.actionRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: context.windowsNeoDuration(tokens.motionFast),
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              borderRadius: tokens.actionRadius,
              border: Border.all(
                color: _hovered
                    ? tokens.accentBorder.withValues(alpha: 0.72)
                    : tokens.border.withValues(alpha: 0.40),
              ),
            ),
            child: Row(
              children: [
                WindowsNeoTrendingRank(
                  rank: widget.rank,
                  isPinned: widget.isPinned,
                  fontSize: 12.5,
                  width: 22,
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    widget.item.showName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.ink,
                      fontWeight: widget.isPinned || widget.rank <= 3
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                WindowsNeoTrendingTag(
                  item: widget.item,
                  isPinned: widget.isPinned,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
