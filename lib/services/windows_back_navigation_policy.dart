abstract final class WindowsBackNavigationPolicy {
  static bool dispatch({
    bool Function()? popContext,
    bool Function()? popPage,
  }) {
    if (popContext?.call() == true) return true;
    return popPage?.call() ?? false;
  }
}
