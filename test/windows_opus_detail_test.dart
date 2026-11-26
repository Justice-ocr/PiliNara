import 'dart:typed_data';

import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show MainListReply, ReplyInfo;
import 'package:PiliPlus/grpc/grpc_req.dart';
import 'package:PiliPlus/http/api.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:PiliPlus/pages/article/controller.dart';
import 'package:PiliPlus/pages/article/view.dart';
import 'package:PiliPlus/utils/reply_scheme_helper.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

class _Preferences extends Fake implements Box<dynamic> {
  final entries = <dynamic, dynamic>{};

  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      entries[key] ?? defaultValue;

  @override
  Future<void> put(dynamic key, dynamic value) async {
    entries[key] = value;
  }
}

void main() {
  setUpAll(() {
    GStorage.setting = _Preferences();
    GStorage.localCache = _Preferences()
      ..entries[LocalCacheKey.timeStamp] = DateTime.now().millisecondsSinceEpoch
      ..entries[LocalCacheKey.mixinKey] = 'test';
    Request();
    Request.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.endsWith(Api.opusDetail)) {
            handler.resolve(
              Response<Map<String, dynamic>>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'code': 0,
                  'data': {
                    'item': {
                      'id_str': '123',
                      'basic': {'comment_type': 12, 'comment_id_str': '456'},
                      'modules': [
                        {
                          'module_type': 'MODULE_TYPE_TITLE',
                          'module_title': {'text': '图文测试标题'},
                        },
                        {
                          'module_type': 'MODULE_TYPE_CONTENT',
                          'module_content': {'paragraphs': []},
                        },
                        {
                          'module_type': 'MODULE_TYPE_STAT',
                          'module_stat': <String, dynamic>{},
                        },
                      ],
                    },
                  },
                },
              ),
            );
          } else if (options.path.endsWith('/MainList')) {
            handler.resolve(
              Response<Uint8List>(
                requestOptions: options,
                statusCode: 200,
                data: GrpcReq.compressProtobuf(
                  MainListReply(replies: [ReplyInfo(id: Int64(2))])
                      .writeToBuffer(),
                ),
                headers: Headers.fromMap({
                  'grpc-status': ['0'],
                }),
              ),
            );
          } else {
            handler.reject(
              DioException(
                requestOptions: options,
                error: 'Unexpected request',
              ),
            );
          }
        },
      ),
    );
  });
  tearDownAll(() => Request.dio.interceptors.removeAt(0));

  testWidgets('动态图文详情挂载并显示正文标题，使用所属页面的评论定位参数', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ArticlePage(
          parameters: {'type': 'opus', 'id': '123'},
          arguments: {rootRpIdKey: 42},
          controllerTag: 'workspace:opus:123',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('图文测试标题'), findsWidgets);
    final controller = Get.find<ArticleController>(tag: 'workspace:opus:123');
    expect(controller.isLoaded.value, isTrue);
    expect(controller.rootRpId, Int64(42));
    await tester.pumpWidget(const SizedBox());
    Get.reset();
  });
}
