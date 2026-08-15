import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:PiliPlus/common/assets.dart';
import 'package:PiliPlus/common/style.dart';
import 'package:PiliPlus/common/widgets/button/icon_button.dart';
import 'package:PiliPlus/common/widgets/custom_icon.dart';
import 'package:PiliPlus/common/widgets/extra_hittest_stack.dart';
import 'package:PiliPlus/common/widgets/flutter/popup_menu.dart';
import 'package:PiliPlus/common/widgets/flutter/pop_scope.dart';
import 'package:PiliPlus/common/widgets/flutter/text_field/controller.dart';
import 'package:PiliPlus/common/widgets/gesture/horizontal_drag_gesture_recognizer.dart';
import 'package:PiliPlus/common/widgets/image/network_img_layer.dart';
import 'package:PiliPlus/common/widgets/keep_alive_wrapper.dart';
import 'package:PiliPlus/common/widgets/route_aware_mixin.dart';
import 'package:PiliPlus/common/widgets/scaffold/simple_scaffold.dart';
import 'package:PiliPlus/common/widgets/scroll_physics.dart'
    show tabBarScrollPhysics;
import 'package:PiliPlus/models/common/live/live_contribution_rank_type.dart';
import 'package:PiliPlus/models_new/live/live_danmaku/danmaku_msg.dart';
import 'package:PiliPlus/models_new/live/live_emote/emoticon.dart';
import 'package:PiliPlus/models_new/live/live_room_info_h5/data.dart';
import 'package:PiliPlus/models_new/live/live_superchat/item.dart';
import 'package:PiliPlus/pages/danmaku/danmaku_model.dart';
import 'package:PiliPlus/pages/live_room/contribution_rank/controller.dart';
import 'package:PiliPlus/pages/live_room/contribution_rank/view.dart';
import 'package:PiliPlus/pages/live_room/controller.dart';
import 'package:PiliPlus/pages/live_emote/controller.dart';
import 'package:PiliPlus/pages/live_emote/view.dart';
import 'package:PiliPlus/pages/live_room/superchat/superchat_card.dart';
import 'package:PiliPlus/pages/live_room/superchat/superchat_panel.dart';
import 'package:PiliPlus/pages/live_room/widgets/bottom_control.dart';
import 'package:PiliPlus/pages/live_room/widgets/chat_panel.dart';
import 'package:PiliPlus/pages/live_room/widgets/header_control.dart';
import 'package:PiliPlus/pages/video/widgets/player_focus.dart';
import 'package:PiliPlus/plugin/pl_player/controller.dart';
import 'package:PiliPlus/plugin/pl_player/models/play_status.dart';
import 'package:PiliPlus/plugin/pl_player/utils/danmaku_options.dart';
import 'package:PiliPlus/plugin/pl_player/utils/fullscreen.dart';
import 'package:PiliPlus/plugin/pl_player/view/view.dart';
import 'package:PiliPlus/services/live_pip_overlay_service.dart';
import 'package:PiliPlus/services/logger.dart';
import 'package:PiliPlus/services/pip_overlay_service.dart';
import 'package:PiliPlus/services/pip_transition_coordinator.dart';
import 'package:PiliPlus/services/service_locator.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/utils/extension/num_ext.dart';
import 'package:PiliPlus/utils/extension/size_ext.dart';
import 'package:PiliPlus/utils/extension/theme_ext.dart';
import 'package:PiliPlus/utils/image_utils.dart';
import 'package:PiliPlus/utils/max_screen_size.dart';
import 'package:PiliPlus/utils/mobile_observer.dart';
import 'package:PiliPlus/utils/page_utils.dart';
import 'package:PiliPlus/utils/platform_utils.dart';
import 'package:PiliPlus/utils/share_utils.dart';
import 'package:PiliPlus/utils/storage.dart';
import 'package:PiliPlus/utils/storage_key.dart';
import 'package:PiliPlus/utils/storage_pref.dart';
import 'package:PiliPlus/utils/theme_utils.dart';
import 'package:PiliPlus/utils/utils.dart';
import 'package:PiliPlus/windows_ui/features/video/windows_neo_video_layout.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_stage.dart';
import 'package:PiliPlus/windows_ui/components/windows_neo_rhythm_rail.dart';
import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:canvas_danmaku/danmaku_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:material_ui/material_ui.dart';
import 'package:screen_brightness_platform_interface/screen_brightness_platform_interface.dart';

const baseWhite = Color(0xFFEEEEEE);

class LiveRoomPage extends StatefulWidget {
  const LiveRoomPage({super.key, this.arguments});

  final Object? arguments;

  @override
  State<LiveRoomPage> createState() => _LiveRoomPageState();
}

