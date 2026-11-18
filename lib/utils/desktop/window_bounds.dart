import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:nativeapi/nativeapi.dart' as nativeapi;

/// 窗口尺寸不得超过工作区，避免恢复出一个比屏幕还大的窗口
Size fitWindowSizeToWorkArea(Size windowSize, Rect workArea) => Size(
  math.min(windowSize.width, workArea.width),
  math.min(windowSize.height, workArea.height),
);

/// 最小窗口尺寸不得超过工作区，否则小屏（如 1024×640）上窗口无法收缩到屏幕内
nativeapi.Size fitMinSizeToWorkArea(nativeapi.Size minSize, Rect workArea) =>
    nativeapi.Size(
      width: math.min(minSize.width, workArea.width),
      height: math.min(minSize.height, workArea.height),
    );

/// 计算窗口左上角坐标。
///
/// [savedPosition] 是上次退出时的位置：完全离开工作区后重新居中；
/// 与工作区相交时保留位置并将窗口拉回工作区内。
Offset calcWindowOffset({
  required Size windowSize,
  required Rect workArea,
  Offset? savedPosition,
}) {
  if (savedPosition != null) {
    final savedRect = Rect.fromLTWH(
      savedPosition.dx,
      savedPosition.dy,
      windowSize.width,
      windowSize.height,
    );
    if (savedRect.overlaps(workArea)) {
      return Offset(
        savedPosition.dx.clamp(
          workArea.left,
          math.max(workArea.left, workArea.right - windowSize.width),
        ),
        savedPosition.dy.clamp(
          workArea.top,
          math.max(workArea.top, workArea.bottom - windowSize.height),
        ),
      );
    }
  }

  return Offset(
    workArea.left + (workArea.width - windowSize.width) / 2,
    workArea.top + (workArea.height - windowSize.height) / 2,
  );
}
