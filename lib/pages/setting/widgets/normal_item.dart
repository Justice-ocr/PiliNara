import 'package:PiliPlus/common/widgets/flutter/list_tile.dart';
import 'package:PiliPlus/services/windows_video_tab_service.dart';
import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart' hide ListTile;

class NormalItem extends StatefulWidget {
  final String? title;
  final ValueGetter<String>? getTitle;
  final String? subtitle;
  final ValueGetter<String>? getSubtitle;
  final Widget? leading;
  final Widget Function(ThemeData theme)? getTrailing;
  final void Function(BuildContext context, VoidCallback setState)? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? titleStyle;

  const NormalItem({
    this.title,
    this.getTitle,
    this.subtitle,
    this.getSubtitle,
    this.leading,
    this.getTrailing,
    this.onTap,
    this.contentPadding,
    this.titleStyle,
    super.key,
  }) : assert(title != null || getTitle != null);

  @override
  State<NormalItem> createState() => _NormalItemState();
}

class _NormalItemState extends State<NormalItem> {
  @override
  Widget build(BuildContext context) {
    late final theme = Theme.of(context);
    Widget? subtitle;
    if ((widget.subtitle ?? widget.getSubtitle?.call()) case final text?) {
      subtitle = Text(
        text,
        style: theme.textTheme.labelMedium!.copyWith(
          color: theme.colorScheme.outline,
        ),
      );
    }
    final child = ListTile(
      contentPadding: widget.contentPadding,
      onTap: widget.onTap == null
          ? null
          : () => widget.onTap!(context, refresh),
      title: Text(
        widget.title ?? widget.getTitle!(),
        style: widget.titleStyle ?? theme.textTheme.titleMedium!,
      ),
      subtitle: subtitle,
      leading: widget.leading,
      trailing: widget.getTrailing?.call(theme),
    );
    if (!WindowsVideoTabService.enabled) return child;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.windowsNeo.surface,
        border: Border(bottom: BorderSide(color: context.windowsNeo.border)),
      ),
      child: child,
    );
  }

  void refresh() {
    if (mounted) {
      setState(() {});
    }
  }
}
