import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/pages/webdav/webdav.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

class WebDavSettingPage extends StatefulWidget {
  const WebDavSettingPage({
    super.key,
    this.showAppBar = true,
  });

  final bool showAppBar;

  @override
  State<WebDavSettingPage> createState() => _WebDavSettingPageState();
}

class _WebDavSettingPageState extends State<WebDavSettingPage> {
  final _uriCtr = TextEditingController(text: Pref.webdavUri);
  final _usernameCtr = TextEditingController(text: Pref.webdavUsername);
  final _passwordCtr = TextEditingController(text: Pref.webdavPassword);
  final _directoryCtr = TextEditingController(text: Pref.webdavDirectory);
  bool _obscureText = true;

  @override
  void dispose() {
    _uriCtr.dispose();
    _usernameCtr.dispose();
    _passwordCtr.dispose();
    _directoryCtr.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    await GStorage.setting.putAll({
      SettingBoxKey.webdavUri: _uriCtr.text,
      SettingBoxKey.webdavUsername: _usernameCtr.text,
      SettingBoxKey.webdavPassword: _passwordCtr.text,
      SettingBoxKey.webdavDirectory: _directoryCtr.text,
    });
    if (_uriCtr.text.isEmpty) {
      return;
    }
    try {
      final res = await WebDav().init();
      if (res.first) {
        SmartDialog.showToast('配置成功');
      } else {
        SmartDialog.showToast('配置失败: ${res.second}');
      }
    } catch (e) {
      SmartDialog.showToast('配置失败: ${e.toString()}');
    }
  }

  Widget _buildForm(bool isWindowsNeo) {
    return Column(
      children: [
        TextField(
          controller: _uriCtr,
          decoration: const InputDecoration(
            labelText: '地址',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _usernameCtr,
          decoration: const InputDecoration(
            labelText: '用户',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _passwordCtr,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: '密码',
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              tooltip: _obscureText ? '显示密码' : '隐藏密码',
              onPressed: () => setState(() => _obscureText = !_obscureText),
              icon: _obscureText
                  ? const Icon(Icons.visibility)
                  : const Icon(Icons.visibility_off),
            ),
          ),
          obscureText: _obscureText,
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _directoryCtr,
          decoration: const InputDecoration(
            labelText: '路径',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: isWindowsNeo
                  ? FilledButton.tonalIcon(
                      onPressed: WebDav().backup,
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('备份设置'),
                    )
                  : FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: Style.mdRadius,
                        ),
                      ),
                      onPressed: WebDav().backup,
                      child: const Text('备份设置'),
                    ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: isWindowsNeo
                  ? FilledButton.tonalIcon(
                      onPressed: WebDav().restore,
                      icon: const Icon(Icons.cloud_download_outlined, size: 18),
                      label: const Text('恢复设置'),
                    )
                  : FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        shape: const RoundedRectangleBorder(
                          borderRadius: Style.mdRadius,
                        ),
                      ),
                      onPressed: WebDav().restore,
                      child: const Text('恢复设置'),
                    ),
            ),
          ],
        ),
        if (isWindowsNeo) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _saveSettings,
              icon: const Icon(Icons.save_outlined, size: 18),
              label: const Text('保存并验证配置'),
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAppBar = widget.showAppBar;
    final padding = MediaQuery.viewPaddingOf(context);
    final isWindowsNeo = WindowsVideoTabService.enabled;
    Widget form = _buildForm(isWindowsNeo);
    if (isWindowsNeo) {
      form = DecoratedBox(
        decoration: BoxDecoration(
          color: context.windowsNeo.surface,
          border: Border.all(color: context.windowsNeo.border),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(padding: const EdgeInsets.all(20), child: form),
      );
    }
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      appBar: showAppBar ? AppBar(title: const Text('WebDAV 设置')) : null,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView(
            padding: padding.copyWith(
              top: 20,
              left: isWindowsNeo ? 18 : 20 + (showAppBar ? padding.left : 0),
              right: isWindowsNeo ? 18 : 20 + (showAppBar ? padding.right : 0),
              bottom: padding.bottom + 100,
            ),
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isWindowsNeo ? 720 : double.infinity,
                  ),
                  child: form,
                ),
              ),
            ],
          ),
          if (!isWindowsNeo)
            Positioned(
              right:
                  kFloatingActionButtonMargin +
                  (showAppBar ? padding.right : 0),
              bottom: kFloatingActionButtonMargin + padding.bottom,
              child: FloatingActionButton(
                onPressed: _saveSettings,
                child: const Icon(Icons.save),
              ),
            ),
        ],
      ),
    );
  }
}
