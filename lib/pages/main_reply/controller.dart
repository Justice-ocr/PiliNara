import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show MainListReply;
import 'package:PiliPlus/grpc/reply.dart';
import 'package:PiliPlus/http/loading_state.dart';
import 'package:PiliPlus/pages/common/reply/fold/reply_fold_mixin.dart';
import 'package:PiliPlus/pages/common/reply/reply_controller.dart';
import 'package:get/get.dart';

class MainReplyController extends ReplyController<MainListReply> {
  MainReplyController({Map? arguments}) : _routeArguments = arguments;

  final Map? _routeArguments;

  late final int oid;
  @override
  late final int replyType;
  late final String? heroTag;

  @override
  int get sourceId => oid;

  @override
  void onInit() {
    super.onInit();
    final args = _routeArguments ?? Get.arguments;
    oid = args['oid'];
    replyType = args['replyType'];
    heroTag = args['heroTag'];

    queryData();
  }

  @override
  Future<LoadingState<MainListReply>> customGetData() => ReplyGrpc.mainList(
    type: replyType,
    oid: oid,
    mode: mode,
    offset: nextOffset,
  );
}
