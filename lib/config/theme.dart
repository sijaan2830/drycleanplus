import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// App Theme Colors - Blue and Gold theme for DrycleanPlus
class AppColors {
  // Primary Blue Colors - Brighter Dodger Blue
  static const Color primaryBlue = Color(0xFF1E90FF);
  static const Color primaryBlueLight = Color(0xFF63A4FF);
  static const Color primaryBlueDark = Color(0xFF0064C7); // Darker shade of Dodger Blue
  static const Color backgroundBlue = Color(0xFFE3F2FD); // Lightest shade for backgrounds
  
  // Gold Colors - Premium Metallic Gold
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFF1D592);
  static const Color goldDark = Color(0xFFB8962E);
  static const Color goldBorder = Color(0xFFFFD700); // Brighter gold for borders
  
  // Other Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey = Color(0xFF9E9E9E);
  static const Color lightGrey = Color(0xFFF5F5F5);
  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
}

/// App Theme Data
class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.primaryBlue, // Primary background is blue as requested
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryBlue,
        primary: AppColors.primaryBlue,
        secondary: AppColors.gold,
        surface: AppColors.white,
        error: AppColors.error,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold, // Buttons are gold for contrast on blue
          foregroundColor: AppColors.primaryBlue, // Dark blue text on gold button
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.white, width: 1.5),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.white, // White text for outlines on blue
          side: const BorderSide(color: AppColors.gold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.goldLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 4,
        shadowColor: AppColors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.goldBorder, width: 2),
        ),
        margin: const EdgeInsets.all(12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.white, width: 2.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.primaryBlueDark,
        selectedItemColor: AppColors.gold,
        unselectedItemColor: AppColors.white,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.primaryBlueDark,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.goldBorder,
        thickness: 1.5,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppColors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppColors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppColors.white,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          color: AppColors.goldLight,
        ),
      ),
      useMaterial3: true,
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

/// Card decoration with gold border
class AppCardDecoration {
  static BoxDecoration get cardDecoration => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldBorder, width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      );
  
  static BoxDecoration get blueCardDecoration => BoxDecoration(
        color: AppColors.primaryBlueDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.goldBorder, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      );

  static BoxDecoration get selectedCardDecoration => BoxDecoration(
        color: AppColors.primaryBlueLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      );
}

/// Price text style - ensures prices are visible
class PriceTextStyle {
  static const TextStyle priceLarge = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w800,
    color: AppColors.gold,
  );
  
  static const TextStyle priceMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.gold,
  );
  
  static const TextStyle priceSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.gold,
  );
  
  static const TextStyle priceWithGold = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.goldLight,
  );
}
