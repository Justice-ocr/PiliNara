/// Describes the content hosted by a Windows workspace tab.
///
/// A workspace tab is the common container for media, tool pages, and
/// navigation roots. This intentionally does not describe its visual style:
/// Windows Neo components render the same tab contract without owning its
/// identity or lifecycle.
enum WindowsWorkspaceTabType {
  home,
  search,
  video,
  live,
  member,
  dynamic,
  tool,
}

/// Compatibility names for Windows page code that has not yet migrated to the
/// workspace terminology. New workspace modules use the names above.
typedef WindowsMediaTabType = WindowsWorkspaceTabType;

enum WindowsWorkspaceTabCapability {
  close,
  pin,
  split,
  audio,
}

class WindowsTabRouteData {
  const WindowsTabRouteData({
    this.arguments,
    this.parameters = const {},
  });

  final Object? arguments;
  final Map<String, String> parameters;
}

/// The single persisted model for every Windows workspace tab.
///
/// Do not create parallel tool-tab models: tool pages are simply
/// [WindowsWorkspaceTabType.tool] tabs with a registered route.
class WindowsWorkspaceTab {
  WindowsWorkspaceTab({
    required this.id,
    required this.type,
    required this.arguments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final WindowsWorkspaceTabType type;
  final Map<String, dynamic> arguments;
  final DateTime createdAt;
  DateTime updatedAt;

  bool get isHome => type == WindowsWorkspaceTabType.home;
  bool get isTool => type == WindowsWorkspaceTabType.tool;
  bool get isHeavyMedia =>
      type == WindowsWorkspaceTabType.video ||
      type == WindowsWorkspaceTabType.live;

  bool get canClose => !isHome;
  bool get canPin => !isHome;
  bool get canSplit => isHeavyMedia;
  bool get supportsAudio => isHeavyMedia;

  Set<WindowsWorkspaceTabCapability> get capabilities => {
        if (canClose) WindowsWorkspaceTabCapability.close,
        if (canPin) WindowsWorkspaceTabCapability.pin,
        if (canSplit) WindowsWorkspaceTabCapability.split,
        if (supportsAudio) WindowsWorkspaceTabCapability.audio,
      };

  String get rootRoute => switch (type) {
        WindowsWorkspaceTabType.home => '/',
        WindowsWorkspaceTabType.search => '/searchResult',
        WindowsWorkspaceTabType.live => '/liveRoom',
        WindowsWorkspaceTabType.video => '/videoV',
        WindowsWorkspaceTabType.member => '/member',
        WindowsWorkspaceTabType.dynamic => '/dynamicDetail',
        WindowsWorkspaceTabType.tool => arguments['tabRoute']?.toString() ?? '',
      };

  /// Restores only data that belongs to the tab itself. Runtime callbacks,
  /// navigator keys, and player instances deliberately live outside this
  /// model and must never be copied into closed-tab history.
  WindowsWorkspaceTab copyForRestore({DateTime? restoredAt}) =>
      WindowsWorkspaceTab(
        id: id,
        type: type,
        arguments: Map<String, dynamic>.from(arguments),
        createdAt: createdAt,
        updatedAt: restoredAt ?? updatedAt,
      );

  /// Replaces route payload while keeping user-owned tab state by default.
  void replaceArguments(
    Map<String, dynamic> next, {
    bool retainTitle = true,
    bool retainPinned = true,
  }) {
    final previousTitle = arguments['title'];
    final wasPinned = arguments['pinned'] == true;
    arguments
      ..clear()
      ..addAll(next);
    if (retainTitle &&
        !arguments.containsKey('title') &&
        previousTitle != null) {
      arguments['title'] = previousTitle;
    }
    if (retainPinned && wasPinned) arguments['pinned'] = true;
    updatedAt = DateTime.now();
  }

  String get title {
    if (isHome) {
      return '主页';
    }
    final value = arguments['title'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (type == WindowsWorkspaceTabType.search) {
      final keyword = arguments['keyword'];
      if (keyword != null && keyword.toString().trim().isNotEmpty) {
        return '搜索: ${keyword.toString().trim()}';
      }
      return '搜索';
    }
    if (type == WindowsWorkspaceTabType.member) {
      final mid = arguments['mid'];
      return mid == null ? '用户空间' : '用户 $mid';
    }
    if (type == WindowsWorkspaceTabType.dynamic) {
      return '动态详情';
    }
    if (isTool) {
      return arguments['title']?.toString() ?? '工具';
    }
    final bvid = arguments['bvid'];
    if (bvid is String && bvid.isNotEmpty) {
      return bvid;
    }
    final aid = arguments['aid'];
    if (aid != null) {
      return 'av$aid';
    }
    final roomId = arguments['roomId'] ?? arguments['id'];
    if (roomId != null) {
      return '直播间 $roomId';
    }
    return type == WindowsWorkspaceTabType.live ? '直播间' : '视频';
  }

  String get subtitle {
    if (isHome) {
      return '';
    }
    final parts = <String>[];
    if (type == WindowsWorkspaceTabType.search) {
      final index = arguments['initIndex'];
      if (index != null) {
        parts.add('tab $index');
      }
      return parts.join(' 路 ');
    }
    if (type == WindowsWorkspaceTabType.live) {
      final roomId = arguments['roomId'] ?? arguments['id'];
      if (roomId != null) {
        parts.add('room $roomId');
      }
      return parts.join(' · ');
    }
    if (type == WindowsWorkspaceTabType.member && arguments['mid'] != null) {
      return 'UID ${arguments['mid']}';
    }
    if (type == WindowsWorkspaceTabType.dynamic &&
        arguments['dynamicId'] != null) {
      return 'ID ${arguments['dynamicId']}';
    }
    if (arguments['bvid'] case final String bvid when bvid.isNotEmpty) {
      parts.add(bvid);
    }
    if (arguments['cid'] case final int cid) {
      parts.add('cid $cid');
    }
    if (arguments['progress'] case final int progress when progress > 0) {
      parts.add(_formatProgress(Duration(milliseconds: progress)));
    }
    return parts.join(' · ');
  }

  static String _formatProgress(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

typedef WindowsVideoTabItem = WindowsWorkspaceTab;

/// Centralizes stable tab identity and wire-format compatibility.
///
/// No page or visual component should hand-roll a tab id. Keeping identity in
/// the model makes duplicates, closed-tab restore, and future session restore
/// follow the same rule for media and tool tabs.
abstract final class WindowsWorkspaceTabIdentity {
  static Map<String, dynamic> normalizeArguments(
    Map arguments,
    WindowsWorkspaceTabType type,
  ) =>
      Map<String, dynamic>.from(arguments)..['mediaTabType'] = type.name;

  static WindowsWorkspaceTabType typeFromArguments(Map arguments) {
    final type = arguments['mediaTabType'];
    if (type == WindowsWorkspaceTabType.home || type == 'home') {
      return WindowsWorkspaceTabType.home;
    }
    if (type == WindowsWorkspaceTabType.live || type == 'live') {
      return WindowsWorkspaceTabType.live;
    }
    if (type == WindowsWorkspaceTabType.search || type == 'search') {
      return WindowsWorkspaceTabType.search;
    }
    if (type == WindowsWorkspaceTabType.member || type == 'member') {
      return WindowsWorkspaceTabType.member;
    }
    if (type == WindowsWorkspaceTabType.dynamic || type == 'dynamic') {
      return WindowsWorkspaceTabType.dynamic;
    }
    if (type == WindowsWorkspaceTabType.tool || type == 'tool') {
      return WindowsWorkspaceTabType.tool;
    }
    return WindowsWorkspaceTabType.video;
  }

  static String keyFromArguments(Map arguments) {
    final type = typeFromArguments(arguments);
    if (type == WindowsWorkspaceTabType.home) return 'home';
    if (type == WindowsWorkspaceTabType.live) {
      final roomId =
          arguments['roomId']?.toString() ?? arguments['id']?.toString();
      return roomId == null || roomId.isEmpty ? '' : 'live:$roomId';
    }
    if (type == WindowsWorkspaceTabType.search) {
      final keyword = arguments['keyword']?.toString();
      return keyword == null || keyword.isEmpty ? '' : 'search:$keyword';
    }
    if (type == WindowsWorkspaceTabType.member) {
      final mid = arguments['mid']?.toString();
      return mid == null || mid.isEmpty ? '' : 'member:$mid';
    }
    if (type == WindowsWorkspaceTabType.dynamic) {
      final dynamicId = arguments['dynamicId']?.toString();
      return dynamicId == null || dynamicId.isEmpty ? '' : 'dynamic:$dynamicId';
    }
    if (type == WindowsWorkspaceTabType.tool) {
      final route = arguments['tabRoute']?.toString();
      return route == null || route.isEmpty ? '' : 'tool:$route';
    }
    final key = [
      arguments['bvid']?.toString(),
      arguments['cid']?.toString(),
      arguments['epId']?.toString(),
      arguments['seasonId']?.toString(),
    ].where((item) => item != null && item.isNotEmpty).join(':');
    return key.isEmpty ? '' : 'video:$key';
  }
}
