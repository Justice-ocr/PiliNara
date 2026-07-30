import 'package:PiliPlus/models/common/member/search_type.dart';
import 'package:PiliPlus/pages/member_search/child/controller.dart';
import 'package:PiliPlus/utils/extension/scroll_controller_ext.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class MemberSearchController extends GetxController
    with GetSingleTickerProviderStateMixin {
  MemberSearchController({String? mid, String? uname})
    : mid = mid ?? Get.parameters['mid']!,
      uname = uname ?? Get.parameters['uname'];

  late final FocusNode focusNode;
  late final TabController tabController;
  late final TextEditingController editingController;

  final String mid;
  final String? uname;

  final RxBool hasData = false.obs;
  final RxList<int> counts = <int>[-1, -1].obs;

  late final MemberSearchChildController arcCtr;
  late final MemberSearchChildController dynCtr;
  late final String _arcTag;
  late final String _dynTag;

  @override
  void onInit() {
    super.onInit();
    focusNode = FocusNode();
    editingController = TextEditingController();
    tabController = TabController(vsync: this, length: 2);
    _arcTag = Utils.generateRandomString(8);
    _dynTag = Utils.generateRandomString(8);
    arcCtr = Get.put(
      MemberSearchChildController(this, MemberSearchType.archive),
      tag: _arcTag,
    );
    dynCtr = Get.put(
      MemberSearchChildController(this, MemberSearchType.dynamic),
      tag: _dynTag,
    );
  }

  void onClear([VoidCallback? onBack]) {
    if (editingController.value.text.isNotEmpty) {
      editingController.clear();
      counts.value = <int>[-1, -1];
      hasData.value = false;
      focusNode.requestFocus();
    } else {
      if (onBack case final callback?) {
        callback();
      } else {
        Get.back();
      }
    }
  }

  void submit() {
    if (editingController.text.isNotEmpty) {
      hasData.value = true;
      arcCtr
        ..scrollController.jumpToTop()
        ..onReload();
      dynCtr
        ..scrollController.jumpToTop()
        ..onReload();
    }
  }

  @override
  void onClose() {
    Get.delete<MemberSearchChildController>(tag: _arcTag);
    Get.delete<MemberSearchChildController>(tag: _dynTag);
    focusNode.dispose();
    tabController.dispose();
    editingController.dispose();
    super.onClose();
  }
}
