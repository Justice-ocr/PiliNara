import 'dart:math';

enum WindowsVideoMemberPresentation { sidePanel, horizontalSheet, fullPage }

abstract final class WindowsNeoVideoLayout {
  static const sidePanelBreakpoint = 960.0;
  static const sidePanelHeightBreakpoint = 560.0;
  static const minSidePanelWidth = 360.0;
  static const maxSidePanelWidth = 460.0;

  static bool useSidePanel(double width, double height) =>
      width >= sidePanelBreakpoint && height >= sidePanelHeightBreakpoint;

  static double sidePanelWidth(
    double width, {
    required bool visible,
    double? preferredWidth,
  }) =>
      visible ? clampSidePanelWidth(preferredWidth ?? width * 0.32, width) : 0;

  static double clampSidePanelWidth(double value, double windowWidth) {
    final maxWidth = min(maxSidePanelWidth + 80, windowWidth * 0.42);
    return min(maxWidth, max(minSidePanelWidth, value));
  }

  static WindowsVideoMemberPresentation memberPresentation({
    required bool windowsNeoEnabled,
    required bool usesSidePanel,
    required bool isPortrait,
    required bool horizontalMemberPage,
  }) {
    if (windowsNeoEnabled) {
      return usesSidePanel
          ? WindowsVideoMemberPresentation.sidePanel
          : WindowsVideoMemberPresentation.fullPage;
    }
    return !isPortrait && horizontalMemberPage
        ? WindowsVideoMemberPresentation.horizontalSheet
        : WindowsVideoMemberPresentation.fullPage;
  }

  static double widePlayerHeight(double mainWidth, double height) =>
      min(mainWidth / (16 / 9), height * 0.66);

  static double compactPlayerHeight(double width, double height) =>
      min(width / (16 / 9), height * 0.52);
}
