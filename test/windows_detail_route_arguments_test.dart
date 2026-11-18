import 'dart:io';

import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/dynamics_detail/controller.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/pages/video/reply/controller.dart';
import 'package:PiliPlus/utils/reply_scheme_helper.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:hive_ce/hive.dart';

class _DynamicController extends DynamicDetailController {
  _DynamicController({required super.replyRouteArguments});

  @override
  Future<void> queryData([bool isRefresh = true]) async {}
}

class _VideoOwner implements VideoDetailController {
  _VideoOwner(this.heroTag, this.args);

  @override
  final String heroTag;
  @override
  final Map args;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _UgcIntroController extends UgcIntroController {
  _UgcIntroController(super.videoDetailCtr);

  @override
  Future<void> queryVideoIntro() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory storage;

  setUpAll(() async {
    storage = Directory.systemTemp.createTempSync('pilinara_detail_routes_');
    Hive.init(storage.path);
    GStorage.setting = await Hive.openBox<dynamic>('setting');
  });

  tearDown(Get.reset);

  tearDownAll(() async {
    await GStorage.setting.close();
    storage.deleteSync(recursive: true);
  });

  test(
    'dynamic detail initializes with nested route data and reply target',
    () {
      final item = DynamicItemModel.fromJson({
        'id_str': '123',
        'basic': {'comment_id_str': '456', 'comment_type': 17},
      });
      final routeArgs = Map.unmodifiable({'item': item, rootRpIdKey: 789});
      expect(Get.arguments, isNull);

      final controller = Get.put(
        _DynamicController(replyRouteArguments: routeArgs),
      );

      expect(controller.dynItem, same(item));
      expect(controller.oid, 456);
      expect(controller.replyType, 17);
      expect(controller.rootRpId?.toInt(), 789);
      controller.clearTargetRootRpId();
      expect(routeArgs[rootRpIdKey], 789);
      expect(controller.args.containsKey(rootRpIdKey), isFalse);
    },
  );

  test('video intros and replies initialize from their own workspace tabs', () {
    final firstOwner = _VideoOwner('video-a', {'title': 'A', rootRpIdKey: 11});
    final secondOwner = _VideoOwner('video-b', {'title': 'B', rootRpIdKey: 22});
    expect(Get.arguments, isNull);

    final first = Get.put(
      _UgcIntroController(firstOwner),
      tag: firstOwner.heroTag,
    );
    final second = Get.put(
      _UgcIntroController(secondOwner),
      tag: secondOwner.heroTag,
    );
    final firstReply = Get.put(
      VideoReplyController(videoCtr: firstOwner),
      tag: firstOwner.heroTag,
    );
    final secondReply = Get.put(
      VideoReplyController(videoCtr: secondOwner),
      tag: secondOwner.heroTag,
    );

    expect(first.heroTag, 'video-a');
    expect(second.heroTag, 'video-b');
    expect(first.videoDetail.value.title, 'A');
    expect(second.videoDetail.value.title, 'B');
    expect(firstReply.rootRpId?.toInt(), 11);
    expect(secondReply.rootRpId?.toInt(), 22);
  });
}
