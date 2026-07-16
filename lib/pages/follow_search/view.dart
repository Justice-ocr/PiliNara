import 'dart:math' show max;

import 'package:PiliPlus/models_new/follow/data.dart';
import 'package:PiliPlus/models_new/follow/list.dart';
import 'package:PiliPlus/pages/common/search/common_search_page.dart';
import 'package:PiliPlus/pages/follow/widgets/follow_item.dart';
import 'package:PiliPlus/pages/follow_search/controller.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FollowSearchPage extends StatefulWidget {
  const FollowSearchPage({
    super.key,
    this.mid,
    this.isFromSelect = false,
  });

  final int? mid;
  final bool isFromSelect;

  @override
  State<FollowSearchPage> createState() => _FollowSearchPageState();
}

class _FollowSearchPageState
    extends
        CommonSearchPageState<FollowSearchPage, FollowData, FollowItemModel> {
  @override
  late final FollowSearchController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      FollowSearchController(widget.mid ?? Get.arguments['mid']),
      tag: Utils.generateRandomString(8),
    );
  }

  @override
  Widget buildList(List<FollowItemModel> list) {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    final sliver = SliverList.separated(
      itemCount: list.length,
      itemBuilder: ((context, index) {
        if (index == list.length - 1) {
          controller.onLoadMore();
        }
        return FollowItem(
          item: list[index],
          onSelect: widget.mid != null && widget.isFromSelect
              ? (userModel) => Get.back(result: userModel)
              : null,
        );
      }),
      separatorBuilder: (_, _) => isWindowsNeo
          ? Divider(height: 1, color: context.windowsNeo.border)
          : const SizedBox.shrink(),
    );
    if (!isWindowsNeo) return sliver;
    final horizontalPadding = max(
      18.0,
      (MediaQuery.sizeOf(context).width - 820) / 2,
    );
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16,
        horizontalPadding,
        0,
      ),
      sliver: sliver,
    );
  }
}
