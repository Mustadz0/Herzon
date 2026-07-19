/// Design System — Color Tokens
/// Primitive → Semantic → Component layers
library;

import 'package:flutter/material.dart';

// ━━━ Primitive Palette ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class PrimitiveColors {
  PrimitiveColors._();

  static const Color blue600 = Color(0xFF0058BE);
  static const Color blue500 = Color(0xFF2170E4);
  static const Color blue300 = Color(0xFFADC6FF);
  static const Color blue200 = Color(0xFFD8E2FF);
  static const Color blue900 = Color(0xFF004395);
  static const Color blue950 = Color(0xFF001A42);

  static const Color purple600 = Color(0xFF8127CF);
  static const Color purple500 = Color(0xFF9C48EA);
  static const Color purple300 = Color(0xFFDDB7FF);
  static const Color purple200 = Color(0xFFF0DBFF);
  static const Color purple900 = Color(0xFF6900B3);
  static const Color purple950 = Color(0xFF2C0051);

  static const Color indigo500 = Color(0xFF4648D4);
  static const Color indigo400 = Color(0xFF6063EE);
  static const Color indigo300 = Color(0xFFC0C1FF);
  static const Color indigo200 = Color(0xFFE1E0FF);
  static const Color indigo900 = Color(0xFF2F2EBE);
  static const Color indigo950 = Color(0xFF07006C);

  static const Color neutralWhite = Color(0xFFFFFFFF);
  static const Color neutralGray100 = Color(0xFFDAE2FD);
  static const Color neutralGray200 = Color(0xFFE2E7FF);
  static const Color neutralGray300 = Color(0xFFEAEDFF);
  static const Color neutralGray400 = Color(0xFFF2F3FF);
  static const Color neutralGray500 = Color(0xFFFAF8FF);
  static const Color neutralGray700 = Color(0xFF424754);
  static const Color neutralGray800 = Color(0xFF283044);
  static const Color neutralGray850 = Color(0xFF1A2236);
  static const Color neutralGray900 = Color(0xFF131B2E);

  static const Color red600 = Color(0xFFBA1A1A);
  static const Color red200 = Color(0xFFFFDAD6);
  static const Color red900 = Color(0xFF93000A);

  static const Color green500 = Color(0xFF10B981);
}

// ━━━ Semantic Colors ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
class SemanticColors {
  SemanticColors._();

  static const Color primary = PrimitiveColors.blue600;
  static const Color onPrimary = PrimitiveColors.neutralWhite;
  static const Color primaryContainer = PrimitiveColors.blue500;
  static const Color inversePrimary = PrimitiveColors.blue300;

  static const Color secondary = PrimitiveColors.purple600;
  static const Color onSecondary = PrimitiveColors.neutralWhite;
  static const Color secondaryContainer = PrimitiveColors.purple500;

  static const Color tertiary = PrimitiveColors.indigo500;
  static const Color onTertiary = PrimitiveColors.neutralWhite;

  static const Color error = PrimitiveColors.red600;
  static const Color onError = PrimitiveColors.neutralWhite;

  static const Color success = PrimitiveColors.green500;

  static Color surfaceLight = PrimitiveColors.neutralGray500;
  static Color onSurfaceLight = PrimitiveColors.neutralGray900;
  static Color surfaceDark = PrimitiveColors.neutralGray850;
  static Color onSurfaceDark = PrimitiveColors.neutralGray500;
}

// ━━━ Component Colors (applied in theme) ━━━━━━━━━━━━━━━━━━━━━
class ComponentColors {
  ComponentColors._();

  static const Color navLight = Color(0xFFFAF8FF);
  static const Color navDark = Color(0xFF1A1A2E);
  static const Color cardDark = Color(0xFF1A1A1A);
  static const Color popupDark = Color(0xFF2A2A2A);
}
