import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ━━━ Brand Palette (Kinetic Proximity) ━━━

  // Primary
  static const Color primary                  = Color(0xFF0058BE);
  // FIX A: removed duplicate `primaryColor` alias (conflicts with deprecated
  //        Flutter ThemeData.primaryColor property name — causes confusion).
  static const Color onPrimary                = Colors.white;
  static const Color primaryContainer         = Color(0xFF2170E4);
  static const Color onPrimaryContainer       = Color(0xFFFEFCFF);
  static const Color inversePrimary           = Color(0xFFADC6FF);
  static const Color primaryFixed             = Color(0xFFD8E2FF);
  static const Color primaryFixedDim          = Color(0xFFADC6FF);
  static const Color onPrimaryFixed           = Color(0xFF001A42);
  static const Color onPrimaryFixedVariant    = Color(0xFF004395);
  static const Color primaryLight             = inversePrimary;
  static const Color primaryDark              = onPrimaryFixedVariant;

  // Secondary
  static const Color secondary                = Color(0xFF8127CF);
  static const Color accent                   = secondary;
  static const Color onSecondary              = Colors.white;
  static const Color secondaryContainer       = Color(0xFF9C48EA);
  static const Color onSecondaryContainer     = Color(0xFFFFFBFF);
  static const Color secondaryFixed           = Color(0xFFF0DBFF);
  static const Color secondaryFixedDim        = Color(0xFFDDB7FF);
  static const Color onSecondaryFixed         = Color(0xFF2C0051);
  static const Color onSecondaryFixedVariant  = Color(0xFF6900B3);
  static const Color accentLight              = secondaryFixedDim;
  static const Color secondaryColor           = secondary;

  // Tertiary
  static const Color tertiary                 = Color(0xFF4648D4);
  static const Color onTertiary               = Colors.white;
  static const Color tertiaryContainer        = Color(0xFF6063EE);
  static const Color onTertiaryContainer      = Color(0xFFFFFBFF);
  static const Color tertiaryFixed            = Color(0xFFE1E0FF);
  static const Color tertiaryFixedDim         = Color(0xFFC0C1FF);
  static const Color onTertiaryFixed          = Color(0xFF07006C);
  static const Color onTertiaryFixedVariant   = Color(0xFF2F2EBE);

  // Error
  static const Color error                    = Color(0xFFBA1A1A);
  static const Color errorColor               = error;
  static const Color onError                  = Colors.white;
  static const Color errorContainer           = Color(0xFFFFDAD6);
  static const Color onErrorContainer         = Color(0xFF93000A);

  // Success
  static const Color success                  = Color(0xFF10B981);

  // ━━━ Surface System ━━━
  static const Color surface                      = Color(0xFFFAF8FF);
  static const Color surfaceDim                   = Color(0xFFD2D9F4);
  static const Color surfaceBright                = Color(0xFFFAF8FF);
  static const Color surfaceContainerLowest       = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow          = Color(0xFFF2F3FF);
  static const Color surfaceContainer             = Color(0xFFEAEDFF);
  static const Color surfaceContainerHigh         = Color(0xFFE2E7FF);
  static const Color surfaceContainerHighest      = Color(0xFFDAE2FD);
  static const Color onSurface                    = Color(0xFF131B2E);
  static const Color onSurfaceVariant             = Color(0xFF424754);
  static const Color surfaceVariant               = Color(0xFFDAE2FD);
  // FIX E: dark surface uses a dedicated token (not inverseSurface which is too dark
  //        at 0xFF283044 — that is for inverseSurface/onInverseSurface roles only).
  static const Color surfaceDark                  = Color(0xFF1A2236);
  static const Color inverseSurface               = Color(0xFF283044);
  static const Color inverseOnSurface             = Color(0xFFEEF0FF);
  static const Color surfaceTint                  = Color(0xFF005AC2);

  // Outline
  static const Color outline                  = Color(0xFF727785);
  static const Color outlineVariant           = Color(0xFFC2C6D6);

  // Background (aliases)
  static const Color background               = surface;
  static const Color onBackground             = onSurface;

  // Legacy aliases
  static const Color surfaceLight             = surface;
  static const Color cardLight                = surfaceContainerLowest;
  static const Color cardDark                 = Color(0xFF1E293B);
  static const Color cardGlassLight           = surfaceContainerLow;
  static const Color cardGlassDark            = Color(0xB31E293B);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryContainer, secondaryContainer],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient warmGradient = LinearGradient(
    colors: [secondary, tertiary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glass
  static const Color glassBorderLight = Color(0x4DFFFFFF);
  static const Color glassBorderDark  = Color(0x33FFFFFF);
  static const Color navLight         = Color(0xF0FAF8FF);
  // FIX D: slightly lighter navDark so inversePrimary (0xFFADC6FF) has ≥4.5:1 contrast
  static const Color navDark          = Color(0xF0202C40);

  // Shadows
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

  static List<BoxShadow> glassShadowHeavy = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 40,
      offset: const Offset(0, -10),
    ),
    BoxShadow(
      color: primary.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];

  // ━━━ Typography (Kinetic Proximity — Plus Jakarta Sans) ━━━

  static TextStyle get _displayLarge => GoogleFonts.plusJakartaSans(
    fontSize: 48, fontWeight: FontWeight.w800,
    height: 56 / 48, letterSpacing: -0.02,
  );
  static TextStyle get _displaySmall => GoogleFonts.plusJakartaSans(
    fontSize: 36, fontWeight: FontWeight.w700,
    height: 44 / 36, letterSpacing: -0.01,
  );
  static TextStyle get _displayMedium => GoogleFonts.plusJakartaSans(
    fontSize: 32, fontWeight: FontWeight.w700,
    height: 40 / 32, letterSpacing: -0.01,
  );
  static TextStyle get _headlineLarge => GoogleFonts.plusJakartaSans(
    fontSize: 28, fontWeight: FontWeight.w700,
    height: 36 / 28,
  );
  static TextStyle get _headlineMedium => GoogleFonts.plusJakartaSans(
    fontSize: 24, fontWeight: FontWeight.w600,
    height: 32 / 24,
  );
  static TextStyle get _headlineSmall => GoogleFonts.plusJakartaSans(
    fontSize: 20, fontWeight: FontWeight.w600,
    height: 28 / 20,
  );
  static TextStyle get _titleLarge => GoogleFonts.plusJakartaSans(
    fontSize: 18, fontWeight: FontWeight.w500,
    height: 28 / 18,
  );
  static TextStyle get _titleMedium => GoogleFonts.plusJakartaSans(
    fontSize: 16, fontWeight: FontWeight.w500,
    height: 24 / 16,
  );
  static TextStyle get _titleSmall => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w600,
    height: 20 / 14, letterSpacing: 0.01,
  );
  static TextStyle get _bodyLarge => GoogleFonts.plusJakartaSans(
    fontSize: 18, fontWeight: FontWeight.w400,
    height: 28 / 18,
  );
  static TextStyle get _bodyMedium => GoogleFonts.plusJakartaSans(
    fontSize: 16, fontWeight: FontWeight.w400,
    height: 24 / 16,
  );
  static TextStyle get _bodySmall => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w400,
    height: 20 / 14,
  );
  static TextStyle get _labelLarge => GoogleFonts.plusJakartaSans(
    fontSize: 14, fontWeight: FontWeight.w600,
    height: 20 / 14, letterSpacing: 0.01,
  );
  static TextStyle get _labelMedium => GoogleFonts.plusJakartaSans(
    fontSize: 12, fontWeight: FontWeight.w500,
    height: 16 / 12, letterSpacing: 0.05,
  );
  static TextStyle get _labelSmall => GoogleFonts.plusJakartaSans(
    fontSize: 11, fontWeight: FontWeight.w500,
    height: 16 / 11, letterSpacing: 0.05,
  );

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // LIGHT THEME
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static ThemeData get lightTheme {
    const cs = ColorScheme.light(
      primary:               primary,
      onPrimary:             onPrimary,
      primaryContainer:      primaryContainer,
      onPrimaryContainer:    onPrimaryContainer,
      secondary:             secondary,
      onSecondary:           onSecondary,
      secondaryContainer:    secondaryContainer,
      onSecondaryContainer:  onSecondaryContainer,
      tertiary:              tertiary,
      onTertiary:            onTertiary,
      tertiaryContainer:     tertiaryContainer,
      onTertiaryContainer:   onTertiaryContainer,
      error:                 error,
      onError:               onError,
      errorContainer:        errorContainer,
      onErrorContainer:      onErrorContainer,
      surface:               surface,
      onSurface:             onSurface,
      onSurfaceVariant:      onSurfaceVariant,
      outline:               outline,
      outlineVariant:        outlineVariant,
      shadow:                Color(0xFF001A42),
      scrim:                 Color(0xFF001A42),
      inverseSurface:        inverseSurface,
      onInverseSurface:      inverseOnSurface,
      inversePrimary:        inversePrimary,
      surfaceTint:           surfaceTint,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: cs,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge:   _displayLarge,
        displayMedium:  _displayMedium,
        displaySmall:   _displaySmall,
        headlineLarge:  _headlineLarge,
        headlineMedium: _headlineMedium,
        headlineSmall:  _headlineSmall,
        titleLarge:     _titleLarge,
        titleMedium:    _titleMedium,
        titleSmall:     _titleSmall,
        bodyLarge:      _bodyLarge,
        bodyMedium:     _bodyMedium,
        bodySmall:      _bodySmall,
        labelLarge:     _labelLarge,
        labelMedium:    _labelMedium,
        labelSmall:     _labelSmall,
      ),
      // FIX C: use CardTheme (not CardThemeData — that is the internal data class)
      cardTheme: CardTheme(
        elevation: 0,
        color: cardGlassLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shadowColor: primary.withValues(alpha: 0.08),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: cs.onSurface,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navLight,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shadowColor: primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          side: const BorderSide(color: secondary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        // FIX B: use cs.surfaceContainerLow (resolved from ColorScheme) instead of
        //        raw static constant to stay in sync with the actual scheme.
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: error),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: outline,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: onSurfaceVariant,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      // FIX F: use DialogTheme (not DialogThemeData)
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.15),
      ),
      // FIX G: added backgroundColor so chips are visible on any surface
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      dividerTheme: const DividerThemeData(
        space: 0, thickness: 0.5, color: outlineVariant,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: primary,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w500, color: outline,
          );
        }),
      ),
    );
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // DARK THEME
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  static ThemeData get darkTheme {
    const cs = ColorScheme.dark(
      primary:               inversePrimary,
      onPrimary:             onPrimaryFixed,
      primaryContainer:      onPrimaryFixedVariant,
      onPrimaryContainer:    onPrimaryContainer,
      secondary:             secondaryFixedDim,
      onSecondary:           onSecondaryFixed,
      secondaryContainer:    onSecondaryFixedVariant,
      onSecondaryContainer:  onSecondaryContainer,
      tertiary:              tertiaryFixedDim,
      onTertiary:            onTertiaryFixed,
      tertiaryContainer:     onTertiaryFixedVariant,
      onTertiaryContainer:   onTertiaryContainer,
      error:                 Color(0xFFFFB4AB),
      onError:               Color(0xFF690005),
      errorContainer:        onErrorContainer,
      onErrorContainer:      Color(0xFFFFDAD6),
      // FIX E: use surfaceDark (0xFF1A2236) instead of inverseSurface (0xFF283044)
      //        inverseSurface is for inverse widgets (SnackBar, Tooltip), not the
      //        main dark background.
      surface:               surfaceDark,
      onSurface:             inverseOnSurface,
      onSurfaceVariant:      outlineVariant,
      outline:               outline,
      outlineVariant:        onSurfaceVariant,
      shadow:                Color(0xFF000000),
      scrim:                 Color(0xFF000000),
      inverseSurface:        surface,
      onInverseSurface:      onSurface,
      inversePrimary:        primary,
      surfaceTint:           inversePrimary,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: cs,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).copyWith(
        displayLarge:   _displayLarge.copyWith(color: cs.onSurface),
        displayMedium:  _displayMedium.copyWith(color: cs.onSurface),
        displaySmall:   _displaySmall.copyWith(color: cs.onSurface),
        headlineLarge:  _headlineLarge.copyWith(color: cs.onSurface),
        headlineMedium: _headlineMedium.copyWith(color: cs.onSurface),
        headlineSmall:  _headlineSmall.copyWith(color: cs.onSurface),
        titleLarge:     _titleLarge.copyWith(color: cs.onSurface),
        titleMedium:    _titleMedium.copyWith(color: cs.onSurface),
        titleSmall:     _titleSmall.copyWith(color: cs.onSurface),
        bodyLarge:      _bodyLarge.copyWith(color: cs.onSurface),
        bodyMedium:     _bodyMedium.copyWith(color: cs.onSurface),
        bodySmall:      _bodySmall.copyWith(color: cs.onSurfaceVariant),
        labelLarge:     _labelLarge.copyWith(color: cs.onSurfaceVariant),
        labelMedium:    _labelMedium.copyWith(color: cs.onSurfaceVariant),
        labelSmall:     _labelSmall.copyWith(color: cs.onSurfaceVariant),
      ),
      // FIX C: CardTheme (not CardThemeData)
      cardTheme: CardTheme(
        elevation: 0,
        color: cardGlassDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shadowColor: Colors.black.withValues(alpha: 0.2),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 20, fontWeight: FontWeight.w600, color: cs.onSurface,
        ),
      ),
      // FIX D: navDark lightened → inversePrimary (light blue) is now readable
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navDark,
        selectedItemColor: cs.primary,
        unselectedItemColor: cs.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 11, fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: cs.primary,
          foregroundColor: cs.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(100),
          ),
          side: BorderSide(color: cs.primary, width: 1.5),
          foregroundColor: cs.primary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: cs.error),
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: cs.onSurfaceVariant,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14, color: cs.onSurfaceVariant,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      // FIX F: DialogTheme (not DialogThemeData)
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.4),
      ),
      // FIX G: backgroundColor for chips in dark mode
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13, fontWeight: FontWeight.w500,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      ),
      dividerTheme: DividerThemeData(
        space: 0, thickness: 0.5, color: cs.outlineVariant,
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.transparent,
        indicatorColor: inversePrimary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 11, fontWeight: FontWeight.w600, color: inversePrimary,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 11, fontWeight: FontWeight.w500, color: outline,
          );
        }),
      ),
    );
  }
}

// ━━━ BuildContext / ThemeData extensions ━━━
// FIX H: unified + non-duplicate isDark on both types
extension ThemeContextX on BuildContext {
  ThemeData    get theme  => Theme.of(this);
  ColorScheme  get cs     => theme.colorScheme;
  TextTheme    get tt     => theme.textTheme;
  bool         get isDark => theme.brightness == Brightness.dark;
}

extension ThemeDataX on ThemeData {
  bool get isDark => brightness == Brightness.dark;
}
