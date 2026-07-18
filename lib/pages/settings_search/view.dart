import 'package:PiliPlus/common/widgets/loading_widget/http_error.dart';
import 'package:PiliPlus/common/widgets/view_sliver_safe_area.dart';
import 'package:PiliPlus/pages/search/controller.dart' show DebounceStreamState;
import 'package:PiliPlus/pages/setting/models/dynamics_settings.dart';
import 'package:PiliPlus/pages/setting/models/extra_settings.dart';
import 'package:PiliPlus/pages/setting/models/block_settings.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/models/play_settings.dart';
import 'package:PiliPlus/pages/setting/models/privacy_settings.dart';
import 'package:PiliPlus/pages/setting/models/recommend_settings.dart';
import 'package:PiliPlus/pages/setting/models/style_settings.dart';
import 'package:PiliPlus/pages/setting/models/video_settings.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/grid.dart';
import 'package:PiliPlus/utils/waterfall.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:waterfall_flow/waterfall_flow.dart'
    hide SliverWaterfallFlowDelegateWithMaxCrossAxisExtent;

class SettingsSearchPage extends StatefulWidget {
  const SettingsSearchPage({super.key});

  @override
  State<SettingsSearchPage> createState() => _SettingsSearchPageState();
}

class _SettingsSearchPageState
    extends DebounceStreamState<SettingsSearchPage, String> {
  final _textEditingController = TextEditingController();
  final RxList<SettingsModel> _list = <SettingsModel>[].obs;
  late final _settings = [
    ...extraSettings,
    ...privacySettings,
    ...blockSettings,
    ...recommendSettings,
    ...dynamicsSettings,
    ...videoSettings,
    ...playSettings,
    ...styleSettings,
  ];

  @override
  void onValueChanged(String value) {
    if (value.isEmpty) {
      _list.clear();
    } else {
      value = value.toLowerCase();
      _list.value = _settings
          .where(
            (item) =>
                item.effectiveTitle.toLowerCase().contains(value) ||
                item.effectiveSubtitle?.toLowerCase().contains(value) == true,
          )
          .toList();
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WindowsVideoTabService.enabled
          ? context.windowsNeo.background
          : null,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              if (_textEditingController.text.isNotEmpty) {
                _textEditingController.clear();
                _list.clear();
              } else {
                Get.back();
              }
            },
            icon: const Icon(Icons.clear),
          ),
          const SizedBox(width: 10),
        ],
        title: TextField(
          autofocus: true,
          controller: _textEditingController,
          textAlignVertical: TextAlignVertical.center,
          onChanged: ctr!.add,
          decoration: InputDecoration(
            isDense: true,
            hintText: WindowsVideoTabService.enabled ? '搜索设置' : '鎼滅储',
            visualDensity: VisualDensity.standard,
            border: WindowsVideoTabService.enabled
                ? OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(color: context.windowsNeo.border),
                  )
                : InputBorder.none,
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          ViewSliverSafeArea(
            sliver: SliverPadding(
              padding: EdgeInsets.fromLTRB(
                WindowsVideoTabService.enabled ? 20 : 0,
                WindowsVideoTabService.enabled ? 16 : 0,
                WindowsVideoTabService.enabled ? 20 : 0,
                WindowsVideoTabService.enabled ? 100 : 0,
              ),
              sliver: Obx(
                () => _list.isEmpty
                    ? const HttpError()
                    : SliverWaterfallFlow(
                        gridDelegate:
                            SliverWaterfallFlowDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: WindowsVideoTabService.enabled
                                  ? 440
                                  : Grid.smallCardWidth * 2,
                              mainAxisSpacing: WindowsVideoTabService.enabled
                                  ? 12
                                  : 0,
                              crossAxisSpacing: WindowsVideoTabService.enabled
                                  ? 12
                                  : 0,
                            ),
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => _list[index].widget,
                          childCount: _list.length,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
