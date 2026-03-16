import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:inflabasket/core/theme/chart_animations.dart';

mixin ChartTouchState<T extends StatefulWidget> on State<T> {
  int? touchedBarIndex;
  Timer? _touchResetTimer;
  DateTime? _lastTouchTime;

  bool shouldHandleTouch() {
    final now = DateTime.now();
    if (_lastTouchTime != null &&
        now.difference(_lastTouchTime!) < ChartAnimations.touchDebounce) {
      return false;
    }

    _lastTouchTime = now;
    return true;
  }

  bool handleTouchDebounce() => shouldHandleTouch();

  bool handleBarTouch(int index, VoidCallback onUpdate) {
    if (!shouldHandleTouch()) return false;

    touchedBarIndex = index;
    onUpdate();

    _touchResetTimer?.cancel();
    _touchResetTimer = Timer(ChartAnimations.barTouchResetDelay, () {
      if (!mounted) return;
      touchedBarIndex = null;
      onUpdate();
    });

    return true;
  }

  @override
  void dispose() {
    _touchResetTimer?.cancel();
    super.dispose();
  }
}
