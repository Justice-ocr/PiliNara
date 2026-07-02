import 'package:PiliPlus/grpc/reply.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:PiliPlus/utils/global_data.dart';
import 'package:PiliPlus/utils/recommend_filter.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/user_whitelist.dart';
import 'package:flutter/material.dart';

List<SettingsModel> get blockSettings => [
  getListUidWithNameModel(
    title: '推荐屏蔽用户',
    leading: const Icon(Icons.explore_off_outlined),
    emptySubtitle: '点击添加推荐屏蔽用户',
    countSubtitleBuilder: (count) => '已屏蔽 $count 个推荐用户',
    getUidsMap: () => Pref.recommendBlockedMids,
    setUidsMap: (uidsMap) {
      Pref.recommendBlockedMids = uidsMap;
      GlobalData().recommendBlockedMids = uidsMap;
      RecommendFilter.recommendBlockedMids = uidsMap;
    },
    onUpdate: () {},
  ),
  getListUidModel(
    title: '动态屏蔽用户',
    leading: const Icon(Icons.dynamic_feed_outlined),
    getUids: () => Pref.dynamicsBlockedMids,
    setUids: (uids) {
      Pref.dynamicsBlockedMids = uids;
      GlobalData().dynamicsBlockedMids = uids;
    },
    onUpdate: () {},
  ),
  getListUidWithNameModel(
    title: '评论屏蔽用户',
    leading: const Icon(Icons.forum_outlined),
    emptySubtitle: '点击添加评论屏蔽用户',
    countSubtitleBuilder: (count) => '已屏蔽 $count 个评论用户',
    getUidsMap: () => Pref.replyBlockedMids,
    setUidsMap: (mids) {
      Pref.replyBlockedMids = mids;
      ReplyGrpc.replyBlockedMids = mids;
    },
    onUpdate: () {},
  ),
  getListUidWithNameModel(
    title: '白名单用户',
    leading: const Icon(Icons.verified_user_outlined),
    emptySubtitle: '点击添加白名单用户',
    countSubtitleBuilder: (count) => '已加入 $count 个白名单用户',
    getUidsMap: () => Pref.whitelistMids,
    setUidsMap: UserWhitelist.save,
    onUpdate: () {},
  ),
  getListBanWordModel(
    title: '视频 Tag 屏蔽',
    key: SettingBoxKey.banWordForVideoTag,
    onChanged: (value) {
      RecommendFilter.videoTagRegExp = value;
      RecommendFilter.enableVideoTagFilter = value.pattern.isNotEmpty;
    },
  ),
  SwitchModel(
    title: '已关注 UP 豁免推荐过滤',
    subtitle: '推荐中已关注用户发布的内容不参与过滤',
    leading: const Icon(Icons.favorite_border_outlined),
    setKey: SettingBoxKey.exemptFilterForFollowed,
    defaultVal: true,
    onChanged: (value) => RecommendFilter.exemptFilterForFollowed = value,
  ),
];
