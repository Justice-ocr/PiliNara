import 'dart:async';

import 'package:PiliPlus/http/browser_ua.dart';
import 'package:PiliPlus/http/constants.dart';
import 'package:PiliPlus/http/video.dart';
import 'package:PiliPlus/models/common/video/cdn_type.dart';
import 'package:PiliPlus/models/common/video/video_type.dart';
import 'package:PiliPlus/models/video/play/url.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/video_utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

sealed class CdnSelectResult {
  const CdnSelectResult();
}

final class CdnBuiltinResult extends CdnSelectResult {
  const CdnBuiltinResult(this.service);

  final CDNService service;
}

final class CdnCustomResult extends CdnSelectResult {
  const CdnCustomResult(this.host);

  final String host;
}

final class CdnClearCustomResult extends CdnSelectResult {
  const CdnClearCustomResult();
}

Future<void> applyCdnSelectResult(
  CdnSelectResult result, {
  String toastSuffix = '',
}) async {
  switch (result) {
    case CdnBuiltinResult(:final service):
      VideoUtils.cdnService = service;
      VideoUtils.customCDNUrl = null;
      await GStorage.setting.put(SettingBoxKey.CDNService, service.name);
      await GStorage.setting.delete(SettingBoxKey.customCDNUrl);
      SmartDialog.showToast('已设置为 ${service.desc}$toastSuffix');
    case CdnCustomResult(:final host):
      VideoUtils.customCDNUrl = host;
      await GStorage.setting.put(SettingBoxKey.customCDNUrl, host);
      SmartDialog.showToast('已设置自定义 CDN：$host$toastSuffix');
    case CdnClearCustomResult():
      VideoUtils.customCDNUrl = null;
      await GStorage.setting.delete(SettingBoxKey.customCDNUrl);
      SmartDialog.showToast('已清除自定义 CDN$toastSuffix');
  }
}

class SelectDialog<T> extends StatelessWidget {
  final T? value;
  final String title;
  final List<(T, String)> values;
  final Widget Function(BuildContext, int)? subtitleBuilder;
  final bool toggleable;

  const SelectDialog({
    super.key,
    this.value,
    required this.values,
    required this.title,
    this.subtitleBuilder,
    this.toggleable = false,
  });

