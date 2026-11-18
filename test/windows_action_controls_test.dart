import 'dart:io';

import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/dynamics/widgets/additional_panel.dart';
import 'package:PiliPlus/pages/setting/models/play_settings.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  late Directory temp;
  setUpAll(() async {
    temp = await Directory.systemTemp.createTemp('neo_actions_');
    Hive.init(temp.path);
    GStorage.setting = await Hive.openBox<dynamic>('setting');
  });
  tearDownAll(() async {
    await GStorage.setting.close();
    await temp.delete(recursive: true);
  });
  test('Windows hides gravity locking but retains the fullscreen lock and volume controls', () {
    final titles = playSettings.map((setting) => setting.title);
    expect(titles, isNot(contains('锁定后禁止重力感应旋转')));
    expect(titles, contains('全屏显示锁定按钮'));
    expect(titles, contains('滚轮调节音量'));
  }, skip: !Platform.isWindows);

  for (final url in [null, '', 'bilibili://video/1']) {
    testWidgets(
      'reservation card body is actionable only with a destination: $url',
      (tester) async {
        final additional = DynamicAddModel.fromJson({
          'type': 'ADDITIONAL_TYPE_RESERVE',
          'reserve': {
            'title': '预约测试',
            'button': {'jump_url': url, 'status': 0, 'type': 1},
          },
        });
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => addWidget(
                  context,
                  floor: 1,
                  theme: Theme.of(context),
                  idStr: '1',
                  additional: additional,
                )!,
              ),
            ),
          ),
        );
        final body = tester.widget<InkWell>(
          find
              .ancestor(of: find.text('预约测试'), matching: find.byType(InkWell))
              .first,
        );
        expect(body.onTap != null, url?.isNotEmpty == true);
        expect(
          tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull,
        );
      },
    );
  }
}
