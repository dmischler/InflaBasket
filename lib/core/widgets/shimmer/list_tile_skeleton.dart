import 'package:flutter/material.dart';
import 'package:inflabasket/core/widgets/shimmer/shimmer_container.dart';

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({
    super.key,
    this.showLeading = true,
    this.showSubtitle = true,
    this.showTrailing = true,
    this.padding = const EdgeInsets.symmetric(vertical: 8),
  });

  final bool showLeading;
  final bool showSubtitle;
  final bool showTrailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (showLeading) ...[
            const ShimmerContainer(
              width: 40,
              height: 40,
              shape: BoxShape.circle,
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ShimmerContainer(height: 16),
                if (showSubtitle) ...[
                  const SizedBox(height: 8),
                  const ShimmerContainer(width: 180, height: 12),
                ],
              ],
            ),
          ),
          if (showTrailing) ...[
            const SizedBox(width: 12),
            const ShimmerContainer(width: 64, height: 18),
          ],
        ],
      ),
    );
  }
}
