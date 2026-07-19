import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:PiliPlus/windows_ui/motion/windows_neo_motion.dart';
import 'package:flutter/material.dart';

class WindowsNeoSliverState extends StatelessWidget {
  const WindowsNeoSliverState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = '\u91cd\u8bd5',
    this.retrying = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final bool retrying;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    final textTheme = Theme.of(context).textTheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            tokens.pagePadding,
            tokens.spaceXl,
            tokens.pagePadding,
            72,
          ),
          child: WindowsNeoStaggeredReveal(
            order: 0,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Text(
                        '39',
                        style: textTheme.displayLarge?.copyWith(
                          color: tokens.accent.withValues(alpha: 0.07),
                          fontSize: 92,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      Icon(icon, size: 38, color: tokens.accent),
                    ],
                  ),
                  SizedBox(height: tokens.spaceMd),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(
                      color: tokens.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (message?.isNotEmpty == true) ...[
                    SizedBox(height: tokens.spaceSm),
                    Text(
                      message!,
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: tokens.muted,
                        height: 1.45,
                      ),
                    ),
                  ],
                  if (onRetry != null || retrying) ...[
                    SizedBox(height: tokens.spaceLg),
                    OutlinedButton.icon(
                      onPressed: retrying ? null : onRetry,
                      icon: retrying
                          ? const SizedBox.square(
                              dimension: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: Text(retryLabel),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
