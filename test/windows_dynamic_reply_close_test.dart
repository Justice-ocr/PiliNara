import 'dart:typed_data';

import 'package:PiliPlus/common/widgets/scaffold/mini_scaffold.dart';
import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show DetailListReply, ReplyInfo;
import 'package:PiliPlus/grpc/grpc_req.dart';
import 'package:PiliPlus/pages/common/dyn/common_dyn_controller.dart';
import 'package:PiliPlus/pages/common/dyn/common_dyn_page.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/http/init.dart';
import 'package:dio/dio.dart';
import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

class _Preferences extends Fake implements Box<dynamic> {
  final _values = <dynamic, dynamic>{};
  @override
  dynamic get(dynamic key, {dynamic defaultValue}) =>
      _values[key] ?? defaultValue;
  @override
  Future<void> put(dynamic key, dynamic value) async {
    _values[key] = value;
  }
}

class _Controller extends Fake implements CommonDynController {
  @override
  int get replyType => 17;
  @override
  Int64? get upMid => null;
}

class _Detail extends StatefulWidget {
  const _Detail();
  @override
  State<_Detail> createState() => _DetailState();
}

class _DetailState extends CommonDynPageState<_Detail> {
  @override
  final controller = _Controller();
  @override
  Map get arguments => const {};
  @override
  Widget build(BuildContext context) => MiniScaffold(
    body: Builder(
      builder: (pane) => TextButton(
        onPressed: () =>
            replyReply(pane, ReplyInfo(id: Int64(1), oid: Int64(2)), null),
        child: const Text('打开动态评论'),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    GStorage.setting = _Preferences();
    GStorage.localCache = _Preferences();
    Request();
    Request.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response<Uint8List>(
              requestOptions: options,
              statusCode: 200,
              data: GrpcReq.compressProtobuf(
                DetailListReply(root: ReplyInfo(id: Int64(1))).writeToBuffer(),
              ),
              headers: Headers.fromMap({
                'grpc-status': ['0'],
              }),
            ),
          );
        },
      ),
    );
  });
  tearDownAll(() => Request.dio.interceptors.removeAt(0));
  testWidgets('动态详情右栏 × 关闭真正的评论面板，保留当前标签路由', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onGenerateRoute: (_) => MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: _Detail()),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开动态评论'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('评论详情'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    expect(find.text('评论详情'), findsNothing);
    expect(find.text('打开动态评论'), findsOneWidget);
  });
}
