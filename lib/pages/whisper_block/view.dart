import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/widgets/dialog/dialog.dart';
import 'package:PiliPlus/common/widgets/loading_widget/loading_widget.dart';
import 'package:PiliPlus/grpc/bilibili/app/im/v1.pb.dart'
    show KeywordBlockingItem;
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/search/widgets/search_text.dart';
import 'package:PiliPlus/pages/whisper_block/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show LengthLimitingTextInputFormatter;
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';

class WhisperBlockPage extends StatefulWidget {
  const WhisperBlockPage({
    super.key,
  });

  @override
  State<WhisperBlockPage> createState() => _WhisperBlockPageState();
}

class _WhisperBlockPageState extends State<WhisperBlockPage> {
  final _controller = Get.put(WhisperBlockController());

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: WindowsVideoTabService.enabled
          ? context.windowsNeo.background
          : null,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: const Text('消息屏蔽词')),
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

  Widget _buildBody(
    ThemeData theme,
    LoadingState<List<KeywordBlockingItem>?> loadingState,
  ) {
    return switch (loadingState) {
      Loading() => m3eLoading,
      Success(:final response) =>
        response != null && response.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '点击屏蔽词即可删除',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        if (_controller.listLimit != null)
                          Obx(
                            () => Text(
                              '${_controller.count.value}/${_controller.listLimit}',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.outline,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: response
                            .map(
                              (e) => SearchText(
                                text: e.keyword,
                                onTap: (keyword) {
                                  showConfirmDialog(
                                    context: context,
                                    title: const Text('删除屏蔽词？'),
                                    content: const Text('该屏蔽词将不再生效'),
                                    onConfirm: () => _controller.onRemove(e),
                                  );
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      left: 25,
                      right: 25,
                      bottom: MediaQuery.viewPaddingOf(context).bottom + 10,
                    ),
                    child: FilledButton.tonal(
                      onPressed: _onAdd,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [Icon(Icons.add, size: 22), Text('添加消息屏蔽词')],
                      ),
                    ),
                  ),
                ],
              )
            : Align(
                alignment: const Alignment(0, -0.5),
                child: Column(
                  spacing: 6,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(Assets.error, height: 156),
                    const Text(
                      '还未添加屏蔽词',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('添加后，将不再接受包含屏蔽词的消息'),
                    FilledButton.tonal(
                      onPressed: _onAdd,
                      style: FilledButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add, size: 22),
                          Text('添加'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      Error(:final errMsg) => scrollErrorWidget(
        errMsg: errMsg,
        onReload: _controller.onReload,
      ),
    };
  }

  void _onAdd() {
    if (WindowsVideoTabService.enabled) {
      _showWindowsAddDialog();
      return;
    }
    String keyword = '';
    showModalBottomSheet(
      context: context,
      enableDrag: false,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12) +
              EdgeInsets.only(
                bottom:
                    MediaQuery.paddingOf(context).bottom +
                    MediaQuery.viewInsetsOf(context).bottom,
              ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '添加消息屏蔽词',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: Get.back,
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.clear,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                autofocus: true,
                maxLength: _controller.charLimit,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: '请输入',
                  visualDensity: .standard,
                  hintStyle: const TextStyle(fontSize: 14),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  border: const OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.all(Radius.circular(25)),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.onInverseSurface,
                ),
                onChanged: (value) => keyword = value,
                inputFormatters: [LengthLimitingTextInputFormatter(20)],
              ),
              const SizedBox(height: 12),
              FilledButton.tonal(
                onPressed: () {
                  if (keyword.isNotEmpty) {
                    _controller.onAdd(keyword);
                  }
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [Icon(Icons.add, size: 22), Text('添加消息屏蔽词')],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWindowsAddDialog() {
    String keyword = '';
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加消息屏蔽词'),
        content: SizedBox(
          width: 380,
          child: TextFormField(
            autofocus: true,
            maxLength: _controller.charLimit,
            decoration: const InputDecoration(hintText: '请输入'),
            onChanged: (value) => keyword = value,
            onFieldSubmitted: (value) {
              if (value.isNotEmpty) {
                _controller.onAdd(value);
              }
            },
            inputFormatters: [LengthLimitingTextInputFormatter(20)],
          ),
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('取消')),
          FilledButton(
            onPressed: () {
              if (keyword.isNotEmpty) {
                _controller.onAdd(keyword);
              }
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}
