import 'dart:ui';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ChartAnimations {
  const ChartAnimations._();

  static const entranceDuration = Duration(milliseconds: 600);
  static const entranceCurve = Curves.easeOutCubic;
  static const barTouchResetDelay = Duration(milliseconds: 180);
  static const touchDebounce = Duration(milliseconds: 150);

  static Duration entranceDurationFor(int pointCount) =>
      pointCount < 2 ? Duration.zero : entranceDuration;
}

class GlowDotPainter extends FlDotPainter {
  const GlowDotPainter({
    required this.color,
    required this.radius,
    required this.glowColor,
    this.glowRadius = 10,
    this.strokeColor = Colors.white,
    this.strokeWidth = 2,
  });

  final Color color;
  final double radius;
  final Color glowColor;
  final double glowRadius;
  final Color strokeColor;
  final double strokeWidth;

  @override
  void draw(Canvas canvas, FlSpot spot, Offset offsetInCanvas) {
    canvas.drawCircle(
      offsetInCanvas,
      glowRadius,
      Paint()
        ..color = glowColor
        ..style = PaintingStyle.fill,
    );

    if (strokeWidth > 0 && strokeColor.a != 0) {
      canvas.drawCircle(
        offsetInCanvas,
        radius + (strokeWidth / 2),
        Paint()
          ..color = strokeColor
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke,
      );
    }

    canvas.drawCircle(
      offsetInCanvas,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  @override
  Size getSize(FlSpot spot) => Size.fromRadius(glowRadius + strokeWidth);

  @override
  Color get mainColor => color;

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) {
    if (a is! GlowDotPainter || b is! GlowDotPainter) {
      return b;
    }

    return GlowDotPainter(
      color: Color.lerp(a.color, b.color, t) ?? b.color,
      radius: lerpDouble(a.radius, b.radius, t) ?? b.radius,
      glowColor: Color.lerp(a.glowColor, b.glowColor, t) ?? b.glowColor,
      glowRadius: lerpDouble(a.glowRadius, b.glowRadius, t) ?? b.glowRadius,
      strokeColor: Color.lerp(a.strokeColor, b.strokeColor, t) ?? b.strokeColor,
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t) ?? b.strokeWidth,
    );
  }

  @override
  bool hitTest(
    FlSpot spot,
    Offset touched,
    Offset center,
    double extraThreshold,
  ) {
    final distance = (touched - center).distance.abs();
    return distance < glowRadius + extraThreshold;
  }

  @override
  List<Object?> get props => [
        color,
        radius,
        glowColor,
        glowRadius,
        strokeColor,
        strokeWidth,
      ];
}

bool animationsEnabled(BuildContext context, {required int pointCount}) {
  final mediaQuery = MediaQuery.maybeOf(context);
  final disableAnimations = mediaQuery?.disableAnimations ?? false;
  return !disableAnimations && pointCount > 1;
}
