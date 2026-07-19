abstract final class WindowsNeoDynamicsLayout {
  static const double maxContentWidth = 1380;
  static const double minHorizontalPadding = 24;
  static const double twoColumnBreakpoint = 820;
  static const double threeColumnBreakpoint = 1200;
  static const double gridSpacing = 18;

  static double horizontalPadding(double availableWidth) =>
      availableWidth > maxContentWidth + minHorizontalPadding * 2
      ? (availableWidth - maxContentWidth) / 2
      : minHorizontalPadding;

  static int crossAxisCount(double contentWidth) =>
      contentWidth >= threeColumnBreakpoint
      ? 3
      : contentWidth >= twoColumnBreakpoint
      ? 2
      : 1;
}
