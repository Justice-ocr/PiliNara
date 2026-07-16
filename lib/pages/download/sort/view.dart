import 'package:PiliPlus/models_new/download/bili_download_entry_info.dart';
import 'package:PiliPlus/pages/common/multi_select/base.dart';
import 'package:PiliPlus/pages/download/detail/widgets/item.dart';
import 'package:PiliPlus/services/download/download_service.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';

class DownloadVideoSortPage extends StatefulWidget {
  const DownloadVideoSortPage({
    super.key,
    required this.title,
    required this.entries,
    required this.onSave,
  });

  final String title;
  final List<BiliDownloadEntryInfo> entries;
  final Future<void> Function(List<int> cids) onSave;

  @override
  State<DownloadVideoSortPage> createState() => _DownloadVideoSortPageState();
}

class _DownloadVideoSortPageState extends State<DownloadVideoSortPage> {
  final _downloadService = Get.find<DownloadService>();
  final _controller = _NoopMultiSelect();
  late final List<BiliDownloadEntryInfo> _sortList =
      List<BiliDownloadEntryInfo>.from(widget.entries);

  void _onReorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = _sortList.removeAt(oldIndex);
    _sortList.insert(newIndex, item);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WindowsVideoTabService.enabled
          ? context.windowsNeo.background
          : null,
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          TextButton(
            onPressed: () async {
              await widget.onSave(_sortList.map((item) => item.cid).toList());
              if (mounted) {
                SmartDialog.showToast('排序完成');
                Get.back();
              }
            },
            child: const Text('完成'),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWindowsNeo = WindowsVideoTabService.enabled;
          final horizontal = isWindowsNeo && constraints.maxWidth > 800
              ? (constraints.maxWidth - 760) / 2
              : isWindowsNeo
              ? 20.0
              : 0.0;
          return ReorderableListView.builder(
            itemCount: _sortList.length,
            // Preserve the existing adjusted-index contract for persistence.
            // ignore: deprecated_member_use
            onReorder: _onReorder,
            physics: const AlwaysScrollableScrollPhysics(),
            padding:
                MediaQuery.viewPaddingOf(context).copyWith(
                  left: isWindowsNeo ? horizontal : null,
                  top: isWindowsNeo ? 16 : 0,
                  right: isWindowsNeo ? horizontal : null,
                ) +
                const EdgeInsets.only(bottom: 100),
            itemBuilder: (context, index) {
              final entry = _sortList[index];
              return Padding(
                key: Key(entry.cid.toString()),
                padding: EdgeInsets.only(bottom: isWindowsNeo ? 12 : 0),
                child: SizedBox(
                  height: isWindowsNeo ? 112 : 100,
                  child: DetailItem(
                    entry: entry,
                    downloadService: _downloadService,
                    showTitle: true,
                    onDelete: () {},
                    controller: _controller,
                    enableTap: false,
                    showMoreButton: false,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NoopMultiSelect implements MultiSelectBase<BiliDownloadEntryInfo> {
  @override
  final RxBool enableMultiSelect = false.obs;

  @override
  int get checkedCount => 0;

  @override
  void handleSelect({bool checked = false, bool disableSelect = true}) {}

  @override
  void onRemove() {}

  @override
  void onSelect(BiliDownloadEntryInfo item) {}
}
