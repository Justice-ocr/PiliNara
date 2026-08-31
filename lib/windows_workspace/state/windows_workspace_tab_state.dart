import 'package:PiliPlus/windows_workspace/models/windows_workspace_tab.dart';
import 'package:get/get.dart';

class WindowsWorkspaceTabState {
  final RxList<WindowsWorkspaceTab> tabs = <WindowsWorkspaceTab>[].obs;
  final RxnString activeId = RxnString();
  final RxSet<String> splitTabIds = <String>{}.obs;
  final RxSet<String> audibleTabIds = <String>{}.obs;
  final RxSet<String> splitDraftTabIds = <String>{}.obs;
  final RxBool splitSelectionMode = false.obs;
  final RxnString maximizedSplitTabId = RxnString();
  final RxDouble splitHorizontalRatio = 0.5.obs;
  final RxDouble splitVerticalRatio = 0.5.obs;
  final List<String> activationHistory = [];
  final List<WindowsWorkspaceTab> closedTabs = [];

  Map? currentArguments;
}
