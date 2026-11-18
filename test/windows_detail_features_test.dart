import 'dart:convert';

import 'package:PiliPlus/grpc/bilibili/main/community/reply/v1.pb.dart'
    show ReplyInfo;
import 'package:PiliPlus/models_new/video/video_ai_conclusion/model_result.dart';
import 'package:PiliPlus/models_new/video/video_detail/data.dart';
import 'package:PiliPlus/models_new/video/video_detail/episode.dart';
import 'package:PiliPlus/models_new/video/video_detail/page.dart';
import 'package:PiliPlus/models_new/video/video_detail/section.dart';
import 'package:PiliPlus/models_new/video/video_detail/ugc_season.dart';
import 'package:PiliPlus/pages/video/ai_conclusion/view.dart';
import 'package:PiliPlus/pages/video/controller.dart';
import 'package:PiliPlus/pages/video/reply/controller.dart';
import 'package:PiliPlus/pages/video/windows_video_context_controller.dart';
import 'package:PiliPlus/pages/video/introduction/ugc/controller.dart';
import 'package:PiliPlus/pages/video/view.dart';
import 'package:PiliPlus/utils/subtitle_utils.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';

class _Intro extends Fake implements UgcIntroController {
  _Intro(VideoDetailData detail) : videoDetail = detail.obs;
  @override
  final Rx<VideoDetailData> videoDetail;
  @override
  final indexNotifier = ValueNotifier(null);
  @override
  int get partIndex => 0;
  @override
  int get sectionIndex => 0;
  @override
  int get seasonIndex => 0;
}

class _Presenter implements WindowsVideoReplyPresenter {
  WindowsVideoReplyContext? opened;
  @override
  bool openWindowsReplyContext(WindowsVideoReplyContext entry) {
    opened = entry;
    return true;
  }
}

class _Owner extends Fake implements VideoDetailController {
  _Owner(this.heroTag);
  @override
  final String heroTag;
  @override
  final _Presenter pageOwner = _Presenter();
}

void main() {
  testWidgets('两栏接连打开楼中楼时各自保留回复定位', (tester) async {
    final left = _Owner('left');
    final right = _Owner('right');
    final reply = ReplyInfo();
    VideoReplyController(videoCtr: left).replyReply(reply, 11);
    VideoReplyController(videoCtr: right).replyReply(reply, 22);
    expect(left.pageOwner.opened?.replyId, 11);
    expect(right.pageOwner.opened?.replyId, 22);
    await tester.pump(const Duration(milliseconds: 501));
  });

  testWidgets('AI 总结时间戳调用当前面板的 seek 回调', (tester) async {
    final model = AiConclusionResult.fromJson({
      'outline': [
        {
          'title': '概要',
          'part_outline': [
            {'timestamp': 75, 'content': '片段'},
          ],
        },
      ],
    });
    Duration? seek;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => AiConclusionPanel.buildContent(
              context,
              Theme.of(context),
              model,
              onSeek: (time) => seek = time,
            ),
          ),
        ),
      ),
    );
    final line = find.textContaining('片段', findRichText: true);
    await tester.tapAt(tester.getTopLeft(line) + const Offset(4, 8));
    expect(seek, const Duration(seconds: 75));
  });
  for (final season in [false, true]) {
    testWidgets('挂载实际 UGC ${season ? '合集' : '多 P'}侧栏', (tester) async {
      final detail = season
          ? VideoDetailData(
              ugcSeason: UgcSeason(
                title: '测试',
                sections: [
                  SectionItem(
                    episodes: [
                      EpisodeItem(title: '第一集', pages: [Part(cid: 1)]),
                    ],
                  ),
                ],
              ),
            )
          : VideoDetailData(
              pages: [
                Part(part: '第一集', cid: 1),
                Part(part: '第二集', cid: 2),
              ],
            );
      final intro = _Intro(detail);
      // Mount only the workspace playlist subtree: no media engine or network.
      final dynamic state = (const VideoDetailPageV().createState() as dynamic)
        ..ugcIntroController = intro;
      await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: state.ugcSeasonPanel as Widget)),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('第一集'), findsWidgets);
      await tester.pumpWidget(const SizedBox());
      intro.indexNotifier.dispose();
    });
  }

  test('新字幕写成 BCC 文档，旧数组缓存仍可用于播放与 SRT 导出', () {
    final body = [
      {'from': 1.25, 'to': 2, 'content': '字幕'},
    ];
    final document = utf8.decode(SubtitleUtils.encodeDocument(body));
    expect(jsonDecode(document), {'body': body});
    for (final source in [document, jsonEncode(body)]) {
      final decoded = SubtitleUtils.decodeBody(source);
      expect(
        SubtitleUtils.json2Vtt(decoded),
        contains('00:00:01.250 --> 00:00:02.000\n字幕'),
      );
      expect(
        SubtitleUtils.json2Srt(decoded),
        contains('1\n00:00:01,250 --> 00:00:02,000\n字幕'),
      );
    }
    expect(() => SubtitleUtils.decodeBody('{}'), throwsFormatException);
  });
}
