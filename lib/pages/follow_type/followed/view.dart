import 'package:PiliPlus/pages/follow_type/followed/controller.dart';
import 'package:PiliPlus/pages/follow_type/view.dart';
import 'package:PiliPlus/utils/extension/get_ext.dart';
import 'package:PiliPlus/utils/parse_int.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class FollowedPage extends StatefulWidget {
  const FollowedPage({super.key, this.arguments, this.controllerTag});

  final Map? arguments;
  final String? controllerTag;

  @override
  State<FollowedPage> createState() => _FollowedPageState();

  static void toFollowedPage({dynamic mid, String? name}) {
    if (mid == null) return;
    PageUtils.toDupNamed(
      '/followed',
      arguments: {
        'mid': safeToInt(mid),
        'name': name,
      },
    );
  }
}

class _FollowedPageState extends FollowTypePageState<FollowedPage> {
  @override
  Map? get routeArguments => widget.arguments;
  @override
  late final FollowedController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      FollowedController(),
      tag: widget.controllerTag ??
          widget.arguments?['mid']?.toString() ??
          Utils.generateRandomString(8),
    );
  }

  @override
  PreferredSizeWidget get appBar => AppBar(
    title: Obx(
      () => Text(
        '我关注的${controller.total.value}人也关注了${controller.name.value ?? 'TA'}',
      ),
    ),
  );
}
