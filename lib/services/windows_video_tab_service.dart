import 'dart:io' show Platform;

import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:get/get.dart';

class WindowsVideoTabItem {
  WindowsVideoTabItem({
    required this.id,
    required this.arguments,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final Map<String, dynamic> arguments;
  final DateTime createdAt;
  DateTime updatedAt;

  String get title {
    final value = arguments['title'];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    final bvid = arguments['bvid'];
    if (bvid is String && bvid.isNotEmpty) {
      return bvid;
    }
    final aid = arguments['aid'];
    if (aid != null) {
      return 'av$aid';
    }
    return '视频';
  }

  String get subtitle {
    final parts = <String>[];
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

abstract final class WindowsVideoTabService {
  static final RxList<WindowsVideoTabItem> tabs =
      <WindowsVideoTabItem>[].obs;
  static final RxnString activeId = RxnString();
  static final Map<String, void Function()> _activators = {};
  static final Map<String, void Function()> _closers = {};
  static final Map<String, _WindowsVideoTabPlayer> _players = {};

  static bool get enabled => Platform.isWindows && Pref.enableWindowsVideoTabs;

  static String keyFromArgs(Map arguments) {
    final bvid = arguments['bvid']?.toString();
    final cid = arguments['cid']?.toString();
    final epId = arguments['epId']?.toString();
    final seasonId = arguments['seasonId']?.toString();
    return [bvid, cid, epId, seasonId]
        .where((item) => item != null && item.isNotEmpty)
        .join(':');
  }

  static void upsert(Map arguments) {
    if (!enabled) return;
    final normalized = Map<String, dynamic>.from(arguments);
    final id = keyFromArgs(normalized);
    if (id.isEmpty) return;

    final index = tabs.indexWhere((item) => item.id == id);
    if (index == -1) {
      final now = DateTime.now();
      tabs.add(
        WindowsVideoTabItem(
          id: id,
          arguments: normalized,
          createdAt: now,
          updatedAt: now,
        ),
      );
    } else {
      final tab = tabs[index];
      tab.arguments
        ..clear()
        ..addAll(normalized);
      tab.updatedAt = DateTime.now();
      tabs.refresh();
    }
    activeId.value = id;
  }

  static void updateProgress(Map arguments, Duration? progress) {
    if (!enabled || progress == null) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    final index = tabs.indexWhere((item) => item.id == id);
    if (index == -1) return;
    tabs[index].arguments['progress'] = progress.inMilliseconds;
    tabs[index].updatedAt = DateTime.now();
    tabs.refresh();
  }

  static bool has(String id) => tabs.any((item) => item.id == id);

  static void setActive(Map arguments) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isNotEmpty && has(id)) {
      activeId.value = id;
    }
  }

  static void close(String id) {
    _closers.remove(id)?.call();
    _activators.remove(id);
    _players.remove(id)?.dispose();
    tabs.removeWhere((item) => item.id == id);
    if (activeId.value == id) {
      activeId.value = null;
    }
  }

  static void clear() {
    final closers = List<void Function()>.from(_closers.values);
    _closers.clear();
    _activators.clear();
    for (final close in closers) {
      close();
    }
    for (final cached in _players.values) {
      cached.dispose();
    }
    _players.clear();
    tabs.clear();
    activeId.value = null;
  }

  static T? takePlayer<T extends Object>(Map arguments) {
    final id = keyFromArgs(arguments);
    final cached = _players.remove(id);
    if (cached == null) return null;
    if (cached.player case final T player) {
      return player;
    }
    cached.dispose();
    return null;
  }

  static void keepPlayer<T extends Object>(
    Map arguments,
    T player, {
    required void Function(T player) dispose,
  }) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty || !has(id)) return;
    _players[id] = _WindowsVideoTabPlayer(
      player,
      (player) => dispose(player as T),
    );
  }

  static T? removePlayer<T extends Object>(Map arguments) {
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return null;
    final cached = _players.remove(id);
    if (cached == null) return null;
    if (cached.player case final T player) {
      return player;
    }
    cached.dispose();
    return null;
  }

  static void registerRoute(
    Map arguments, {
    required void Function() activate,
    required void Function() close,
  }) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    _activators[id] = activate;
    _closers[id] = close;
  }

  static void unregisterRoute(Map arguments, void Function() close) {
    if (!enabled) return;
    final id = keyFromArgs(arguments);
    if (id.isEmpty) return;
    if (identical(_closers[id], close)) {
      _closers.remove(id);
      _activators.remove(id);
    }
  }

  static Future<void>? open(WindowsVideoTabItem item) {
    if (!enabled) return null;
    activeId.value = item.id;
    final activate = _activators[item.id];
    if (activate != null) {
      activate();
      return null;
    }
    final args = Map<String, dynamic>.from(item.arguments)
      ..remove('fromPip');
    return Get.toNamed(
      '/videoV',
      arguments: args,
      preventDuplicates: false,
    );
  }
}

class _WindowsVideoTabPlayer {
  const _WindowsVideoTabPlayer(this.player, this._dispose);

  final Object player;
  final void Function(Object player) _dispose;

  void dispose() => _dispose(player);
}
