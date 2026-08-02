import 'package:flutter/material.dart';

/// Centralized responsiveness utility for the DrycleanPlus app.
/// Use these helpers instead of hardcoding pixel values to ensure
/// the UI adapts correctly to all phone screen sizes.
class R {
  /// Safe bottom padding (accounts for home indicator on notched phones)
  static double safeBottom(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  /// Safe top padding (accounts for status bar / notch)
  static double safeTop(BuildContext context) =>
      MediaQuery.paddingOf(context).top;

  /// Full screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  /// Full screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Dynamic footer height — fixed bar + home indicator padding
  static double footerHeight(BuildContext context) =>
      kBottomNavigationBarHeight + safeBottom(context);

  /// True if device is a small phone (screen height < 700dp)
  static bool isSmallScreen(BuildContext context) =>
      screenHeight(context) < 700;

  /// True if device is a compact phone (screen height < 750dp)
  static bool isCompactScreen(BuildContext context) =>
      screenHeight(context) < 750;

  /// Responsive fraction of screen height. E.g. hf(context, 0.35) = 35% of screen.
  static double hf(BuildContext context, double fraction) =>
      screenHeight(context) * fraction;

  /// Responsive fraction of screen width. E.g. wf(context, 0.5) = 50% of screen.
  static double wf(BuildContext context, double fraction) =>
      screenWidth(context) * fraction;

  /// Responsive value: small screen value vs default value
  static double adaptive(
    BuildContext context, {
    required double small,
    required double normal,
    double? large,
  }) {
    if (isSmallScreen(context)) return small;
    if (large != null && screenHeight(context) > 900) return large;
    return normal;
  }
}
