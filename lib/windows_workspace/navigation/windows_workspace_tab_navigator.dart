import 'package:PiliPlus/windows_workspace/models/windows_workspace_tab.dart';
import 'package:PiliPlus/windows_workspace/state/windows_workspace_tab_runtime.dart';
import 'package:flutter/material.dart';

class WindowsWorkspaceTabNavigator {
  WindowsWorkspaceTabNavigator(this._runtime);

  final WindowsWorkspaceTabRuntime _runtime;

  void setHostMounted(bool value) {
    _runtime.hostMounted = value;
    if (!value) {
      _runtime.navigatorKeys.clear();
    }
  }

  GlobalKey<NavigatorState> navigatorKeyFor(String id) =>
      _runtime.navigatorKeys.putIfAbsent(id, GlobalKey<NavigatorState>.new);

  void retainNavigatorKeys(Set<String> ids) {
    _runtime.navigatorKeys.removeWhere((id, _) => !ids.contains(id));
  }

  Future<T?>? pushNamedInActiveTab<T extends Object?>(
    String page, {
    required bool enabled,
    required bool isHostCurrent,
    required String? activeTabId,
    required Set<String> nestedRoutes,
    Object? arguments,
    Map<String, String>? parameters,
    bool replace = false,
  }) {
    if (!enabled || !_runtime.hostMounted || !isHostCurrent) return null;
    final uri = Uri.tryParse(page);
    if (uri == null || !nestedRoutes.contains(uri.path)) return null;
    final navigator = activeTabId == null
        ? null
        : _runtime.navigatorKeys[activeTabId]?.currentState;
    if (navigator == null) return null;
    final routeData = WindowsTabRouteData(
      arguments: arguments,
      parameters: {
        ...uri.queryParameters,
        ...?parameters,
      },
    );
    if (replace) {
      return navigator.pushReplacementNamed<T, Object?>(
        uri.path,
        arguments: routeData,
      );
    }
    return navigator.pushNamed<T>(uri.path, arguments: routeData);
  }

  void popToRoot(String? activeTabId) {
    final navigator = activeTabId == null
        ? null
        : _runtime.navigatorKeys[activeTabId]?.currentState;
    navigator?.popUntil((route) => route.isFirst);
  }

  bool popPage(String? activeTabId) {
    final navigator = activeTabId == null
        ? null
        : _runtime.navigatorKeys[activeTabId]?.currentState;
    if (navigator?.canPop() != true) return false;
    navigator!.pop();
    return true;
  }
}
