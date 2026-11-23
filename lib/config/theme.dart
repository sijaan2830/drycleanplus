import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';

/// DrycleanPlus design tokens — Blue theme.
///
/// Old constant names (gold, goldBorder, primaryBlueDark ...) are kept so every
/// screen that was not rewritten still compiles and automatically picks up the
/// new look: blue background, soft glass cards, white / ice-blue accents (no yellow).
class AppColors {
  // ── Brand blues ────────────────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1C61E4);
  static const Color primaryBlueLight = Color(0xFF3282F8);
  static const Color primaryBlueDark = Color(0xFF1245B5);
  static const Color primaryBlueDeep = Color(0xFF0A2C7A);
  static const Color backgroundBlue = Color(0xFF1245B5);
  static const Color skyTint = Color(0xFFD6E8FF);

  // ── Accent: pure blue theme — white + ice blue (old "gold" names kept) ────────
  static const Color gold = Color(0xFFFFC107); // accent = white (names kept for old screens)
  static const Color goldLight = Color(0xFFFFD54F); // ice blue
  static const Color goldDark = Color(0xFFFFA000); // soft sky blue
  static const Color sky = Color(0xFF7DDCFF); // bright cyan-blue highlight
  // Was a heavy 2px gold outline. Now a soft glass outline.
  static const Color goldBorder = Color(0xFFFFD54F);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color ink = Color(0xFF0B1F5B); // HTML --ink
  static const Color inkSoft = Color(0xFF1F3274); // HTML --ink-soft
  static const Color muted = Color(0xFF5B6B8C); // secondary text on white cards
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF3F6FC);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF22C55E);

  // ── Gradients ──────────────────────────────────────────────────────────────
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF3282F8), Color(0xFF1C61E4), Color(0xFF1245B5)],
    stops: [0.0, 0.38, 1.0],
  );

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFFF), Color(0xFFD9ECFF)],
  );
}

class AppRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 30;
}

class AppTheme {
  static ThemeData get theme {
    final base = ThemeData(brightness: Brightness.dark, useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.white),
      displayMedium: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white),
      displaySmall: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.white),
      headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.white),
      headlineSmall: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.white),
      titleLarge: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white),
      titleMedium: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.white),
      bodyLarge: GoogleFonts.inter(fontSize: 16, color: AppColors.white),
      bodyMedium: GoogleFonts.inter(fontSize: 14, color: AppColors.white),
      bodySmall: GoogleFonts.inter(fontSize: 12, color: AppColors.white.withOpacity(0.75)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.primaryBlue,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        brightness: Brightness.dark,
        primary: AppColors.primaryBlue,
        secondary: AppColors.gold,
        surface: AppColors.primaryBlueDark,
        error: AppColors.error,
      ),
      textTheme: textTheme,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.inter(
          color: AppColors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.primaryBlueDeep,
          elevation: 0,
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 0.3),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white,
          side: BorderSide(color: AppColors.white.withOpacity(0.45), width: 1.4),
          minimumSize: const Size(64, 54),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.white,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shadowColor: AppColors.primaryBlueDeep.withOpacity(0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
        margin: const EdgeInsets.all(12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white.withOpacity(0.12),
        hintStyle: GoogleFonts.inter(color: AppColors.white.withOpacity(0.5)),
        labelStyle: GoogleFonts.inter(color: AppColors.white.withOpacity(0.85)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.white.withOpacity(0.25)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: AppColors.white.withOpacity(0.25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.white, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.4),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: Color(0xFFFF8A80), width: 1.8),
        ),
        errorStyle: GoogleFonts.inter(color: const Color(0xFFFFB4AB)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryBlueDeep,
        selectedItemColor: AppColors.white,
        unselectedItemColor: Color(0x99FFFFFF),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.primaryBlueDeep,
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.white.withOpacity(0.16),
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: GoogleFonts.inter(color: AppColors.white, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.primaryBlueDeep,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.primaryBlueDeep,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}

/// Card decorations (names kept for old screens).
class AppCardDecoration {
  /// White surface card (use dark `AppColors.ink` text inside).
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlueDeep.withOpacity(0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      );

  /// Glass card on the blue background (white text inside).
  static BoxDecoration get blueCardDecoration => BoxDecoration(
        color: AppColors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.white.withOpacity(0.22), width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlueDeep.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      );

  static BoxDecoration get selectedCardDecoration => BoxDecoration(
        color: AppColors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.gold, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      );
}

/// Price text styles.
class PriceTextStyle {
  static const TextStyle priceLarge =
      TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.white);
  static const TextStyle priceMedium =
      TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.white);
  static const TextStyle priceSmall =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white);
  static const TextStyle priceWithGold =
      TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.gold);
}
