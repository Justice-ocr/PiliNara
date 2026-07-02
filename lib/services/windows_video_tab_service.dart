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
    tabs.removeWhere((item) => item.id == id);
    if (activeId.value == id) {
      activeId.value = null;
    }
  }

  static void clear() {
    tabs.clear();
    activeId.value = null;
  }

  static Future<void>? open(
    WindowsVideoTabItem item, {
    bool replace = true,
  }) {
    if (!enabled) return null;
    activeId.value = item.id;
    final args = Map<String, dynamic>.from(item.arguments)
      ..remove('fromPip');
    if (replace) {
      return Get.offNamed(
        '/videoV',
        arguments: args,
        preventDuplicates: false,
      );
    }
    return Get.toNamed(
      '/videoV',
      arguments: args,
      preventDuplicates: false,
    );
  }
}
