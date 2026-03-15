import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerContainer extends StatelessWidget {
  const ShimmerContainer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.child,
  });

  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    return ExcludeSemantics(
      child: Shimmer.fromColors(
        baseColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
        highlightColor:
            isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF5F5F5),
        period: const Duration(milliseconds: 1500),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: shape,
            borderRadius: shape == BoxShape.circle
                ? null
                : borderRadius ?? BorderRadius.circular(12),
          ),
          child: child,
        ),
      ),
    );
  }
}
