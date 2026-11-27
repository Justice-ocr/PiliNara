import 'package:PiliPlus/pages/setting/models/style_settings.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_theme_studio.dart';
import 'package:material_ui/material_ui.dart';

class StyleSetting extends StatefulWidget {
  const StyleSetting({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<StyleSetting> createState() => _StyleSettingState();
}

class _StyleSettingState extends State<StyleSetting> {
  final settings = styleSettings;

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    final showStudio = WindowsVideoTabService.enabled;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: showAppBar ? AppBar(title: const Text('外观设置')) : null,
      body: ListView.builder(
        padding: EdgeInsets.only(
          left: showAppBar ? padding.left : 0,
          right: showAppBar ? padding.right : 0,
          bottom: padding.bottom + 100,
        ),
        itemCount: settings.length + (showStudio ? 1 : 0),
        itemBuilder: (context, index) {
          if (showStudio && index == 0) {
            return const WindowsNeoThemeStudio();
          }
          return settings[index - (showStudio ? 1 : 0)].widget;
        },
      ),
    );
  }
}
