import 'dart:io' show Platform;

import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

/// Synchronizes Windows 11 DWM native window attributes (border tint, corner
/// preference, dark chrome hint, and optional backdrop) with the active
/// Windows Neo theme tokens. Safely no-ops on Windows 10, non-Windows, and tests.
abstract final class WindowsDwmBridge {
  static const _channel = MethodChannel('pilinara/windows_dwm');

  static bool? _lastDark;
  static int? _lastCorner;
  static int? _lastBorder;

  /// DWMWCP_ROUND = 2 (soft), DWMWCP_ROUNDSMALL = 3 (tight industrial corner).
  static int _cornerPreferenceFor(WindowsNeoTokens tokens) =>
      tokens.usesRoundedGeometry ? 2 : 3;

  /// Converts a Flutter [Color] to Win32 COLORREF (0x00BBGGRR).
  static int _toColorRef(Color color) {
    final r = (color.r * 255.0).round().clamp(0, 255);
    final g = (color.g * 255.0).round().clamp(0, 255);
    final b = (color.b * 255.0).round().clamp(0, 255);
    return (b << 16) | (g << 8) | r;
  }

  static void sync(WindowsNeoTokens tokens, Brightness brightness) {
    if (!Platform.isWindows) return;
    final dark = brightness == Brightness.dark || tokens.usesDarkChrome;
    final corner = _cornerPreferenceFor(tokens);
    final borderColor = _toColorRef(
      Color.alphaBlend(
        tokens.accentBorder.withValues(alpha: dark ? 0.55 : 0.42),
        tokens.border,
      ),
    );
    if (_lastDark == dark &&
        _lastCorner == corner &&
        _lastBorder == borderColor) {
      return;
    }
    _lastDark = dark;
    _lastCorner = corner;
    _lastBorder = borderColor;

    _channel
        .invokeMethod<void>('syncWindowAppearance', <String, Object>{
          'dark': dark,
          'cornerPreference': corner,
          'borderColor': borderColor,
        })
        .catchError((_) {});
  }
}
