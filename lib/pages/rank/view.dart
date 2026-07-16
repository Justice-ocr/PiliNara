import 'package:PiliPlus/common/widgets/flutter/vertical_tabs.dart';
import 'package:PiliPlus/models/common/rank_type.dart';
import 'package:PiliPlus/pages/rank/controller.dart';
import 'package:PiliPlus/pages/rank/zone/view.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RankPage extends StatefulWidget {
  const RankPage({super.key});

  @override
  State<RankPage> createState() => _RankPageState();
}

class _RankPageState extends State<RankPage>
    with AutomaticKeepAliveClientMixin {
  final RankController _rankController = Get.put(RankController());

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    if (WindowsVideoTabService.enabled) {
      return Column(
        children: [
          ColoredBox(
            color: context.windowsNeo.surface,
            child: SizedBox(
              height: context.windowsNeo.sectionTabHeight,
              child: TabBar(
                controller: _rankController.tabController,
                tabs: RankType.values
                    .map(
                      (item) => Tab(
                        text: item.label,
                        height: context.windowsNeo.sectionTabHeight - 2,
                      ),
                    )
                    .toList(),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                padding: EdgeInsets.symmetric(
                  horizontal: context.windowsNeo.pagePadding - 4,
                ),
                dividerColor: Colors.transparent,
                dividerHeight: 0,
                indicatorSize: TabBarIndicatorSize.label,
                indicator: UnderlineTabIndicator(
                  borderSide: BorderSide(
                    color: context.windowsNeo.accent,
                    width: 2.4,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                labelColor: context.windowsNeo.ink,
                unselectedLabelColor: context.windowsNeo.muted,
                onTap: _onTap,
              ),
            ),
          ),
          Divider(height: 1, color: context.windowsNeo.border),
          Expanded(child: _buildPages()),
        ],
      );
    }
    return Row(
      children: [
        _buildTab(theme),
        Expanded(child: _buildPages()),
      ],
    );
  }

  Widget _buildPages() => TabBarView(
    physics: const NeverScrollableScrollPhysics(),
    controller: _rankController.tabController,
    children: RankType.values
        .map(
          (item) => ZonePage(rid: item.rid, seasonType: item.seasonType),
        )
        .toList(),
  );

  void _onTap(int index) {
    if (!_rankController.tabController.indexIsChanging) {
      _rankController.animateToTop();
    } else {
      _rankController
        ..tabIndex.value = index
        ..tabController.animateTo(index);
    }
  }

  Widget _buildTab(ThemeData theme) {
    return VerticalTabBar(
      dividerWidth: 0,
      isScrollable: true,
      indicatorWeight: 3,
      indicatorSize: .tab,
      controller: _rankController.tabController,
      padding: .only(bottom: MediaQuery.paddingOf(context).bottom + 105),
      tabs: RankType.values.map((e) => VerticalTab(text: e.label)).toList(),
      onTap: _onTap,
    );
  }
}
