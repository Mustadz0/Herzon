/// Design System — Typography Tokens
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme get textTheme => GoogleFonts.interTextTheme();

  static TextStyle headlineLarge = GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800);
  static TextStyle headlineMedium = GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700);
  static TextStyle titleLarge = GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700);
  static TextStyle titleMedium = GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600);
  static TextStyle titleSmall = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600);
  static TextStyle bodyLarge = GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400);
  static TextStyle bodyMedium = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500);
  static TextStyle bodySmall = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400);
  static TextStyle labelLarge = GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700);
  static TextStyle labelMedium = GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600);
  static TextStyle labelSmall = GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500);
}
