import 'package:PiliPlus/models/common/setting_type.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/pages/setting/models/block_settings.dart';
import 'package:PiliPlus/pages/setting/models/dynamics_settings.dart';
import 'package:PiliPlus/pages/setting/models/extra_settings.dart';
import 'package:PiliPlus/pages/setting/models/play_settings.dart';
import 'package:PiliPlus/pages/setting/models/privacy_settings.dart';
import 'package:PiliPlus/pages/setting/models/recommend_settings.dart';
import 'package:PiliPlus/pages/setting/models/style_settings.dart';
import 'package:PiliPlus/pages/setting/models/video_settings.dart';
import 'package:flutter/material.dart';

class CommonSetting extends StatefulWidget {
  const CommonSetting({
    super.key,
    required this.settingType,
    this.showAppBar = true,
  });

  final bool showAppBar;
  final SettingType settingType;

  @override
  State<CommonSetting> createState() => _CommonSettingState();
}

class _CommonSettingState extends State<CommonSetting> {
  late EdgeInsets padding;
  late List<SettingsModel> settings;

  void _initSetting() {
    settings = switch (widget.settingType) {
      SettingType.privacySetting => privacySettings,
      SettingType.blockSetting => blockSettings,
      SettingType.recommendSetting => recommendSettings,
      SettingType.dynamicsSetting => dynamicsSettings,
      SettingType.videoSetting => videoSettings,
      SettingType.playSetting => playSettings,
      SettingType.styleSetting => styleSettings,
      SettingType.extraSetting => extraSettings,
      _ => const <SettingsModel>[],
    };
  }

  @override
  void initState() {
    super.initState();
    _initSetting();
  }

  @override
  void didUpdateWidget(CommonSetting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.settingType != oldWidget.settingType) {
      _initSetting();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    padding = MediaQuery.viewPaddingOf(context);
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar(title: Text(widget.settingType.title)) : null,
      body: ListView.builder(
        key: ValueKey(widget.settingType),
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        itemCount: settings.length,
        itemBuilder: (context, index) => settings[index].widget,
      ),
    );
  }
}
