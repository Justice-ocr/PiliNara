import 'package:PiliPlus/models/dynamics/result.dart';
import 'package:PiliPlus/pages/setting/models/model.dart';
import 'package:get/get.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:flutter/material.dart';

List<SettingsModel> get dynamicsSettings => [
  getListBanWordModel(
    title: '动态关键词过滤',
    key: SettingBoxKey.banWordForDyn,
    onChanged: (value) {
      DynamicsDataModel.banWordForDyn = value;
      DynamicsDataModel.enableFilter = value.pattern.isNotEmpty;
    },
  ),
  NormalModel(
    title: '屏蔽与豁免',
    leading: const Icon(Icons.shield_outlined),
    getSubtitle: () => '推荐/动态/评论用户屏蔽、白名单、Tag 屏蔽',
    onTap: (context, setState) => Get.toNamed('/blockSetting'),
  ),
  SwitchModel(
    title: '屏蔽带货动态',
    subtitle: '屏蔽商品推广、带货相关动态',
    leading: const Icon(Icons.shopping_bag_outlined),
    setKey: SettingBoxKey.antiGoodsDyn,
    defaultVal: false,
    onChanged: (value) {
      DynamicsDataModel.antiGoodsDyn = value;
    },
  ),
  SwitchModel(
    title: '屏蔽无权查看的动态',
    subtitle: '过滤当前账号无权查看的受限动态',
    leading: const Icon(Icons.visibility_off_outlined),
    setKey: SettingBoxKey.removeBlockedDyn,
    defaultVal: false,
    onChanged: (value) {
      DynamicsDataModel.removeBlockedDyn = value;
    },
  ),
  SwitchModel(
    title: '屏蔽充电专属视频动态',
    subtitle: '过滤充电专属视频动态',
    leading: const Icon(Icons.video_library_outlined),
    setKey: SettingBoxKey.removeOnlyFansVideoDyn,
    defaultVal: false,
    onChanged: (value) {
      DynamicsDataModel.removeOnlyFansVideoDyn = value;
    },
  ),
];
