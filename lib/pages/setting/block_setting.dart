import 'package:PiliPlus/pages/setting/models/block_settings.dart';
import 'package:flutter/material.dart';

class BlockSetting extends StatefulWidget {
  const BlockSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<BlockSetting> createState() => _BlockSettingState();
}

class _BlockSettingState extends State<BlockSetting> {
  final settings = blockSettings;

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar(title: const Text('屏蔽与豁免')) : null,
      body: ListView.builder(
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
