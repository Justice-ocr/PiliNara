import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class WindowsNeoContextStack extends StatelessWidget {
  const WindowsNeoContextStack({
    super.key,
    required this.base,
    this.contexts = const [],
  });

  final Widget base;
  final List<Widget> contexts;

  @override
  Widget build(BuildContext context) => IndexedStack(
    index: contexts.length,
    children: [base, ...contexts],
  );
}

class WindowsNeoContextPanel extends StatelessWidget {
  const WindowsNeoContextPanel({
    super.key,
    required this.title,
    required this.onBack,
    required this.child,
    this.actions = const [],
    this.backTooltip = '返回相关内容',
  });

  final String title;
  final VoidCallback onBack;
  final Widget child;
  final List<Widget> actions;
  final String backTooltip;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: Row(
            children: [
              IconButton(
                tooltip: backTooltip,
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 19),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ...actions,
              const SizedBox(width: 4),
            ],
          ),
        ),
        Divider(height: 1, color: tokens.border),
        Expanded(child: child),
      ],
    );
  }
}
