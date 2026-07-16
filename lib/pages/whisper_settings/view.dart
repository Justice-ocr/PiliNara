import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart'
    show IMSettingType, Setting;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/whisper_block/view.dart';
import 'package:PiliPlus/pages/whisper_settings/controller.dart';
import 'package:PiliPlus/pages/whisper_settings/widgets/item.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:protobuf/protobuf.dart' show PbMap;

class WhisperSettingsPage extends StatefulWidget {
  const WhisperSettingsPage({
    super.key,
    required this.imSettingType,
    this.onUpdate,
  });

  final IMSettingType imSettingType;
  final ValueChanged<Map<int, Setting>>? onUpdate;

  @override
  State<WhisperSettingsPage> createState() => _WhisperSettingsPageState();
}

class _WhisperSettingsPageState extends State<WhisperSettingsPage> {
  late final WhisperSettingsController _controller;
  @override
  void initState() {
    super.initState();
    _controller = Get.put(
      WhisperSettingsController(imSettingType: widget.imSettingType),
      tag: widget.imSettingType.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: WindowsVideoTabService.enabled
          ? context.windowsNeo.background
          : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Obx(() => Text(_controller.title.value)),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWindowsNeo = WindowsVideoTabService.enabled;
          final horizontal = isWindowsNeo && constraints.maxWidth > 760
              ? (constraints.maxWidth - 720) / 2
              : isWindowsNeo
              ? 20.0
              : 0.0;
          final child = Obx(
            () => _buildBody(theme, _controller.loadingState.value),
          );
          if (!isWindowsNeo) return child;
          return Padding(
            padding: EdgeInsets.fromLTRB(horizontal, 16, horizontal, 0),
            child: Material(
              color: context.windowsNeo.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
                side: BorderSide(color: context.windowsNeo.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          );
        },
      ),
    );
  }

  Future<bool> onSet(
    int key,
    PbMap<int, Setting> response,
    Setting item,
  ) async {
    final settings = {key: item};
    final res = await _controller.onSet(settings);
    if (res) {
      widget.onUpdate?.call(settings);
    }
    return res;
  }

  void onRedirect(
    ThemeData theme,
    int key,
    PbMap<int, Setting> response,
    Setting item,
  ) {
    if (item.redirect.settingPage.hasParentSettingType()) {
      Get.to(
        WhisperSettingsPage(
          imSettingType: item.redirect.settingPage.parentSettingType,
          onUpdate: (value) {
            _controller.loadingState
              ..value.data[key]?.redirect.settingPage.subSettings.addAll(value)
              ..refresh();
          },
        ),
        preventDuplicates: false,
      );
    } else if (item.redirect.hasWindowSelect()) {
      String? selected;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          clipBehavior: Clip.hardEdge,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: item.redirect.windowSelect.item.map(
              (e) {
                if (e.selected) {
                  selected ??= e.text;
                }
                return ListTile(
                  dense: true,
                  onTap: () async {
                    if (!e.selected) {
                      Get.back();
                      for (final j in item.redirect.windowSelect.item) {
                        j.selected = false;
                      }
                      item.redirect.selectedSummary = e.text;
                      e.selected = true;
                      _controller.loadingState.refresh();
                      final settings = {key: item};
                      final res = await _controller.onSet(settings);
                      if (!res) {
                        for (final j in item.redirect.windowSelect.item) {
                          j.selected = j.text == selected;
                        }
                        item.redirect.selectedSummary = selected!;
                        _controller.loadingState.refresh();
                      }
                    }
                  },
                  title: Text(
                    e.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: e.selected ? theme.colorScheme.primary : null,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ),
      );
    } else if (item.redirect.otherPage.hasUrl()) {
      if (item.redirect.title == '黑名单') {
        Get.toNamed('/blackListPage');
      } else if (item.redirect.otherPage.url.startsWith('http')) {
        Get.toNamed(
          '/webview',
          parameters: {'url': item.redirect.otherPage.url},
        );
      } else {
        SmartDialog.showToast(item.redirect.otherPage.url);
      }
    } else if (item.redirect.settingPage.hasUrl()) {
      if (item.redirect.title == '消息屏蔽词') {
        Get.to(const WhisperBlockPage());
      } else if (item.redirect.settingPage.url.startsWith('http')) {
        Get.toNamed(
          '/webview',
          parameters: {'url': item.redirect.settingPage.url},
        );
      } else {
        SmartDialog.showToast(item.redirect.settingPage.url);
      }
    }
  }

  Widget _buildBody(
    ThemeData theme,
    LoadingState<PbMap<int, Setting>> loadingState,
  ) {
    late final divider = Divider(
      height: 1,
      color: WindowsVideoTabService.enabled
          ? context.windowsNeo.border
          : theme.colorScheme.outline.withValues(alpha: 0.1),
    );
    return switch (loadingState) {
      Loading() => const SizedBox.shrink(),
      Success<PbMap<int, Setting>>(:final response) => Builder(
        builder: (context) {
          final keys = response.keys.toList()..sort();
          return ListView.separated(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
            ),
            itemCount: keys.length,
            itemBuilder: (context, index) {
              final key = keys[index];
              final item = response[key]!;
              return ImSettingsItem(
                item: item,
                onSet: () => onSet(key, response, item),
                onRedirect: () => onRedirect(theme, key, response, item),
              );
            },
            separatorBuilder: (context, index) => divider,
          );
        },
      ),
      Error(:final errMsg) => scrollErrorWidget(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }
}
