import 'package:PiliPlus/models/common/search/search_type.dart';
import 'package:get/get.dart';

class SearchResultController extends GetxController {
  SearchResultController({Map? arguments})
    : keyword = arguments?['keyword']?.toString() ??
          Get.parameters['keyword'] ??
          '';

  final String keyword;

  RxList<int> count = List.filled(SearchType.values.length, -1).obs;

  RxInt toTopIndex = (-1).obs;

  @override
  void onClose() {
    toTopIndex.close();
    super.onClose();
  }
}
