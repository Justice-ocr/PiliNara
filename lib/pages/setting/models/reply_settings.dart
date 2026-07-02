import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/grpc/reply.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';

List<SettingsModel> get replySettings => [
  getListBanWordModel(
    title: '评论关键词过滤',
    key: SettingBoxKey.banWordForReply,
    onChanged: (value) {
      ReplyGrpc.replyRegExp = value;
      ReplyGrpc.enableFilter = value.pattern.isNotEmpty;
    },
  ),
  NormalModel(
    title: '屏蔽与豁免',
    leading: const Icon(Icons.shield_outlined),
    getSubtitle: () => '推荐/动态/评论用户屏蔽、白名单、Tag 屏蔽',
    onTap: (context, setState) => Get.toNamed('/blockSetting'),
  ),
  SwitchModel(
    title: '屏蔽带货评论',
    subtitle: '屏蔽商品推广相关评论',
    leading: const Icon(CustomIcons.shopping_bag_not_interested),
    setKey: SettingBoxKey.antiGoodsReply,
    defaultVal: false,
    onChanged: (value) => ReplyGrpc.antiGoodsReply = value,
  ),
  SwitchModel(
    title: '屏蔽点赞 UP 评论',
    subtitle: '屏蔽已关注 UP 的点赞/评论相关内容',
    leading: const Icon(Icons.thumb_up_outlined),
    setKey: SettingBoxKey.keepUpLikeReply,
    defaultVal: false,
    onChanged: (value) => ReplyGrpc.keepUpLikeReply = value,
  ),
  SwitchModel(
    title: '屏蔽关注 UP 回复',
    subtitle: '屏蔽已关注 UP 的回复内容',
    leading: const Icon(Icons.mark_chat_read_outlined),
    setKey: SettingBoxKey.keepUpReplyReply,
    defaultVal: false,
    onChanged: (value) => ReplyGrpc.keepUpReplyReply = value,
  ),
];
