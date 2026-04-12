import 'dart:math' as math;

import 'package:flutter/widgets.dart';

abstract final class Responsive {
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >= 600;
  }

  static double horizontalPadding(BuildContext context) {
    return isTablet(context) ? 28 : 20;
  }

  static double contentWidth(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    return math.min(width, isTablet(context) ? 860 : 700);
  }
}
