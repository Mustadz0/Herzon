import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../design/colors.dart';
import '../design/typography.dart';
import '../design/shadows.dart';

class AppTheme {
  AppTheme._();

  static const Color primary = SemanticColors.primary;
  static const Color navLight = ComponentColors.navLight;
  static const Color navDark = ComponentColors.navDark;

  static const LinearGradient brandGradient = LinearGradient(
    colors: [SemanticColors.primary, SemanticColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const Curve easeOutStrong = Cubic(0.23, 1, 0.32, 1);
  static const Curve easeInOutStrong = Cubic(0.77, 0, 0.175, 1);
  static const Duration durButtonPress = Duration(milliseconds: 160);
  static const Duration durUi = Duration(milliseconds: 200);
  static const Duration durPage = Duration(milliseconds: 300);

  static List<BoxShadow> softShadow([Color? c]) => [
    BoxShadow(
      color: (c ?? primary).withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: (c ?? primary).withValues(alpha: 0.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> glassShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.03),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  // ━━ Backward-compat aliases (used across the codebase) ━━━━
  static const Color primaryColor = SemanticColors.primary;
  static const Color accent = PrimitiveColors.purple500;
  static const Color success = SemanticColors.success;
  static const Color error = SemanticColors.error;
  static const Color cardDark = ComponentColors.cardDark;
  static const Color outlineVariant = Color(0xFFC2C6D6);
  static const Color secondary = SemanticColors.secondary;
  static const Color primaryDark = PrimitiveColors.blue950;

  static const List<BoxShadow> glassShadowHeavy = [
    BoxShadow(
      color: Colors.black26,
      blurRadius: 32,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Colors.black12,
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  static const LinearGradient accentGradient = LinearGradient(
    colors: [SemanticColors.primary, SemanticColors.secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFFFF6B6B), Color(0xFFFFB347)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardGlassLight = Color(0xFFF2F3FF);
  static const Color cardGlassDark = Color(0xB31E293B);

  static ThemeData get lightTheme {
    const cs = ColorScheme.light(
      primary: SemanticColors.primary,
      onPrimary: SemanticColors.onPrimary,
      primaryContainer: SemanticColors.primaryContainer,
      onPrimaryContainer: Color(0xFFFEFCFF),
      secondary: SemanticColors.secondary,
      onSecondary: SemanticColors.onSecondary,
      secondaryContainer: SemanticColors.secondaryContainer,
      onSecondaryContainer: Color(0xFFFFFBFF),
      tertiary: SemanticColors.tertiary,
      onTertiary: SemanticColors.onTertiary,
      tertiaryContainer: Color(0xFF6063EE),
      onTertiaryContainer: Color(0xFFFFFBFF),
      error: SemanticColors.error,
      onError: SemanticColors.onError,
      errorContainer: Color(0xFFFFDAD6),
      onErrorContainer: Color(0xFF93000A),
      surface: Color(0xFFFAF8FF),
      onSurface: Color(0xFF131B2E),
      onSurfaceVariant: Color(0xFF424754),
      outline: Color(0xFF727785),
      outlineVariant: Color(0xFFC2C6D6),
      inverseSurface: Color(0xFF283044),
      onInverseSurface: Color(0xFFEEF0FF),
      inversePrimary: Color(0xFFADC6FF),
      surfaceTint: Color(0xFF005AC2),
    );
    return _baseTheme(Brightness.light, cs);
  }

  static ThemeData get darkTheme {
    const cs = ColorScheme.dark(
      primary: Color(0xFFADC6FF),
      onPrimary: Color(0xFF001A42),
      primaryContainer: Color(0xFF004395),
      onPrimaryContainer: Color(0xFFFEFCFF),
      secondary: Color(0xFFDDB7FF),
      onSecondary: Color(0xFF2C0051),
      secondaryContainer: Color(0xFF6900B3),
      onSecondaryContainer: Color(0xFFFFFBFF),
      tertiary: Color(0xFFC0C1FF),
      onTertiary: Color(0xFF07006C),
      tertiaryContainer: Color(0xFF2F2EBE),
      onTertiaryContainer: Color(0xFFFFFBFF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFF1A2236),
      onSurface: Color(0xFFEEF0FF),
      onSurfaceVariant: Color(0xFFC2C6D6),
      outline: Color(0xFF727785),
      outlineVariant: Color(0xFF424754),
      inverseSurface: Color(0xFFFAF8FF),
      onInverseSurface: Color(0xFF131B2E),
      inversePrimary: Color(0xFF0058BE),
      surfaceTint: Color(0xFFADC6FF),
    );
    return _baseTheme(Brightness.dark, cs);
  }

  static ThemeData _baseTheme(Brightness brightness, ColorScheme cs) {
    final isDark = brightness == Brightness.dark;
    final navBg = isDark ? navDark : navLight;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: cs,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w800, height: 56/48, letterSpacing: -0.02, color: cs.onSurface),
        displayMedium: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w700, height: 40/32, letterSpacing: -0.01, color: cs.onSurface),
        displaySmall: GoogleFonts.plusJakartaSans(fontSize: 36, fontWeight: FontWeight.w700, height: 44/36, letterSpacing: -0.01, color: cs.onSurface),
        headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w700, height: 36/28, color: cs.onSurface),
        headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w600, height: 32/24, color: cs.onSurface),
        headlineSmall: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w600, height: 28/20, color: cs.onSurface),
        titleLarge: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w500, height: 28/18, color: cs.onSurface),
        titleMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w500, height: 24/16, color: cs.onSurface),
        titleSmall: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, height: 20/14, letterSpacing: 0.01, color: cs.onSurface),
        bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w400, height: 28/18, color: cs.onSurface),
        bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w400, height: 24/16, color: cs.onSurface),
        bodySmall: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w400, height: 20/14, color: isDark ? cs.onSurfaceVariant : cs.onSurface),
        labelLarge: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, height: 20/14, letterSpacing: 0.01, color: isDark ? cs.onSurfaceVariant : cs.onSurface),
        labelMedium: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, height: 16/12, letterSpacing: 0.05, color: isDark ? cs.onSurfaceVariant : cs.onSurface),
        labelSmall: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w500, height: 16/11, letterSpacing: 0.05, color: isDark ? cs.onSurfaceVariant : cs.onSurface),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? cardGlassDark : cardGlassLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shadowColor: isDark ? Colors.black.withValues(alpha: 0.2) : primary.withValues(alpha: 0.08),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBg,
        selectedItemColor: cs.primary,
        unselectedItemColor: isDark ? cs.onSurfaceVariant : cs.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
        ).copyWith(elevation: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.pressed) ? 4.0 : 0.0)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          side: BorderSide(color: cs.onSurface, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ).copyWith(elevation: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.pressed) ? 2.0 : 0.0)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
        ).copyWith(elevation: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.pressed) ? 2.0 : 0.0)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cs.primary, width: 2)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: cs.error)),
        hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurfaceVariant),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: cs.onSurfaceVariant),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(space: 0, thickness: 0.5, color: cs.outlineVariant),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: cs.primary.withValues(alpha: 0.12),
      ),
    );
  }
}

extension ThemeContextX on BuildContext {
  ThemeData   get theme  => Theme.of(this);
  ColorScheme get cs     => theme.colorScheme;
  TextTheme   get tt     => theme.textTheme;
  bool        get isDark => theme.brightness == Brightness.dark;
}

extension ThemeDataX on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}
