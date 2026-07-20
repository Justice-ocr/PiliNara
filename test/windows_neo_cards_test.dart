import 'dart:io';

import 'package:PiliPlus/models/model_rec_video_item.dart';
import 'package:PiliPlus/pages/rank/view.dart';
import 'package:PiliPlus/pages/rank/zone/view.dart';
import 'package:PiliPlus/pages/setting/view.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_card_shell.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_horizontal_video_tile.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_search_skeletons.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_state.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_video_card_v.dart';
import 'package:PiliPlus/windows_ui/features/home/windows_neo_home.dart';
import 'package:PiliPlus/windows_ui/features/home/windows_neo_hot.dart';
import 'package:PiliPlus/windows_ui/features/home/windows_neo_live_card.dart';
import 'package:PiliPlus/windows_ui/features/home/windows_neo_recommendation_grid.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
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
    expect(find.byType(WindowsNeoLoadingMarker), findsNWidgets(2));
  });

  testWidgets('card shell gives keyboard focus the same visual lift', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 240,
              height: 120,
              child: WindowsNeoCardShell(
                hovered: false,
                onTap: () {},
                child: const Text('Focusable card'),
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset,
      Offset.zero,
    );

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(
      tester.widget<AnimatedSlide>(find.byType(AnimatedSlide)).offset.dy,
      lessThan(0),
    );
    expect(
      tester
          .widget<TweenAnimationBuilder<double>>(
            find.byType(TweenAnimationBuilder<double>),
          )
          .tween
          .end,
      1,
    );
  });

  testWidgets('live skeleton fits the Windows 16:9 grid extent', (
    tester,
  ) async {
    const width = 280.0;
    const metadataHeight = 92.0;
    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              height: width / (16 / 9) + metadataHeight,
              child: WindowsNeoLiveCardSkeleton(),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(WindowsNeoLiveCardSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('search skeletons fit their desktop result extents', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: const Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  width: 720,
                  height: 120,
                  child: WindowsNeoSearchHorizontalSkeleton(),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: 280,
                  height: 240,
                  child: WindowsNeoSearchLiveSkeleton(),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: 520,
                  height: 72,
                  child: WindowsNeoSearchCompactSkeleton(),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: 600,
                  height: 170,
                  child: WindowsNeoSearchPgcSkeleton(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.byType(WindowsNeoSearchHorizontalSkeleton), findsOneWidget);
    expect(find.byType(WindowsNeoSearchLiveSkeleton), findsOneWidget);
    expect(find.byType(WindowsNeoSearchCompactSkeleton), findsOneWidget);
    expect(find.byType(WindowsNeoSearchPgcSkeleton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Neo empty state keeps retry in the sliver workflow', (
    tester,
  ) async {
    var retries = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: WindowsNeoTheme.apply(ThemeData.light()),
        home: Scaffold(
          body: CustomScrollView(
            slivers: [
              WindowsNeoSliverState(
                icon: Icons.search_off_outlined,
                title: 'No results',
                message: 'Try another query',
                onRetry: () => retries++,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('39'), findsOneWidget);
    expect(find.text('No results'), findsOneWidget);
    await tester.tap(find.text('\u91cd\u8bd5'));
    expect(retries, 1);
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

  test('Windows settings pages inherit the actual content pane size', () {
    const parent = MediaQueryData(size: Size(2048, 1152));
    const constraints = BoxConstraints.tightFor(width: 920, height: 800);

    final pane = windowsSettingsPaneMediaQuery(parent, constraints);

    expect(pane.size, const Size(920, 800));
  });
}