  @override
  Widget build(BuildContext context) {
    final titleMedium = TextTheme.of(context).titleMedium!;
    return AlertDialog(
      clipBehavior: Clip.hardEdge,
      title: Text(title),
      constraints: subtitleBuilder != null
          ? const BoxConstraints.tightFor(width: 320)
          : null,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: Material(
        type: .transparency,
        child: SingleChildScrollView(
          child: RadioGroup<T>(
            onChanged: (v) => Navigator.of(context).pop(v ?? value),
            groupValue: value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                values.length,
                (index) {
                  final item = values[index];
                  return RadioListTile<T>(
                    toggleable: toggleable,
                    dense: true,
                    value: item.$1,
                    title: Text(
                      item.$2,
                      style: titleMedium,
                    ),
                    subtitle: subtitleBuilder?.call(context, index),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CdnSelectDialog extends StatefulWidget {
  final BaseItem? sample;

  const CdnSelectDialog({
    super.key,
    this.sample,
  });

  @override
  State<CdnSelectDialog> createState() => _CdnSelectDialogState();
}

class _CdnSelectDialogState extends State<CdnSelectDialog> {
  late final List<ValueNotifier<String?>> _cdnResList;
  late final List<CancelToken?> _tokens;
  late final bool _cdnSpeedTest;

  @override
  void initState() {
    _cdnSpeedTest = Pref.cdnSpeedTest;
    if (_cdnSpeedTest) {
      _dio =
          Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            )
            ..options.headers = {
              'user-agent': BrowserUa.pc,
              'referer': HttpString.baseUrl,
            };
      final length = CDNService.values.length;
      _cdnResList = List.generate(
        length,
        (_) => ValueNotifier<String?>(null),
      );
      _tokens = List.generate(length, (_) => CancelToken());
      _startSpeedTest();
    }
    super.initState();
  }

  @override
  void dispose() {
    if (_cdnSpeedTest) {
      for (final e in _tokens) {
        e?.cancel();
      }
      for (final notifier in _cdnResList) {
        notifier.dispose();
      }
      _dio.close(force: true);
    }
    super.dispose();
  }

  Future<BaseItem> _getSampleUrl() async {
    final result = await VideoHttp.videoUrl(
      cid: 196018899,
      bvid: 'BV1fK4y1t7hj',
      tryLook: false,
      videoType: VideoType.ugc,
    );
    final item = result.dataOrNull?.dash?.video?.first;
    if (item == null) throw Exception('无法获取视频流');
    return item;
  }

  Future<void> _startSpeedTest() async {
    try {
      final videoItem = widget.sample ?? await _getSampleUrl();
      await _testAllCdnServices(videoItem);
    } catch (e) {
      if (kDebugMode) debugPrint('CDN speed test failed: $e');
    }
  }

  Future<void> _testAllCdnServices(BaseItem videoItem) async {
    for (final item in CDNService.values) {
      if (!mounted) break;
      await _testSingleCdn(item, videoItem);
    }
  }

  Future<void> _testSingleCdn(CDNService item, BaseItem videoItem) async {
    try {
      final cdnUrl = VideoUtils.getCdnUrl(
        videoItem.playUrls,
        defaultCDNService: item,
        applyCustomCDN: false,
      );
      await _measureDownloadSpeed(cdnUrl, item.index);
    } catch (e) {
      _handleSpeedTestError(e, item.index);
    }
  }

  late final Dio _dio;

  Future<void> _measureDownloadSpeed(String url, int index) async {
    const maxSize = 8 * 1024 * 1024;
    int downloaded = 0;

    final cancelToken = _tokens[index];
    final start = DateTime.now().microsecondsSinceEpoch;

    void onClose() {
      cancelToken?.cancel();
      _tokens[index] = null;
    }

    await _dio.get(
      url,
      cancelToken: cancelToken,
      onReceiveProgress: (count, total) {
        if (!mounted) {
          return;
        }

        final duration = DateTime.now().microsecondsSinceEpoch - start;

        downloaded += count;

        if (duration > 15000000) {
          onClose();
          if (downloaded > 0) {
            _updateSpeedResult(index, downloaded, duration);
            downloaded = 0;
          } else {
            throw TimeoutException('测速超时');
          }
        } else if (downloaded >= maxSize) {
          onClose();
          _updateSpeedResult(index, downloaded, duration);
          downloaded = 0;
        }
      },
    );
  }

  void _updateSpeedResult(int index, int downloaded, int duration) {
    final speed = (downloaded / duration).toStringAsPrecision(3);
    _cdnResList[index].value = '${speed}MB/s';
  }

  void _handleSpeedTestError(dynamic error, int index) {
    _tokens
      ..[index]?.cancel()
      ..[index] = null;
    final item = _cdnResList[index];
    if (item.value != null) return;

    if (kDebugMode) debugPrint('CDN speed test error: $error');
    if (!mounted) return;
    String message;
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      if (statusCode != null && 400 <= statusCode && statusCode < 500) {
        message = '此视频可能无法替换为该CDN';
      } else {
        message = error.toString();
      }
    } else {
      message = error.toString();
    }
    if (message.isEmpty) {
      message = '测速失败';
    }
    item.value = message;
  }

  Future<void> _inputCustom() async {
    final controller = TextEditingController(text: VideoUtils.customCDNUrl);
    String? errorText;
    String? confirm() {
      final host = VideoUtils.normalizeCustomCDNHost(controller.text);
      if (host == null) {
        errorText = '请输入有效的 host 或完整 URL';
        return null;
      }
      return host;
    }

    final host = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('自定义 CDN 节点'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'upos-sz-mirrorali.bilivideo.com',
              helperText: '支持输入完整 URL，自动提取 host',
              errorText: errorText,
            ),
            onChanged: (_) {
              if (errorText != null) setState(() => errorText = null);
            },
            onSubmitted: (_) {
              final value = confirm();
              if (value == null) {
                setState(() {});
              } else {
                Navigator.pop(context, value);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                final value = confirm();
                if (value == null) {
                  setState(() {});
                } else {
                  Navigator.pop(context, value);
                }
              },
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (host != null && mounted) {
      Navigator.pop(context, CdnCustomResult(host));
    }
  }

  @override
  Widget build(BuildContext context) {
    final customHost = VideoUtils.customCDNUrl;
    return AlertDialog(
      title: const Text('CDN 设置'),
      constraints: const BoxConstraints.tightFor(width: 340),
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (customHost != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.dns_outlined),
                title: const Text('自定义节点'),
                subtitle: Text(
                  customHost,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: IconButton(
                  tooltip: '清除自定义 CDN',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(
                    context,
                    const CdnClearCustomResult(),
                  ),
                ),
              ),
            RadioGroup<CDNService>(
              groupValue: customHost == null ? VideoUtils.cdnService : null,
              onChanged: (value) {
                if (value != null) {
                  Navigator.pop(context, CdnBuiltinResult(value));
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(CDNService.values.length, (index) {
                  final service = CDNService.values[index];
                  return RadioListTile<CDNService>(
                    dense: true,
                    value: service,
                    title: Text(service.desc),
                    subtitle: _cdnSpeedTest
                        ? ValueListenableBuilder(
                            valueListenable: _cdnResList[index],
                            builder: (context, value, _) => Text(
                              value ?? '---',
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : null,
                  );
                }),
              ),
            ),
            const Divider(height: 16),
            ListTile(
              dense: true,
              leading: const Icon(Icons.edit_outlined),
              title: const Text('手动输入节点'),
              subtitle: const Text('输入 host 或完整 URL'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _inputCustom,
            ),
          ],
        ),
      ),
    );
  }
}
