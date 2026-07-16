import 'dart:io';

import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/pages/rank/view.dart';
import 'package:PiliPlus/pages/rank/zone/view.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_horizontal_video_tile.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_video_card_v.dart';
import 'package:PiliPlus/windows_ui/features/home/windows_neo_home.dart';
import 'package:PiliPlus/windows_ui/features/home/windows_neo_hot.dart';
import 'package:PiliPlus/windows_ui/features/home/windows_neo_recommendation_grid.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory storageDirectory;

  setUpAll(() async {
    storageDirectory = Directory.systemTemp.createTempSync(
      'pilinara_windows_cards_test_',
    );
    Hive.init(storageDirectory.path);
    GStorage.setting = await Hive.openBox<dynamic>('setting');
  });

  tearDownAll(() async {
    await GStorage.setting.close();
    storageDirectory.deleteSync(recursive: true);
  });

  test('compiles Windows Neo primary browse surfaces', () {
    expect(WindowsNeoHome, isNotNull);
    expect(WindowsNeoHot, isNotNull);
    expect(WindowsNeoRecommendationGrid, isNotNull);
    expect(RankPage, isNotNull);
    expect(ZonePage, isNotNull);
  });

  testWidgets('renders Windows Neo video card skeletons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: const Scaffold(
          body: SizedBox(
            width: 900,
            height: 300,
            child: Row(
              children: [
                Expanded(child: WindowsNeoVideoCardVSkeleton()),
                SizedBox(width: 12),
                Expanded(child: WindowsNeoHorizontalTileSkeleton()),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(WindowsNeoVideoCardVSkeleton), findsOneWidget);
    expect(find.byType(WindowsNeoHorizontalTileSkeleton), findsOneWidget);
  });

  testWidgets('reserves two complete lines for recommendation titles', (
    tester,
  ) async {
    const title =
        'A long recommendation title that must occupy two complete lines '
        'without being covered by metadata';
    final item = RcmdVideoItemModel.fromJson({
      'id': 1,
      'bvid': 'BV1test',
      'cid': 1,
      'goto': 'av',
      'uri': '',
      'pic': '',
      'title': title,
      'duration': 180,
      'pubdate': 0,
      'owner': {'mid': 1, 'name': 'Test uploader', 'face': ''},
      'stat': {'view': 1000, 'like': 10, 'danmaku': 20},
      'is_followed': 0,
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 280,
              height: 280 / (16 / 9) + 104,
              child: WindowsNeoVideoCardV(videoItem: item),
            ),
          ),
        ),
      ),
    );

    final titleBox = tester.renderObject<RenderBox>(find.text(title));
    expect(titleBox.size.height, greaterThanOrEqualTo(36));
    expect(tester.takeException(), isNull);
  });
}
