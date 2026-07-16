import 'dart:math' show max;

import 'package:PiliPlus/common/widgets/reorder_mixin.dart';
import 'package:PiliPlus/http/follow.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/models/member/tags.dart';
import 'package:PiliPlus/pages/follow/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/bili_utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class FollowTagSortPage extends StatefulWidget {
  const FollowTagSortPage({super.key, required this.controller});

  final FollowController controller;

  @override
  State<FollowTagSortPage> createState() => _FollowTagSortPageState();
}

class _FollowTagSortPageState extends State<FollowTagSortPage>
    with ReorderMixin {
  final List<MemberTagItemModel> _defTags = <MemberTagItemModel>[];
  final List<MemberTagItemModel> _customTags = <MemberTagItemModel>[];

  @override
  void initState() {
    super.initState();
    for (final e in widget.controller.tabs) {
      if (BiliUtils.isCustomFollowTag(e.tagid)) {
        _customTags.add(e);
      } else {
        _defTags.add(e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    return Scaffold(
      backgroundColor: isWindowsNeo ? context.windowsNeo.background : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('关注分组排序'),
        actions: _customTags.isNotEmpty
            ? [
                if (isWindowsNeo)
                  IconButton(
                    tooltip: '保存排序',
                    onPressed: _saveOrder,
                    icon: const Icon(Icons.save_outlined),
                  )
                else
                  TextButton(
                    onPressed: _saveOrder,
                    child: const Text('完成'),
                  ),
                const SizedBox(width: 16),
              ]
            : null,
      ),
      body: _buildBody,
    );
  }

  void onReorderItem(int oldIndex, int newIndex) {
    _customTags.insert(newIndex, _customTags.removeAt(oldIndex));
    setState(() {});
  }

  Widget get _buildBody {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final horizontalPadding = max(
      18.0,
      (MediaQuery.sizeOf(context).width - 720) / 2,
    );
    return ReorderableListView.builder(
      onReorderItem: onReorderItem,
      proxyDecorator: proxyDecorator,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(
        left: isWindowsNeo ? horizontalPadding : 0,
        top: isWindowsNeo ? 16 : 0,
        right: isWindowsNeo ? horizontalPadding : 0,
        bottom: MediaQuery.viewPaddingOf(context).bottom + 100,
      ),
      header: Column(
        children: _defTags.map((e) => _buildItem(e, enabled: false)).toList(),
      ),
      itemCount: _customTags.length,
      itemBuilder: (context, index) {
        return _buildItem(_customTags[index]);
      },
    );
  }

  Widget _buildItem(
    MemberTagItemModel item, {
    bool enabled = true,
  }) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final child = ListTile(
      textColor: enabled ? null : scheme.outline,
      key: isWindowsNeo ? null : ValueKey(item.tagid),
      leading: enabled
          ? const Icon(Icons.group_outlined)
          : Icon(
              size: 23,
              Icons.lock_outline,
              color: scheme.outline,
            ),
      minLeadingWidth: 0,
      title: Text('${item.name} (${item.count})'),
      subtitle: item.tip?.isNotEmpty == true ? Text(item.tip!) : null,
    );
    if (!isWindowsNeo) return child;
    return Padding(
      key: ValueKey(item.tagid),
      padding: const EdgeInsets.only(bottom: 12),
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
  }

  Future<void> _saveOrder() async {
    final res = await FollowHttp.sortFollowTag(
      tagids: _customTags.map((e) => e.tagid).join(','),
    );
    if (res.isSuccess) {
      SmartDialog.showToast('排序完成');
      final tabs = _defTags + _customTags;
      widget.controller
        ..tabs.value = tabs
        ..onInitTab()
        ..followState.value = Success(tabs.hashCode);
      if (mounted) {
        Get.back();
      }
    } else {
      res.toast();
    }
  }
}
