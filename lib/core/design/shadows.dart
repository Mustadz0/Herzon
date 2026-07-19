/// Design System — Shadow / Elevation Tokens
library;

import 'package:flutter/material.dart';

class AppShadows {
  AppShadows._();

  static const BoxShadow sm = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 4,
    offset: Offset(0, 1),
  );

  static const BoxShadow md = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );

  static BoxShadow glow(Color color) => BoxShadow(
    color: color.withValues(alpha: 0.15),
    blurRadius: 12,
    spreadRadius: 1,
  );
}
