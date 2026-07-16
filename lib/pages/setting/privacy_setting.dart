import 'dart:math' show max;

import 'package:PiliPlus/pages/setting/models/privacy_settings.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class PrivacySetting extends StatefulWidget {
  const PrivacySetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<PrivacySetting> createState() => _PrivacySettingState();
}

class _PrivacySettingState extends State<PrivacySetting> {
  final settings = privacySettings;

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final list = ListView(
      padding: EdgeInsets.only(
        left: showAppBar ? padding.left : 0,
        right: showAppBar ? padding.right : 0,
        bottom: padding.bottom + 100,
      ),
      children: settings.map((item) => item.widget).toList(),
    );
    return Scaffold(
      backgroundColor: isWindowsNeo && showAppBar
          ? context.windowsNeo.background
          : null,
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar(title: const Text('隐私设置')) : null,
      body: isWindowsNeo && showAppBar
          ? Padding(
              padding: EdgeInsets.fromLTRB(
                18,
                16,
                18,
                max(18, padding.bottom),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Material(
                    color: context.windowsNeo.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                      side: BorderSide(color: context.windowsNeo.border),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: list,
                  ),
                ),
              ),
            )
          : list,
    );
  }
}
