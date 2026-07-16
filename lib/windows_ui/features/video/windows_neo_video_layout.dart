import 'dart:math';

abstract final class WindowsNeoVideoLayout {
  static const sidePanelBreakpoint = 960.0;
  static const sidePanelHeightBreakpoint = 560.0;
  static const minSidePanelWidth = 360.0;
  static const maxSidePanelWidth = 460.0;

  static bool useSidePanel(double width, double height) =>
      width >= sidePanelBreakpoint && height >= sidePanelHeightBreakpoint;

  static double sidePanelWidth(double width, {required bool visible}) => visible
      ? min(maxSidePanelWidth, max(minSidePanelWidth, width * 0.32))
      : 0;

  static double widePlayerHeight(double mainWidth, double height) =>
      min(mainWidth / (16 / 9), height * 0.66);

  static double compactPlayerHeight(double width, double height) =>
      min(width / (16 / 9), height * 0.52);
}
