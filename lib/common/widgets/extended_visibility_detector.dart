import 'package:flutter/widgets.dart';

/// Compatibility wrapper for the nested-scroll visibility hook.
///
/// The Windows branch does not ship the upstream visibility observer. Keeping
/// the keyed wrapper preserves the widget identity and nested-page lifecycle
/// without introducing a platform-specific dependency.
class ExtendedVisibilityDetector extends StatelessWidget {
  const ExtendedVisibilityDetector({
    super.key,
    required this.uniqueKey,
    required this.child,
  });

  final Key uniqueKey;
  final Widget child;

  @override
  Widget build(BuildContext context) => KeyedSubtree(key: uniqueKey, child: child);
}
