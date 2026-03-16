import 'package:flutter/material.dart';

double responsiveChartHeight(BuildContext context,
    {ChartType type = ChartType.line}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final isTablet = MediaQuery.of(context).size.shortestSide >= 600;

  final basePercentage = type == ChartType.bar ? 0.30 : 0.26;
  final minHeight = isTablet ? 220.0 : (type == ChartType.bar ? 200.0 : 180.0);
  final maxHeight = isTablet ? 320.0 : (type == ChartType.bar ? 280.0 : 240.0);

  final calculatedHeight = screenHeight * basePercentage;
  return calculatedHeight.clamp(minHeight, maxHeight);
}

enum ChartType { line, bar }