class _LiveRoomPageState extends State<LiveRoomPage>
    with
        WidgetsBindingObserver,
        RouteAware,
        RouteAwareMixin,
        SingleTickerProviderStateMixin {
  late final fullScreenSCWidth = Pref.fullScreenSCWidth;
  final String heroTag = Utils.generateRandomString(6);
  late final LiveRoomController _liveRoomController;
  late PlPlayerController plPlayerController;
  bool get isFullScreen => plPlayerController.isFullScreen.value;

  // 标志位：是否正在进入 PiP 模式
  bool _isEnteringPipMode = false;
  bool _closingFromWindowsLiveTabService = false;
  double? _windowsSidePanelWidth;
  late final TabController _windowsSideTabController;
  final TextEditingController _windowsDanmakuTextController =
      TextEditingController();
  late final FocusNode _windowsDanmakuFocusNode;
  bool _windowsDanmakuSending = false;
  bool _windowsEmotePanelVisible = false;

  late final GlobalKey pageKey = GlobalKey();
  late final GlobalKey chatKey = GlobalKey();
  late final GlobalKey scKey = GlobalKey();
  late final GlobalKey playerKey = GlobalKey();

  // 归位动画进行中：页面播放器以透明占位先行布局（供量取目标矩形），
  // 恢复握手完成后亮出，期间小窗是唯一可见端
  bool _pipRestoreInFlight = false;
  int _pipRestoreRectAttempts = 0;

  // 页面根参照系：归位目标矩形以此量取，规避路由转场期间的整页偏移
  final _pageRootKey = GlobalKey();

  /// 量取页面播放器矩形（收起源矩形用全局坐标；归位目标以页面根为参照系）
  Rect? _livePlayerRect({bool relativeToPage = false}) {
    final renderObject = playerKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize ||
        // 未加载完成时播放器区是零尺寸 SizedBox.shrink,视为未量到
        renderObject.size.isEmpty) {
      return null;
    }
    if (relativeToPage) {
      final pageRenderObject = _pageRootKey.currentContext?.findRenderObject();
      if (pageRenderObject is RenderBox && pageRenderObject.attached) {
        return renderObject.localToGlobal(
              Offset.zero,
              ancestor: pageRenderObject,
            ) &
            renderObject.size;
      }
      return null;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  /// C1/C2 共用：页面就绪后量取归位目标矩形并上报协调器（最多重试 10 帧）
  void _scheduleLivePipRestoreAttach() {
    _pipRestoreRectAttempts = 0;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _attachLivePipRestore(),
    );
  }

  void _attachLivePipRestore() {
    if (!mounted || !_pipRestoreInFlight) return;
    final targetRect = _livePlayerRect(relativeToPage: true);
    if (targetRect == null && _pipRestoreRectAttempts++ < 10) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _attachLivePipRestore(),
      );
      return;
    }
    LivePipOverlayService.transition.attachRestorePage(
      targetRect: targetRect,
      onCompleted: () {
        if (!mounted) {
          _pipRestoreInFlight = false;
          return;
        }
        setState(() => _pipRestoreInFlight = false);
      },
    );
  }

  // 归位动画进行中：页面播放器以透明占位先行布局（供量取目标矩形），
  // 恢复握手完成后亮出，期间小窗是唯一可见端
  bool _pipRestoreInFlight = false;
  int _pipRestoreRectAttempts = 0;

  // 页面根参照系：归位目标矩形以此量取，规避路由转场期间的整页偏移
  final _pageRootKey = GlobalKey();

  /// 量取页面播放器矩形（收起源矩形用全局坐标；归位目标以页面根为参照系）
  Rect? _livePlayerRect({bool relativeToPage = false}) {
    final renderObject = playerKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize ||
        // 未加载完成时播放器区是零尺寸 SizedBox.shrink,视为未量到
        renderObject.size.isEmpty) {
      return null;
    }
    if (relativeToPage) {
      final pageRenderObject = _pageRootKey.currentContext?.findRenderObject();
      if (pageRenderObject is RenderBox && pageRenderObject.attached) {
        return renderObject.localToGlobal(
              Offset.zero,
              ancestor: pageRenderObject,
            ) &
            renderObject.size;
      }
      return null;
    }
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  /// C1/C2 共用：页面就绪后量取归位目标矩形并上报协调器（最多重试 10 帧）
  void _scheduleLivePipRestoreAttach() {
    _pipRestoreRectAttempts = 0;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _attachLivePipRestore(),
    );
  }

  void _attachLivePipRestore() {
    if (!mounted || !_pipRestoreInFlight) return;
    final targetRect = _livePlayerRect(relativeToPage: true);
    if (targetRect == null && _pipRestoreRectAttempts++ < 10) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _attachLivePipRestore(),
      );
      return;
    }
    LivePipOverlayService.transition.attachRestorePage(
      targetRect: targetRect,
      onCompleted: () {
        if (!mounted) {
          _pipRestoreInFlight = false;
          return;
        }
        setState(() => _pipRestoreInFlight = false);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _windowsDanmakuFocusNode = FocusNode(
      debugLabel: 'windows-live-danmaku-input',
      onKeyEvent: _handleWindowsDanmakuKey,
    );
    addObserverMobile(this);
    final args = _routeArgs;
    if (args is Map) {
      WindowsVideoTabService.currentArguments = args;
    }

    // 解析当前请求进入的房间号
    int? currentEntryRoomId;
    if (args is Map) {
      currentEntryRoomId = (args['roomId'] as int?) ?? (args['id'] as int?);
    } else if (args is int) {
      currentEntryRoomId = args;
    }

    // 检测是否是从小窗返回（即：进入的房间正是当前小窗中的房间）
    final bool isReturningFromPip =
        currentEntryRoomId != null &&
        LivePipOverlayService.isCurrentLiveRoom(currentEntryRoomId);

    // 无论是否是同一个房间，既然进入了直播详情页，就关闭现有的小窗（不销毁播放器）
    if (LivePipOverlayService.isInPipMode) {
      // 本页随后会新建 controller 并自开弹幕流/通知条目，旧 controller 就此退休
      LivePipOverlayService.cleanupSavedController();
      if (isReturningFromPip &&
          LivePipOverlayService.transition.phase == PipPhase.restoring) {
        // 点击展开（归位动画中）：小窗仍在飞向本页，非销毁式关闭推迟到
        // 握手完成由协调器触发 _finalizeRestore 执行；本页播放器先透明占位
        _pipRestoreInFlight = true;
        _scheduleLivePipRestoreAttach();
      } else {
        // 其他房间/无动画路径：维持旧的非销毁式关闭，让新页面接管播放器
        WidgetsBinding.instance.addPostFrameCallback((_) {
          LivePipOverlayService.stopLivePip(callOnClose: false);
        });
      }
    }

    // 如果有视频小窗也关闭
    if (PipOverlayService.isInPipMode) {
      PipOverlayService.stopPip(
        callOnClose: false,
        releaseSavedOwner: true,
        // 小窗 owner 的视频页仍在栈内时只暂停不 dispose，避免破坏其计数
        disposeSavedOwnerPlayer: VideoStackManager.getCount() == 0,
      );
    }

    _liveRoomController = Get.put(
      LiveRoomController(heroTag, fromPip: isReturningFromPip),
      tag: heroTag,
    );
    _windowsSideTabController = TabController(
      length: _liveRoomController.showSuperChat ? 3 : 2,
      vsync: this,
    );
    plPlayerController = _liveRoomController.plPlayerController
      ..addStatusLister(playerListener);
    if (WindowsVideoTabService.enabled) {
      plPlayerController.activateAsGlobal();
      WindowsVideoTabService.registerRoute(
        _liveTabArgs,
        activate: _activateWindowsLiveTab,
        deactivate: _deactivateWindowsLiveTab,
        close: _closeWindowsLiveTab,
        present: _presentWindowsLiveTab,
        muteState: plPlayerController.muted,
        setMuted: plPlayerController.setMuted,
      );
    }
    PlPlayerController.setPlayCallBack(plPlayerController.play);

    if (isReturningFromPip) {
      _liveRoomController.isInPipMode.value = false;
      plPlayerController
        ..isLive = true
        ..danmakuController = _liveRoomController.danmakuController;
      _liveRoomController
        ..danmakuController?.resume()
        ..startLiveTimer()
        ..startLiveMsg();
    } else {
      plPlayerController.isLive = true;
      if (plPlayerController.removeSafeArea) {
        hideSystemBar();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (plPlayerController.removeSafeArea) {
      padding = .zero;
    } else {
      padding = MediaQuery.viewPaddingOf(context);
    }
    final size = MediaQuery.sizeOf(context);
    maxWidth = size.width;
    maxHeight = size.height;
    isWindowMode = MaxScreenSize.isWindowMode(
      width: maxWidth * plPlayerController.uiScale,
      height: maxHeight * plPlayerController.uiScale,
    );
    isPortrait = size.isPortrait;
    plPlayerController.screenRatio = maxHeight / maxWidth;
  }

  @override
  Future<void> didPopNext() async {
    addObserverMobile(this);
    if (WindowsVideoTabService.enabled) {
      WindowsVideoTabService.setActive(_liveTabArgs);
      plPlayerController.activateAsGlobal();
    }

    // 如果返回当前页面时应用内小窗正在运行，且房间号匹配，说明是从正在小窗播放的页面返回
    if (LivePipOverlayService.isInPipMode) {
      if (LivePipOverlayService.currentRoomId == _liveRoomController.roomId) {
        // 返回展开：小窗飞回页内播放器位置，非销毁式关闭推迟到握手完成；
        // 无法归位（无小窗会话）则维持旧的瞬时关闭
        if (LivePipOverlayService.transition.beginRestore()) {
          _pipRestoreInFlight = true;
          _scheduleLivePipRestoreAttach();
        } else {
          LivePipOverlayService.stopLivePip(
            callOnClose: false,
            immediate: true,
          );
        }
      } else {
        // 小窗里是其他房间，返回直播间时必须关闭，否则会同时播放两个视频
        LivePipOverlayService.stopLivePip(callOnClose: true, immediate: true);
        // 当前页面之前可能曾尝试进入小窗，需要重置该标志防止 dispose 跳过播放器清理
        _isEnteringPipMode = false;
      }
    }
    // 直播页返回时，若视频小窗仍在运行，也需关闭
    if (PipOverlayService.isInPipMode) {
      PipOverlayService.stopPip(callOnClose: true, immediate: true);
      _isEnteringPipMode = false;
    }

    // 如果 local 的 plPlayerController 实例指向了已被销毁的单例，刷新它
    if (plPlayerController != _liveRoomController.plPlayerController) {
      plPlayerController = _liveRoomController.plPlayerController;
    }

    if (!plPlayerController.isLive) {
      plPlayerController.isLive = true;
      _liveRoomController.isLoaded.refresh();
    }
    plPlayerController.danmakuController =
        _liveRoomController.danmakuController;
    PlPlayerController.setPlayCallBack(plPlayerController.play);
    _liveRoomController.startLiveTimer();

    // 如果是从小窗返回，直接恢复状态，不重新初始化
    if (_liveRoomController.isReturningFromPip) {
      _liveRoomController
        ..danmakuController?.resume()
        ..startLiveMsg();
      plPlayerController.addStatusLister(playerListener);
      super.didPopNext();
      return;
    }

    // 非小窗返回情况下的恢复：如果播放器未初始化（例如小窗在其它页面被手动关闭），或者被其它直播/视频抢占
    final bool shouldPlay =
        _liveRoomController.isPlaying ??
        plPlayerController.playerStatus.isPlaying;

    bool needsRecovery = false;
    if (plPlayerController.videoPlayerController == null) {
      needsRecovery = true;
    } else if (!plPlayerController.isLive ||
        plPlayerController.roomId != _liveRoomController.roomId) {
      needsRecovery = true;
    }

    if (needsRecovery) {
      await _liveRoomController.playerInit(autoplay: shouldPlay);
      // 重新获取刷新后的实例
      plPlayerController = _liveRoomController.plPlayerController;
    }

    plPlayerController.addStatusLister(playerListener);

    if (plPlayerController.playerStatus.isPlaying &&
        plPlayerController.cid == null) {
      _liveRoomController
        ..danmakuController?.resume()
        ..startLiveMsg();
    } else {
      final shouldPlay = _liveRoomController.isPlaying ?? false;
      if (shouldPlay) {
        _liveRoomController
          ..danmakuController?.resume()
          ..startLiveMsg();
      }
      await _liveRoomController.playerInit(autoplay: shouldPlay);
    }
    if (!mounted) return;
    plPlayerController.addStatusLister(playerListener);
    super.didPopNext();
  }

  @override
  void didPushNext() {
    removeObserverMobile(this);
    plPlayerController.removeStatusLister(playerListener);

    if (plPlayerController.playerStatus.isPlaying &&
        !isFullScreen &&
        _shouldStartLivePip()) {
      _startLivePipIfNeeded();
    } else {
      _liveRoomController
        ..danmakuController?.clear()
        ..cancelLiveTimer()
        ..closeLiveMsg()
        ..isPlaying = plPlayerController.playerStatus.isPlaying;
    }

    super.didPushNext();
  }

  void playerListener(PlayerStatus status) {
    if (status.isPlaying) {
      _liveRoomController
        ..danmakuController?.resume()
        ..startLiveTimer()
        ..startLiveMsg();
    } else {
      _liveRoomController
        ..danmakuController?.pause()
        ..cancelLiveTimer()
        ..closeLiveMsg();
    }
  }

  void _activateWindowsLiveTab() {
    _presentWindowsLiveTab(true, true);
  }

  void _deactivateWindowsLiveTab() {
    _presentWindowsLiveTab(false, false);
  }

  void _presentWindowsLiveTab(bool visible, bool focused) {
    if (!mounted) return;
    plPlayerController.visible = visible;
    if (focused) {
      plPlayerController.activateAsGlobal();
      PlPlayerController.setPlayCallBack(plPlayerController.play);
    }
    final tabId = WindowsVideoTabService.keyFromArgs(_liveTabArgs);
    unawaited(
      plPlayerController.setTabAudioSuppressed(
        WindowsVideoTabService.shouldSuppressTabAudio(tabId, focused),
      ),
    );
    if (focused && plPlayerController.playerStatus.isPlaying) {
      _liveRoomController
        ..danmakuController?.resume()
        ..startLiveTimer()
        ..startLiveMsg();
    } else {
      _liveRoomController
        ..cancelLiveTimer()
        ..closeLiveMsg();
    }
    setState(() {});
  }

  void _closeWindowsLiveTab() {
    if (!mounted) return;
    _closingFromWindowsLiveTabService = true;
    final route = ModalRoute.of(context);
    if (route != null) {
      if (route.isCurrent) {
        Navigator.of(context).maybePop();
      } else {
        Navigator.of(context).removeRoute(route);
      }
      return;
    }
    WindowsVideoTabService.unregisterRoute(
      _liveTabArgs,
      _closeWindowsLiveTab,
    );
    final player =
        WindowsVideoTabService.removePlayer<PlPlayerController>(_liveTabArgs) ??
        plPlayerController;
    videoPlayerServiceHandler?.onVideoDetailDispose(heroTag);
    player.dispose();
    Get.delete<LiveRoomController>(tag: heroTag, force: true);
  }

  @override
  void dispose() {
    final isInLivePip = LivePipOverlayService.isCurrentLiveRoom(
      _liveRoomController.roomId,
    );
    final keepWindowsTabAlive =
        WindowsVideoTabService.enabled &&
        !_closingFromWindowsLiveTabService &&
        WindowsVideoTabService.has(
          WindowsVideoTabService.keyFromArgs(_liveTabArgs),
        );
    if (!isInLivePip && !_isEnteringPipMode && !keepWindowsTabAlive) {
      videoPlayerServiceHandler?.onVideoDetailDispose(heroTag);
    }
    removeObserverMobile(this);
    if (Platform.isAndroid && !plPlayerController.setSystemBrightness) {
      ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
    }
    if (!isInLivePip && !_isEnteringPipMode && !keepWindowsTabAlive) {
      PlPlayerController.setPlayCallBack(null);
    }
    plPlayerController.removeStatusLister(playerListener);
    if (keepWindowsTabAlive) {
      WindowsVideoTabService.keepPlayer(
        _liveTabArgs,
        plPlayerController,
        dispose: (player) => player.dispose(),
      );
    } else if (!isInLivePip && !_isEnteringPipMode) {
      plPlayerController.dispose();
    }

    for (final e in LiveContributionRankType.values) {
      Get.delete<ContributionRankController>(
        tag: '${_liveRoomController.roomId}${e.name}',
      );
    }

    WindowsVideoTabService.unregisterRoute(
      _liveTabArgs,
      _closeWindowsLiveTab,
    );

    if (!isInLivePip && !_isEnteringPipMode && !keepWindowsTabAlive) {
      Get.delete<LiveRoomController>(tag: heroTag, force: true);
    }

    _windowsSideTabController.dispose();
    _windowsDanmakuTextController.dispose();
    _windowsDanmakuFocusNode.dispose();
    Get.delete<LiveEmotePanelController>(
      tag: _liveRoomController.roomId.toString(),
    );
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (plPlayerController.visible = state == .resumed) {
      if (!plPlayerController.showDanmaku) {
        _liveRoomController
          ..refreshMsgIfNeeded()
          ..startLiveTimer();
        plPlayerController.showDanmaku = true;
      }
    } else if (state == .paused) {
      _liveRoomController.cancelLiveTimer();
      plPlayerController
        ..showDanmaku = false
        ..danmakuController?.clear();
    }
  }

  late double maxWidth;
  late double maxHeight;
  bool isWindowMode = false;
  late EdgeInsets padding;
  late bool isPortrait;

  WindowsNeoTokens get _windowsTokens =>
      WindowsNeoTokens.fromTheme(
        ThemeUtils.darkTheme,
        family: WindowsNeoThemeController.family.value,
        depth: WindowsNeoThemeController.depth.value,
      ).copyWith(
        background: const Color(0xFF0B0D0F),
        sidebar: const Color(0xFF101316),
        surface: const Color(0xFF14171A),
        surfaceRaised: const Color(0xFF1B1F23),
        border: const Color(0xFF343A40),
        muted: const Color(0xFF9AA4AE),
        hover: const Color(0xFF252B31),
        ink: const Color(0xFFF3F5F7),
      );

  ThemeData get _windowsLiveTheme {
    final base = WindowsNeoTheme.apply(
      ThemeUtils.darkTheme,
      family: WindowsNeoThemeController.family.value,
      depth: WindowsNeoThemeController.depth.value,
    );
    final extensions =
        base.extensions.values
            .where((item) => item is! WindowsNeoTokens)
            .toList()
          ..add(_windowsTokens);
    return base.copyWith(
      scaffoldBackgroundColor: _windowsTokens.background,
      canvasColor: _windowsTokens.surface,
      dividerColor: _windowsTokens.border,
      colorScheme: base.colorScheme.copyWith(
        primary: _windowsTokens.accent,
        surface: _windowsTokens.surface,
        onSurface: _windowsTokens.ink,
        outline: _windowsTokens.border,
      ),
      extensions: extensions,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (plPlayerController.isPipMode) {
      child = videoPlayerPanel(
        isFullScreen,
        width: maxWidth,
        height: maxHeight,
        isPipMode: true,
        needDm: !plPlayerController.pipNoDanmaku,
      );
    } else if (WindowsVideoTabService.enabled) {
      // The media-tab host already puts inactive tabs in Offstage. Keeping the
      // live page mounted avoids detaching and recreating the Windows video
      // surface on every ordinary tab switch.
      child = childWhenWindowsNeo;
    } else {
      child = childWhenDisabled;
    }
    if (plPlayerController.keyboardControl) {
      child = PlayerFocus(
        plPlayerController: plPlayerController,
        onSendDanmaku: WindowsVideoTabService.enabled && !isFullScreen
            ? _focusWindowsDanmaku
            : _liveRoomController.onSendDanmaku,
        onRefresh: _liveRoomController.queryLiveUrl,
        shouldIgnoreShortcuts: () => _windowsDanmakuFocusNode.hasFocus,
        child: child,
      );
    }
    // 页面根参照系：归位目标矩形以此量取
    return KeyedSubtree(
      key: _pageRootKey,
      child: Theme(
        data: ThemeUtils.darkTheme,
        child: child,
      ),
    );
  }

  Widget get childWhenWindowsNeo => Obx(() {
    final fullScreen = isFullScreen || plPlayerController.isDesktopPip;
    return Scaffold(
      backgroundColor: _windowsTokens.background,
      resizeToAvoidBottomInset: false,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          if (fullScreen) {
            return ColoredBox(
              color: Colors.black,
              child: SizedBox.expand(
                child: videoPlayerPanel(
                  true,
                  width: width,
                  height: height,
                ),
              ),
            );
          }
          final useSidePanel = WindowsNeoVideoLayout.useSidePanel(
            width,
            height,
          );
          return Column(
            children: [
              SizedBox(
                height: 56,
                child: _buildAppBar(
                  false,
                  automaticallyImplyLeading: false,
                  backgroundColor: _windowsTokens.surface,
                ),
              ),
              Divider(height: 1, color: _windowsTokens.border),
              Expanded(
                child: useSidePanel
                    ? _buildWindowsWideLayout(width, height - 57)
                    : _buildWindowsCompactLayout(width, height - 57),
              ),
            ],
          );
        },
      ),
    );
  });

  Widget _buildWindowsWideLayout(double width, double height) {
    final sideWidth = WindowsNeoVideoLayout.sidePanelWidth(
      width,
      visible: true,
      preferredWidth: _windowsSidePanelWidth,
    );
    final playerWidth = width - sideWidth - 6;
    return Row(
      children: [
        _buildWindowsSidePanelResizeHandle(width, sideWidth),
        SizedBox(
          width: playerWidth,
          height: height,
          child: ColoredBox(
            color: Colors.black,
            child: _buildWindowsMediaStage(
              width: playerWidth,
              height: height,
            ),
          ),
        ),
        SizedBox(
          width: sideWidth,
          height: height,
          child: _buildWindowsSidePanel(),
        ),
      ],
    );
  }

  Widget _buildWindowsSidePanelResizeHandle(double width, double sideWidth) =>
      MouseRegion(
        cursor: SystemMouseCursors.resizeColumn,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragUpdate: (details) {
            setState(() {
              _windowsSidePanelWidth =
                  WindowsNeoVideoLayout.clampSidePanelWidth(
                    sideWidth - details.delta.dx,
                    width,
                  );
            });
          },
          child: SizedBox(
            width: 6,
            child: Center(
              child: Container(width: 1, color: _windowsTokens.border),
            ),
          ),
        ),
      );

  Widget _buildWindowsCompactLayout(double width, double height) {
    final playerHeight = WindowsNeoVideoLayout.compactPlayerHeight(
      width,
      height,
    );
    return Column(
      children: [
        SizedBox(
          width: width,
          height: playerHeight,
          child: ColoredBox(
            color: Colors.black,
            child: _buildWindowsMediaStage(
              width: width,
              height: playerHeight,
            ),
          ),
        ),
        Divider(height: 1, color: _windowsTokens.border),
        Expanded(child: _buildWindowsSidePanel()),
      ],
    );
  }

  Widget _buildWindowsSidePanel() {
    final showSuperChat = _liveRoomController.showSuperChat;
    final darkPanel = switch (_windowsTokens.family) {
      WindowsNeoThemeFamily.ark ||
      WindowsNeoThemeFamily.exAstris ||
      WindowsNeoThemeFamily.corporate => true,
      _ => false,
    };
    final panelForeground = darkPanel ? Colors.white : _windowsTokens.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: darkPanel
            ? _windowsTokens.chromeSurface
            : _windowsTokens.surface,
        border: Border(
          left: BorderSide(
            color: darkPanel
                ? Colors.white.withValues(alpha: 0.14)
                : _windowsTokens.border.withValues(alpha: 0.72),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 18,
            offset: const Offset(-4, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 44,
            child: TabBar(
              controller: _windowsSideTabController,
              tabs: [
                const Tab(text: '\u804a\u5929'),
                if (showSuperChat)
                  Tab(
                    child: Obx(() {
                      final count = _liveRoomController.superChatMsg.length;
                      return Text(count == 0 ? 'SC' : 'SC $count');
                    }),
                  ),
                const Tab(text: '\u8d21\u732e\u699c'),
              ],
              dividerColor: Colors.transparent,
              dividerHeight: 0,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 5,
              ),
              indicator: WindowsNeoTabIndicator(
                tokens: _windowsTokens,
                width: 30,
              ),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
              labelColor: panelForeground,
              unselectedLabelColor: darkPanel
                  ? Colors.white.withValues(alpha: 0.62)
                  : _windowsTokens.muted,
              overlayColor: WidgetStatePropertyAll(
                _windowsTokens.hover.withValues(alpha: 0.7),
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _windowsTokens.border.withValues(alpha: 0.68),
              borderRadius: BorderRadius.zero,
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _windowsSideTabController,
              children: [
                _buildWindowsChatPanel(),
                if (showSuperChat)
                  SuperChatPanel(
                    key: scKey,
                    controller: _liveRoomController,
                  ),
                Obx(() {
                  _liveRoomController.isLoaded.value;
                  final ruid = _liveRoomController.ruid;
                  if (ruid == null) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return ContributionRankPanel(
                    key: ValueKey('${_liveRoomController.roomId}-$ruid'),
                    ruid: ruid,
                    roomId: _liveRoomController.roomId,
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowsMediaStage({
    required double width,
    required double height,
  }) => AnimatedBuilder(
    animation: _windowsSideTabController,
    child: videoPlayerPanel(false, width: width, height: height),
    builder: (context, player) => WindowsNeoMediaStage(
      mode: WindowsNeoStageMode.live,
      scene: WindowsNeoStageScene.live,
      stateLabel: _liveRoomController.showSuperChat ? 'CHAT / SC' : 'CHAT',
      stateIndex: _windowsSideTabController.index,
      child: player!,
    ),
  );

  Widget _buildWindowsChatPanel() => Column(
    children: [
      Expanded(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final emotePanelHeight = min(380.0, constraints.maxHeight - 8);
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: LiveRoomChatPanel(
                    key: chatKey,
                    isPP: false,
                    roomId: _liveRoomController.roomId,
                    liveRoomController: _liveRoomController,
                    hideSuperChat: true,
                    onAtUser: _insertWindowsMention,
                  ),
                ),
                if (_windowsEmotePanelVisible && emotePanelHeight > 0)
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 0,
                    height: emotePanelHeight,
                    child: _buildWindowsEmotePanel(),
                  ),
              ],
            );
          },
        ),
      ),
      _buildWindowsInlineInput(),
    ],
  );

  Widget videoPlayerPanel(
    bool isFullScreen, {
    required double width,
    required double height,
    bool isPipMode = false,
    Color fill = Colors.black,
    Alignment alignment = Alignment.center,
    bool needDm = true,
  }) {
    if (!isFullScreen &&
        !plPlayerController.isDesktopPip &&
        _liveRoomController.fsSC.value != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            !isFullScreen &&
            !plPlayerController.isDesktopPip &&
            _liveRoomController.fsSC.value != null) {
          _liveRoomController.fsSC.value = null;
        }
      });
    }
    _liveRoomController.isFullScreen = isFullScreen;
    Widget player = Obx(
      key: playerKey,
      () {
        if (_liveRoomController.isLoaded.value && plPlayerController.isLive) {
          final roomInfoH5 = _liveRoomController.roomInfoH5.value;
          return PLVideoPlayer(
            key: ValueKey(
              'live-player-${_liveRoomController.roomId}-$isPipMode',
            ),
            maxWidth: width,
            maxHeight: height,
            isPipMode: isPipMode,
            fill: fill,
            alignment: alignment,
            plPlayerController: plPlayerController,
            headerControl: LiveHeaderControl(
              key: _liveRoomController.headerKey,
              title: roomInfoH5?.roomInfo?.title,
              upName: roomInfoH5?.anchorInfo?.baseInfo?.uname,
              plPlayerController: plPlayerController,
              onSendDanmaku: WindowsVideoTabService.enabled && !isFullScreen
                  ? _focusWindowsDanmaku
                  : _liveRoomController.onSendDanmaku,
              onPlayAudio: _liveRoomController.queryLiveUrl,
              isPortrait: isPortrait,
              liveController: _liveRoomController,
              onlineWidget: onlineWidget,
            ),
            bottomControl: BottomControl(
              plPlayerController: plPlayerController,
              liveRoomCtr: _liveRoomController,
              onRefresh: _liveRoomController.queryLiveUrl,
            ),
            danmuWidget: !needDm
                ? null
                : LiveDanmaku(
                    liveRoomController: _liveRoomController,
                    plPlayerController: plPlayerController,
                    isFullScreen: isFullScreen,
                    isPipMode: plPlayerController.isDesktopPip || isPipMode,
                    size: Size(width, height),
                  ),
          );
        }
        return const SizedBox.shrink();
      },
    );
    if (_liveRoomController.showSuperChat &&
        (isFullScreen || plPlayerController.isDesktopPip)) {
      player = Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: player),
          if (kDebugMode) ...[
            Positioned(
              top: 50,
              right: 0,
              child: TextButton(
                onPressed: () {
                  final item = SuperChatItem.random;
                  _liveRoomController
                    ..fsSC.value = item
                    ..addDm(item);
                },
                child: const Text('add superchat'),
              ),
            ),
            Positioned(
              right: 0,
              top: 90,
              child: TextButton(
                onPressed: () {
                  _liveRoomController.fsSC.value = null;
                },
                child: const Text('remove superchat'),
              ),
            ),
          ],
          Positioned(
            left: padding.left + 25,
            bottom: 25,
            width: fullScreenSCWidth,
            child: Obx(() {
              final item = _liveRoomController.fsSC.value;
              if (item == null) {
                return const SizedBox.shrink();
              }
              try {
                return ExtraHitTestStack(
                  key: ValueKey(item.id),
                  clipBehavior: Clip.none,
                  children: [
                    SuperChatCard(
                      item: item,
                      onRemove: () => _liveRoomController.fsSC.value = null,
                      onReport: () => _liveRoomController.reportSC(item),
                    ),
                    Positioned(
                      right: -6,
                      top: -6,
                      child: iconButton(
                        size: 24,
                        iconSize: 14,
                        bgColor: const Color(0xEEFFFFFF),
                        iconColor: Colors.black54,
                        icon: const Icon(Icons.clear),
                        onPressed: () => _liveRoomController.fsSC.value = null,
                      ),
                    ),
                  ],
                );
              } catch (_) {
                if (kDebugMode) rethrow;
                return const SizedBox.shrink();
              }
            }),
          ),
        ],
      );
    }
    final Widget result = popScope(
      canPop: !isFullScreen && !plPlayerController.isDesktopPip,
      onPopInvokedWithResult: _onPopInvokedWithResult,
      child: player,
    );
    // 归位动画中：透明占位参与布局（供量取目标矩形）但不可见不可点，
    // 小窗是唯一可见端，恢复握手完成后亮出
    return _pipRestoreInFlight
        ? IgnorePointer(child: Opacity(opacity: 0, child: result))
        : result;
  }

  void _onPopInvokedWithResult(bool didPop, Object? result) {
    if (didPop) {
      _startLivePipIfNeeded();
    }
    plPlayerController.onPopInvokedWithResult(
      didPop,
      result,
      pauseOnPop: !_isEnteringPipMode,
    );
  }

  bool _shouldStartLivePip() {
    if (!Pref.enableInAppPip) {
      return false;
    }
    if (LivePipOverlayService.isInPipMode) {
      return false;
    }
    if (plPlayerController.isDesktopPip || plPlayerController.isPipMode) {
      return false;
    }
    if (!plPlayerController.isLive) {
      return false;
    }
    // 如果即将进入听视频界面，不开启小窗(没啥用，直播间没有相关入口，但还是留着吧？)
    if (Get.currentRoute == '/audio') {
      return false;
    }
    return true;
  }

  void _startLivePipIfNeeded() {
    if (!_shouldStartLivePip()) {
      return;
    }
    // 设置小窗模式标志
    _liveRoomController.isInPipMode.value = true;
    _isEnteringPipMode = true;
    // 继续播放直播消息
    _liveRoomController.startLiveMsg();

    try {
      LivePipOverlayService.startLivePip(
        context: context,
        heroTag: heroTag,
        roomId: _liveRoomController.roomId,
        plPlayerController: plPlayerController,
        controller: _liveRoomController,
        // 收起动画源矩形：页面播放器当前屏幕位置；量取失败则无动画直接出现
        sourceRect: _livePlayerRect(),
        onClose: () {
          _isEnteringPipMode = false;
          _liveRoomController.isInPipMode.value = false;
          _handleLivePipCloseCleanup();
        },
        onReturn: () {
          _isEnteringPipMode = false;
          Get.toNamed(
            '/liveRoom',
            arguments: {
              'roomId': _liveRoomController.roomId,
              'fromPip': true,
            },
          );
        },
      );
    } catch (e) {
      // PiP 启动失败，重置状态
      _isEnteringPipMode = false;
      _liveRoomController.isInPipMode.value = false;
      logger.e('Failed to start live PiP: $e');
    }
  }

  void _handleLivePipCloseCleanup() {
    if (plPlayerController.isCloseAll) {
      return;
    }
    _liveRoomController.isInPipMode.value = false;
    // 路由 pop 时 onClose 已因 isInPipMode 跳过清理，下方 Get.delete 对已
    // 注销实例是空操作，弹幕流与计时器需在此显式关闭
    _liveRoomController
      ..closeLiveMsg()
      ..cancelLiveTimer()
      ..cancelLikeTimer();
    videoPlayerServiceHandler?.onVideoDetailDispose(heroTag);
    if (Platform.isAndroid && !plPlayerController.setSystemBrightness) {
      ScreenBrightnessPlatform.instance.resetApplicationScreenBrightness();
    }
    PlPlayerController.setPlayCallBack(null);
    plPlayerController
      ..removeStatusLister(playerListener)
      ..dispose();

    // 彻底清理永久控制器
    Get.delete<LiveRoomController>(tag: heroTag, force: true);
  }

  Widget get childWhenDisabled {
    return Obx(() {
      final isFullScreen = this.isFullScreen || plPlayerController.isDesktopPip;
      return Stack(
        clipBehavior: Clip.none,
        children: [
          const SizedBox.expand(child: ColoredBox(color: Colors.black)),
          if (!isFullScreen)
            Obx(
              () {
                final appBackground = _liveRoomController
                    .roomInfoH5
                    .value
                    ?.roomInfo
                    ?.appBackground;
                Widget child;
                if (appBackground != null && appBackground.isNotEmpty) {
                  child = CachedNetworkImage(
                    fit: BoxFit.cover,
                    width: maxWidth,
                    height: maxHeight,
                    memCacheWidth: maxWidth.cacheSize(context),
                    imageUrl: ImageUtils.safeThumbnailUrl(appBackground),
                    placeholder: (_, _) => const SizedBox.shrink(),
                  );
                } else {
                  child = Image.asset(
                    Assets.livingBackground,
                    fit: BoxFit.cover,
                    width: maxWidth,
                    height: maxHeight,
                    cacheWidth: maxWidth.cacheSize(context),
                  );
                }
                return Positioned.fill(
                  child: Opacity(opacity: 0.6, child: child),
                );
              },
            ),
          ScaffoldLayout(
            appBar: isWindowMode && isFullScreen && !isPortrait
                ? null
                : _buildAppBar(isFullScreen),
            body: isPortrait
                ? Obx(
                    () {
                      if (_liveRoomController.isPortrait.value) {
                        return _buildPP(isFullScreen);
                      }
                      return _buildPH(isFullScreen);
                    },
                  )
                : _buildBodyH(isFullScreen),
          ),
        ],
      );
    });
  }

  Widget _buildPH(bool isFullScreen) {
    final height = maxWidth / Style.aspectRatio16x9;
    final videoHeight = isFullScreen
        ? maxHeight - (isWindowMode && !isPortrait ? 0 : padding.top)
        : height;
    final bottomHeight = maxHeight - padding.top - height - kToolbarHeight;
    return Column(
      children: [
        SizedBox(
          width: maxWidth,
          height: videoHeight,
          child: videoPlayerPanel(
            isFullScreen,
            width: maxWidth,
            height: videoHeight,
          ),
        ),
        Offstage(
          offstage: isFullScreen,
          child: SizedBox(
            width: maxWidth,
            height: max(0, bottomHeight),
            child: _buildBottomWidget,
          ),
        ),
      ],
    );
  }

  Widget _buildPP(bool isFullScreen) {
    final bottomHeight = 70 + padding.bottom;
    final videoHeight = isFullScreen
        ? maxHeight - (isWindowMode && !isPortrait ? 0 : padding.top)
        : maxHeight - bottomHeight;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          bottom: isFullScreen ? 0 : bottomHeight,
          child: videoPlayerPanel(
            width: maxWidth,
            height: videoHeight,
            isFullScreen,
            needDm: isFullScreen,
            alignment: isFullScreen ? Alignment.center : Alignment.topCenter,
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 55 + bottomHeight,
          height: maxHeight * 0.32,
          child: Offstage(
            offstage: isFullScreen,
            child: _buildChatWidget(true),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomHeight,
          child: Offstage(
            offstage: isFullScreen,
            child: _buildInputWidget,
          ),
        ),
      ],
    );
  }

  Widget get onlineWidget => GestureDetector(
    onTap: _showRank,
    child: Obx(() {
      if (_liveRoomController.onlineCount.value case final onlineCount?) {
        return Text(
          '高能观众($onlineCount)',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white,
          ),
        );
      }
      return const SizedBox.shrink();
    }),
  );

  void _showRank() {
    if (_liveRoomController.ruid case final ruid?) {
      final heightFactor = PlatformUtils.isMobile && !isPortrait ? 1.0 : 0.7;
      showModalBottomSheet(
        context: context,
        useSafeArea: true,
        clipBehavior: .hardEdge,
        isScrollControlled: true,
        constraints: const BoxConstraints(maxWidth: 450),
        builder: (context) => FractionallySizedBox(
          widthFactor: 1.0,
          heightFactor: heightFactor,
          child: ContributionRankPanel(
            ruid: ruid,
            roomId: _liveRoomController.roomId,
          ),
        ),
      );
    }
  }

  PreferredSizeWidget _buildAppBar(
    bool isFullScreen, {
    bool automaticallyImplyLeading = true,
    Color? backgroundColor,
  }) {
    return AppBar(
      primary: !plPlayerController.removeSafeArea,
      toolbarHeight: isFullScreen ? 0 : null,
      backgroundColor: backgroundColor ?? Colors.transparent,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: automaticallyImplyLeading,
      titleTextStyle: const TextStyle(color: Colors.white),
      title: isFullScreen || plPlayerController.isDesktopPip
          ? null
          : Obx(
              () {
                RoomInfoH5Data? roomInfoH5 =
                    _liveRoomController.roomInfoH5.value;
                if (roomInfoH5 == null) {
                  return const SizedBox.shrink();
                }
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => PageUtils.toMember(roomInfoH5.roomInfo?.uid),
                  child: Row(
                    spacing: 10,
                    mainAxisSize: .min,
                    children: [
                      NetworkImgLayer(
                        width: 34,
                        height: 34,
                        type: .avatar,
                        src: roomInfoH5.anchorInfo!.baseInfo!.face,
                      ),
                      Flexible(
                        child: Column(
                          spacing: 1,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              spacing: 10,
                              mainAxisSize: .min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: Text(
                                    roomInfoH5.anchorInfo!.baseInfo!.uname!,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                onlineWidget,
                              ],
                            ),
                            Row(
                              spacing: 10,
                              mainAxisSize: .min,
                              children: [
                                _liveRoomController.watchedWidget,
                                _liveRoomController.timeWidget,
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
      actions: [
        // IconButton(
        //   tooltip: '刷新',
        //   onPressed: _liveRoomController.queryLiveUrl,
        //   icon: const Icon(Icons.refresh, size: 20),
        // ),
        StaticPopupMenuButton(
          icon: const Icon(Icons.more_vert, size: 20),
          itemBuilder: (BuildContext context) {
            final liveUrl =
                'https://live.bilibili.com/${_liveRoomController.roomId}';
            return <PopupMenuEntry>[
              PopupMenuItem(
                onTap: () => Utils.copyText(liveUrl),
                child: const Row(
                  spacing: 10,
                  mainAxisSize: .min,
                  children: [
                    Icon(Icons.copy, size: 19),
                    Text('复制链接'),
                  ],
                ),
              ),
              if (PlatformUtils.isMobile)
                PopupMenuItem(
                  onTap: () => ShareUtils.shareText(liveUrl),
                  child: const Row(
                    spacing: 10,
                    mainAxisSize: .min,
                    children: [
                      Icon(Icons.share, size: 19),
                      Text('分享直播间'),
                    ],
                  ),
                ),
              PopupMenuItem(
                onTap: () => PageUtils.inAppWebview(liveUrl, off: true),
                child: const Row(
                  spacing: 10,
                  mainAxisSize: .min,
                  children: [
                    Icon(Icons.open_in_browser, size: 19),
                    Text('浏览器打开'),
                  ],
                ),
              ),
              if (_liveRoomController.roomInfoH5.value != null)
                PopupMenuItem(
                  onTap: () {
                    try {
                      RoomInfoH5Data roomInfo =
                          _liveRoomController.roomInfoH5.value!;
                      PageUtils.pmShare(
                        this.context,
                        content: {
                          "cover": roomInfo.roomInfo!.cover!,
                          "sourceID": _liveRoomController.roomId.toString(),
                          "title": roomInfo.roomInfo!.title!,
                          "url": liveUrl,
                          "authorID": roomInfo.roomInfo!.uid.toString(),
                          "source": "直播",
                          "desc": roomInfo.roomInfo!.title!,
                          "author": roomInfo.anchorInfo!.baseInfo!.uname,
                        },
                      );
                    } catch (e) {
                      SmartDialog.showToast(e.toString());
                    }
                  },
                  child: const Row(
                    spacing: 10,
                    mainAxisSize: .min,
                    children: [
                      Icon(Icons.forward_to_inbox, size: 19),
                      Text('分享至消息'),
                    ],
                  ),
                ),
            ];
          },
        ),
      ],
    );
  }

  Widget _buildBodyH(bool isFullScreen) {
    double videoWidth =
        clampDouble(maxHeight / maxWidth * 1.08, 0.56, 0.7) * maxWidth;
    final rightWidth = min(400.0, maxWidth - videoWidth - padding.horizontal);
    videoWidth = maxWidth - rightWidth - padding.horizontal;
    final videoHeight = maxHeight - padding.top - kToolbarHeight;
    final width = isFullScreen ? maxWidth : videoWidth;
    final height = isFullScreen
        ? maxHeight - (isWindowMode && !isPortrait ? 0 : padding.top)
        : videoHeight;
    return Padding(
      padding: isFullScreen
          ? EdgeInsets.zero
          : EdgeInsets.only(left: padding.left, right: padding.right),
      child: Row(
        children: [
          Container(
            width: width,
            height: height,
            margin: EdgeInsets.only(bottom: padding.bottom),
            child: videoPlayerPanel(
              isFullScreen,
              fill: Colors.transparent,
              width: width,
              height: height,
            ),
          ),
          Offstage(
            offstage: isFullScreen,
            child: SizedBox(
              width: rightWidth,
              height: videoHeight,
              child: _buildBottomWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget get _buildBottomWidget => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: _buildChatWidget()),
      _buildInputWidget,
    ],
  );

  Widget _buildChatWidget([bool isPP = false]) {
    Widget chat() => LiveRoomChatPanel(
      key: chatKey,
      isPP: isPP,
      roomId: _liveRoomController.roomId,
      liveRoomController: _liveRoomController,
      onAtUser: (item) => _liveRoomController
        ..savedDanmaku = [
          RichTextItem.fromStart(
            '@${item.name} ',
            rawText: item.extra.mid.toString(),
            type: .at,
            id: item.extra.id.toString(),
          ),
        ]
        ..onSendDanmaku(),
    );
    return Padding(
      padding: .only(bottom: 12, top: isPortrait ? 12 : 0),
      child: _liveRoomController.showSuperChat
          ? PageView(
              key: pageKey,
              controller: _liveRoomController.pageController,
              physics: tabBarScrollPhysics,
              onPageChanged: _liveRoomController.pageIndex.call,
              horizontalDragGestureRecognizer:
                  CustomHorizontalDragGestureRecognizer.new,
              children: [
                KeepAliveWrapper(child: chat()),
                SuperChatPanel(
                  key: scKey,
                  controller: _liveRoomController,
                ),
              ],
            )
          : chat(),
    );
  }

  void _insertWindowsMention(DanmakuMsg item) {
    final current = _windowsDanmakuTextController.text;
    final separator = current.isEmpty || current.endsWith(' ') ? '' : ' ';
    final next = '$current$separator@${item.name} ';
    _windowsDanmakuTextController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    _windowsDanmakuFocusNode.requestFocus();
  }

  void _focusWindowsDanmaku() => _windowsDanmakuFocusNode.requestFocus();

  void _toggleWindowsEmotePanel() {
    if (kReleaseMode && !_liveRoomController.isLogin) {
      SmartDialog.showToast('账号未登录');
      return;
    }
    setState(() => _windowsEmotePanelVisible = !_windowsEmotePanelVisible);
  }

  void _insertWindowsEmote(Emoticon emote, double? _, double? __) {
    final emoji = emote.emoji;
    if (emoji == null || emoji.isEmpty) return;
    final value = _windowsDanmakuTextController.value;
    final selection = value.selection.isValid
        ? value.selection
        : TextSelection.collapsed(offset: value.text.length);
    final text = value.text.replaceRange(selection.start, selection.end, emoji);
    _windowsDanmakuTextController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(
        offset: selection.start + emoji.length,
      ),
    );
    setState(() => _windowsEmotePanelVisible = false);
    _windowsDanmakuFocusNode.requestFocus();
  }

  Future<void> _sendWindowsEmoticon(Emoticon emote) async {
    final emoticonUnique = emote.emoticonUnique;
    if (emoticonUnique == null ||
        emoticonUnique.isEmpty ||
        _windowsDanmakuSending) {
      return;
    }
    setState(() {
      _windowsDanmakuSending = true;
      _windowsEmotePanelVisible = false;
    });
    final res = await LiveHttp.sendLiveMsg(
      roomId: _liveRoomController.roomId,
      msg: emoticonUnique,
      dmType: 1,
      emoticonOptions: '[object Object]',
    );
    if (!mounted) return;
    if (!res.isSuccess) res.toast();
    setState(() => _windowsDanmakuSending = false);
  }

  Widget _buildWindowsEmotePanel() => DecoratedBox(
    decoration: BoxDecoration(
      color: _windowsTokens.chromeSurface,
      border: Border.all(color: _windowsTokens.border.withValues(alpha: 0.82)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.36),
          blurRadius: 18,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: LiveEmotePanel(
      roomId: _liveRoomController.roomId,
      onChoose: _insertWindowsEmote,
      onSendEmoticonUnique: _sendWindowsEmoticon,
    ),
  );

  KeyEventResult _handleWindowsDanmakuKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      _sendWindowsDanmaku();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _sendWindowsDanmaku() async {
    final message = _windowsDanmakuTextController.text.trim();
    if (message.isEmpty || _windowsDanmakuSending) return;
    if (kReleaseMode && !_liveRoomController.isLogin) {
      SmartDialog.showToast('账号未登录');
      return;
    }

    setState(() => _windowsDanmakuSending = true);
    final res = await LiveHttp.sendLiveMsg(
      roomId: _liveRoomController.roomId,
      msg: message,
    );
    if (!mounted) return;
    if (res.isSuccess) {
      _windowsDanmakuTextController.clear();
      _windowsDanmakuFocusNode.requestFocus();
    } else {
      res.toast();
    }
    setState(() => _windowsDanmakuSending = false);
  }

  Widget _buildWindowsInlineInput() {
    final tokens = _windowsTokens;
    final darkComposer = switch (tokens.family) {
      WindowsNeoThemeFamily.ark ||
      WindowsNeoThemeFamily.exAstris ||
      WindowsNeoThemeFamily.corporate => true,
      _ => false,
    };
    final composerSurface = darkComposer
        ? tokens.chromeSurface
        : tokens.surfaceRaised;
    final composerInk = darkComposer ? Colors.white : tokens.ink;
    final sendForeground = tokens.accent.computeLuminance() > 0.50
        ? Colors.black
        : Colors.white;
    return Container(
      constraints: const BoxConstraints(minHeight: 62, maxHeight: 126),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: composerSurface,
        border: Border(
          top: BorderSide(
            color: darkComposer
                ? Colors.white.withValues(alpha: 0.16)
                : tokens.border.withValues(alpha: 0.72),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        spacing: 6,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Obx(() {
            final enabled = plPlayerController.enableShowDanmaku.value;
            return IconButton(
              tooltip: enabled ? '关闭弹幕' : '开启弹幕',
              onPressed: () {
                final newValue = !enabled;
                plPlayerController.enableShowDanmaku.value = newValue;
                if (!plPlayerController.tempPlayerConf) {
                  GStorage.setting.put(
                    SettingBoxKey.enableShowLiveDanmaku,
                    newValue,
                  );
                }
              },
              color: enabled ? tokens.accent : tokens.muted,
              icon: Icon(
                enabled ? CustomIcons.dm_on : CustomIcons.dm_off,
                size: 20,
              ),
            );
          }),
          Expanded(
            child: TextField(
              controller: _windowsDanmakuTextController,
              focusNode: _windowsDanmakuFocusNode,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendWindowsDanmaku(),
              style: TextStyle(color: composerInk, fontSize: 14),
              decoration: InputDecoration(
                hintText: '输入弹幕，按 Enter 发送',
                hintStyle: TextStyle(
                  color: darkComposer
                      ? Colors.white.withValues(alpha: 0.50)
                      : tokens.muted,
                ),
                filled: true,
                fillColor: darkComposer
                    ? Colors.white.withValues(alpha: 0.07)
                    : tokens.hover.withValues(alpha: 0.62),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: tokens.actionRadius,
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: tokens.actionRadius,
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: tokens.actionRadius,
                  borderSide: BorderSide(
                    color: tokens.accent.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '表情',
            onPressed: _toggleWindowsEmotePanel,
            color: _windowsEmotePanelVisible ? tokens.accent : tokens.muted,
            icon: Icon(
              _windowsEmotePanelVisible
                  ? Icons.emoji_emotions
                  : Icons.emoji_emotions_outlined,
              size: 20,
            ),
          ),
          Builder(
            builder: (context) => Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: tokens.actionRadius,
                onTapDown: _liveRoomController.onLikeTapDown,
                onTapUp: _liveRoomController.onLikeTapUp,
                onTapCancel: _liveRoomController.onLikeTapUp,
                child: Tooltip(
                  message: '点赞',
                  child: SizedBox.square(
                    dimension: 40,
                    child: Icon(
                      Icons.thumb_up_off_alt,
                      size: 20,
                      color: tokens.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _windowsDanmakuTextController,
            builder: (context, value, _) {
              final canSend =
                  value.text.trim().isNotEmpty && !_windowsDanmakuSending;
              return IconButton.filled(
                tooltip: '发送',
                onPressed: canSend ? _sendWindowsDanmaku : null,
                style: IconButton.styleFrom(
                  backgroundColor: tokens.accent,
                  foregroundColor: sendForeground,
                  disabledBackgroundColor: tokens.hover,
                  disabledForegroundColor: tokens.muted,
                ),
                icon: _windowsDanmakuSending
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded, size: 18),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget get _buildInputWidget {
    final isWindowsNeo = WindowsVideoTabService.enabled;
    if (isWindowsNeo) return _buildWindowsInlineInput();
    final child = Container(
      padding: .only(top: 5, left: 10, right: 10, bottom: padding.bottom),
      height: 70 + padding.bottom,
      decoration: BoxDecoration(
        borderRadius: isWindowsNeo
            ? BorderRadius.zero
            : const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top: BorderSide(
            color: isWindowsNeo
                ? _windowsTokens.border
                : const Color(0x1AFFFFFF),
          ),
        ),
        color: isWindowsNeo
            ? _windowsTokens.surfaceRaised
            : const Color(0x1AFFFFFF),
      ),
      child: GestureDetector(
        onTap: _liveRoomController.onSendDanmaku,
        behavior: .opaque,
        child: Padding(
          padding: const .only(top: 5, bottom: 10),
          child: Align(
            alignment: .topCenter,
            child: Row(
              spacing: 6,
              children: [
                Obx(
                  () {
                    final enableShowLiveDanmaku =
                        plPlayerController.enableShowLiveDanmaku.value;
                    return SizedBox(
                      width: 34,
                      height: 34,
                      child: IconButton(
                        style: IconButton.styleFrom(padding: .zero),
                        onPressed: () {
                          final newVal = !enableShowLiveDanmaku;
                          plPlayerController.enableShowLiveDanmaku.value =
                              newVal;
                          if (!plPlayerController.tempPlayerConf) {
                            GStorage.setting.put(
                              SettingBoxKey.enableShowLiveDanmaku,
                              newVal,
                            );
                          }
                        },
                        icon: enableShowLiveDanmaku
                            ? const Icon(
                                size: 22,
                                CustomIcons.dm_on,
                                color: baseWhite,
                              )
                            : const Icon(
                                size: 22,
                                CustomIcons.dm_off,
                                color: baseWhite,
                              ),
                      ),
                    );
                  },
                ),
                const Expanded(
                  child: Text(
                    '发送弹幕',
                    style: TextStyle(color: baseWhite),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final colorScheme = Theme.of(context).colorScheme;
                    return Material(
                      type: MaterialType.transparency,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          InkWell(
                            overlayColor: overlayColor(colorScheme),
                            customBorder: const CircleBorder(),
                            onTapDown: _liveRoomController.onLikeTapDown,
                            onTapUp: _liveRoomController.onLikeTapUp,
                            onTapCancel: _liveRoomController.onLikeTapUp,
                            child: const SizedBox.square(
                              dimension: 34,
                              child: Icon(
                                size: 22,
                                color: baseWhite,
                                Icons.thumb_up_off_alt,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 30,
                            top: -12,
                            child: Obx(() {
                              final likeClickTime =
                                  _liveRoomController.likeClickTime.value;
                              if (likeClickTime == 0) {
                                return const SizedBox.shrink();
                              }
                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Text(
                                  key: ValueKey(likeClickTime),
                                  'x$likeClickTime',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: colorScheme.isDark
                                        ? colorScheme.primary
                                        : colorScheme.inversePrimary,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                SizedBox(
                  width: 34,
                  height: 34,
                  child: IconButton(
                    style: IconButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: () => _liveRoomController.onSendDanmaku(true),
                    icon: const Icon(
                      size: 22,
                      color: baseWhite,
                      Icons.emoji_emotions_outlined,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (_liveRoomController.showSuperChat) {
      return Stack(
        children: [
          child,
          Positioned(
            left: 0,
            top: 0,
            right: 0,
            child: Obx(
              () => _BorderIndicator(
                radius: const Radius.circular(20),
                isLeft: _liveRoomController.pageIndex.value == 0,
              ),
            ),
          ),
        ],
      );
    }
    return child;
  }

  WidgetStateProperty<Color?>? overlayColor(ColorScheme theme) =>
      WidgetStateProperty.resolveWith((Set<WidgetState> states) {
        if (states.contains(WidgetState.selected)) {
          if (states.contains(WidgetState.pressed)) {
            return theme.primary.withValues(alpha: 0.1);
          }
          if (states.contains(WidgetState.hovered)) {
            return theme.primary.withValues(alpha: 0.08);
          }
          if (states.contains(WidgetState.focused)) {
            return theme.primary.withValues(alpha: 0.1);
          }
        }
        if (states.contains(WidgetState.pressed)) {
          return theme.onSurfaceVariant.withValues(alpha: 0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return theme.onSurfaceVariant.withValues(alpha: 0.08);
        }
        if (states.contains(WidgetState.focused)) {
          return theme.onSurfaceVariant.withValues(alpha: 0.1);
        }
        return Colors.transparent;
      });
}

class _BorderIndicator extends LeafRenderObjectWidget {
  const _BorderIndicator({
    required this.radius,
    required this.isLeft,
  });

  final Radius radius;
  final bool isLeft;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderBorderIndicator(
      radius: radius,
      isLeft: isLeft,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBorderIndicator renderObject,
  ) {
    renderObject
      ..radius = radius
      ..isLeft = isLeft;
  }
}

class _RenderBorderIndicator extends RenderBox {
  _RenderBorderIndicator({
    required this._radius,
    required this._isLeft,
  });

  Radius _radius;
  Radius get radius => _radius;
  set radius(Radius value) {
    if (_radius == value) return;
    _radius = value;
    markNeedsLayout();
  }

  bool _isLeft;
  bool get isLeft => _isLeft;
  set isLeft(bool value) {
    if (_isLeft == value) return;
    _isLeft = value;
    markNeedsPaint();
  }

  @override
  void performLayout() {
    size = constraints.constrainDimensions(constraints.maxWidth, _radius.x);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final size = this.size;
    final canvas = context.canvas;
    final width = size.width / 2;

    BoxBorder.paintNonUniformBorder(
      canvas,
      Rect.fromLTWH(
        offset.dx + (_isLeft ? 0 : width),
        offset.dy,
        width,
        size.height,
      ),
      borderRadius: BorderRadius.only(
        topLeft: _isLeft ? _radius : .zero,
        topRight: _isLeft ? .zero : _radius,
      ),
      textDirection: null,
      top: const BorderSide(),
      color: Colors.white38,
    );
  }
}

class LiveDanmaku extends StatefulWidget {
  final LiveRoomController liveRoomController;
  final PlPlayerController plPlayerController;
  final bool isPipMode;
  final bool isFullScreen;
  final Size size;

  const LiveDanmaku({
    super.key,
    required this.liveRoomController,
    required this.plPlayerController,
    this.isPipMode = false,
    required this.isFullScreen,
    required this.size,
  });

  @override
  State<LiveDanmaku> createState() => _LiveDanmakuState();

  bool get notFullscreen => !isFullScreen || isPipMode;
}

class _LiveDanmakuState extends State<LiveDanmaku> {
  PlPlayerController get plPlayerController => widget.plPlayerController;

  @override
  void didUpdateWidget(LiveDanmaku oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notFullscreen != widget.notFullscreen &&
        !DanmakuOptions.sameFontScale) {
      plPlayerController.danmakuController?.updateOption(
        DanmakuOptions.get(notFullscreen: widget.notFullscreen),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final option = DanmakuOptions.get(notFullscreen: widget.notFullscreen);
    return Obx(
      () => AnimatedOpacity(
        opacity: plPlayerController.enableShowLiveDanmaku.value
            ? plPlayerController.danmakuOpacity.value
            : 0,
        duration: const Duration(milliseconds: 100),
        child: DanmakuScreen<DanmakuExtra>(
          createdController: (e) {
            widget.liveRoomController.danmakuController =
                plPlayerController.danmakuController = e;
          },
          option: option,
          size: widget.size,
        ),
      ),
    );
  }
}
