import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/models/search/search_esports.dart';
import 'package:PiliPlus/pages/match_info/widgets/match_info_item.dart';
import 'package:material_ui/material_ui.dart';

class SearchEsportsItem extends StatelessWidget {
  const SearchEsportsItem({
    super.key,
    required this.item,
  });

  final SearchEsports item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.of(context);
    final contest = item.contest.first;
    return Padding(
      padding: const .symmetric(vertical: 5),
      child: Center(
        child: GestureDetector(
          behavior: .opaque,
          onTap: () => PageUtils.toDupNamed(
            '/matchInfo',
            parameters: {'cid': contest.id.toString()},
          ),
          child: buildContestItem(colorScheme, contest),
        ),
      ),
    );
  }
}
