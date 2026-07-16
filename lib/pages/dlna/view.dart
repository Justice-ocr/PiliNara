import 'dart:async';
import 'dart:math' show max;

import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/common/widgets/view_sliver_safe_area.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:dlna_dart/dlna.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class DLNAPage extends StatefulWidget {
  const DLNAPage({super.key});

  @override
  State<DLNAPage> createState() => _DLNAPageState();
}

class _DLNAPageState extends State<DLNAPage> {
  final _searcher = DLNAManager();
  final Map<String, DLNADevice> _deviceList = {};
  late final _url = Get.parameters['url']!;
  late final _title = Get.parameters['title'];

  Timer? _timer;
  bool _isSearching = false;
  DLNADevice? _lastDevice;
  String? _lastDeviceKey;

  @override
  void initState() {
    super.initState();
    _onSearch(isInit: true);
  }

  Future<void> _onSearch({bool isInit = false}) async {
    if (_isSearching) return;
    _isSearching = true;
    if (!isInit && mounted) {
      _lastDevice = null;
      _deviceList.clear();
      setState(() {});
    }
    final deviceManager = await _searcher.start();
    if (!mounted) {
      return;
    }
    _timer = Timer(const Duration(seconds: 20), _searcher.stop);
    await for (final deviceList in deviceManager.devices.stream) {
      if (mounted) {
        _deviceList.addAll(deviceList);
        setState(() {});
      }
    }
    if (mounted) {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    _searcher.stop();
    _lastDevice = null;
    _lastDeviceKey = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final horizontalPadding = max(
      18.0,
      (MediaQuery.sizeOf(context).width - 820) / 2,
    );
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('投屏'),
        actions: [
          IconButton(
            tooltip: '搜索',
            onPressed: _onSearch,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          if (_isSearching) linearLoading,
          if (isWindowsNeo)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                MediaQuery.viewPaddingOf(context).bottom + 100,
              ),
              sliver: _buildBody(colorScheme),
            )
          else
            ViewSliverSafeArea(sliver: _buildBody(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (!_isSearching && _deviceList.isEmpty) {
      return HttpError(
        errMsg: '没有设备',
        onReload: _onSearch,
      );
    }
    if (_deviceList.isNotEmpty) {
      final keys = _deviceList.keys.toList();
      return SliverList.separated(
        itemCount: keys.length,
        itemBuilder: (context, index) {
          final key = keys[index];
          final device = _deviceList[key]!;
          final isCurr = key == _lastDeviceKey;
          final tile = ListTile(
            title: Text(
              device.info.friendlyName,
              style: isCurr ? TextStyle(color: colorScheme.primary) : null,
            ),
            subtitle: Text(key),
            onTap: () async {
              if (isCurr) return;
              _lastDevice?.pause();
              _lastDevice = device;
              _lastDeviceKey = key;
              setState(() {});
              await device.setUrl(_url, title: _title ?? '');
              await device.play();
            },
          );
          if (!WindowsVideoTabService.enabled) return tile;
          return Material(color: context.windowsNeo.surface, child: tile);
        },
        separatorBuilder: (_, _) => WindowsVideoTabService.enabled
            ? Divider(height: 1, color: context.windowsNeo.border)
            : const SizedBox.shrink(),
      );
    }
    return const SliverToBoxAdapter();
  }
}
