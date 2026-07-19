import 'package:PiliPlus/windows_ui/foundation/windows_neo_theme.dart';
import 'package:flutter/material.dart';

class WindowsNeoSearchHorizontalSkeleton extends StatelessWidget {
  const WindowsNeoSearchHorizontalSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return _SkeletonSurface(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceSm + 2),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final coverWidth = (constraints.maxWidth * 0.38)
                .clamp(96.0, 168.0)
                .toDouble();
            return Row(
              children: [
                SizedBox(
                  width: coverWidth,
                  height: double.infinity,
                  child: ColoredBox(color: tokens.hover),
                ),
                SizedBox(width: tokens.spaceMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(height: 12, color: tokens.hover),
                      SizedBox(height: tokens.spaceSm - 1),
                      FractionallySizedBox(
                        widthFactor: 0.76,
                        child: Container(height: 12, color: tokens.hover),
                      ),
                      const Spacer(),
                      FractionallySizedBox(
                        widthFactor: 0.48,
                        child: Container(height: 10, color: tokens.hover),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class WindowsNeoSearchLiveSkeleton extends StatelessWidget {
  const WindowsNeoSearchLiveSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return _SkeletonSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: ColoredBox(color: tokens.hover)),
          SizedBox(
            height: MediaQuery.textScalerOf(context).scale(80),
            child: Padding(
              padding: EdgeInsets.all(tokens.spaceSm + 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 12, color: tokens.hover),
                  SizedBox(height: tokens.spaceSm - 1),
                  FractionallySizedBox(
                    widthFactor: 0.72,
                    child: Container(height: 12, color: tokens.hover),
                  ),
                  const Spacer(),
                  FractionallySizedBox(
                    widthFactor: 0.42,
                    child: Container(height: 10, color: tokens.hover),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WindowsNeoSearchCompactSkeleton extends StatelessWidget {
  const WindowsNeoSearchCompactSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return _SkeletonSurface(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: tokens.spaceMd),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tokens.hover,
              ),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.56,
                    child: Container(height: 12, color: tokens.hover),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  FractionallySizedBox(
                    widthFactor: 0.78,
                    child: Container(height: 10, color: tokens.hover),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WindowsNeoSearchPgcSkeleton extends StatelessWidget {
  const WindowsNeoSearchPgcSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return _SkeletonSurface(
      child: Padding(
        padding: EdgeInsets.all(tokens.spaceSm + 1),
        child: Row(
          children: [
            SizedBox(
              width: 108,
              height: double.infinity,
              child: ColoredBox(color: tokens.hover),
            ),
            SizedBox(width: tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 13, color: tokens.hover),
                  SizedBox(height: tokens.spaceSm),
                  FractionallySizedBox(
                    widthFactor: 0.74,
                    child: Container(height: 13, color: tokens.hover),
                  ),
                  const Spacer(),
                  FractionallySizedBox(
                    widthFactor: 0.52,
                    child: Container(height: 10, color: tokens.hover),
                  ),
                  SizedBox(height: tokens.spaceSm),
                  FractionallySizedBox(
                    widthFactor: 0.64,
                    child: Container(height: 10, color: tokens.hover),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonSurface extends StatelessWidget {
  const _SkeletonSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.windowsNeo;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: tokens.cardRadius,
        border: Border.all(color: tokens.border.withValues(alpha: 0.42)),
        boxShadow: tokens.cardShadow,
      ),
      child: ClipRRect(borderRadius: tokens.cardRadius, child: child),
    );
  }
}
