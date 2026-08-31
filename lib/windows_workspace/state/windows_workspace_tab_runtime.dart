import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WindowsWorkspaceTabRuntime {
  final Map<String, void Function()> activators = {};
  final Map<String, void Function()> deactivators = {};
  final Map<String, void Function(bool visible, bool focused)> presenters = {};
  final Map<String, RxBool> muteStates = {};
  final Map<String, Future<void> Function(bool muted)> muteSetters = {};
  final Map<String, void Function()> closers = {};
  final Map<String, List<bool Function()>> contextPoppers = {};
  final Map<String, WindowsWorkspaceCachedPlayer> players = {};
  final Map<String, GlobalKey<NavigatorState>> navigatorKeys = {};

  bool hostMounted = false;
}

class WindowsWorkspaceCachedPlayer {
  const WindowsWorkspaceCachedPlayer(this.player, this._dispose);

  final Object player;
  final void Function(Object player) _dispose;

  void dispose() => _dispose(player);
}
