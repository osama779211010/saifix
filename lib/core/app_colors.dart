import 'package:flutter/material.dart';
import '../services/theme_service.dart';

class AppColors {
  // Brand Colors (Dynamic based on user selection)
  static const Color primaryBlue = Color(0xFF1F2D5D); // CMYK 100,90,32,15
  static Color get secondaryBlue => themeService.accentColor;
  static Color get accentBlue => themeService.accentColor;
  static Color get glowBlue => themeService.accentColor.withValues(alpha: 0.8);
  // Adaptive Color Helpers
  static Color adaptiveText(bool isDarkMode, {Color? lightColor}) =>
      isDarkMode ? Colors.white : (lightColor ?? primaryBlue);

  static Color adaptiveIcon(bool isDarkMode, {Color? lightColor}) =>
      isDarkMode ? Colors.white : (lightColor ?? accentBlue);

  // Light Theme
  static const Color scaffoldLight = Color(0xFFF1F5F9);
  static const Color cardLight = Colors.white;
  static const Color inputLight = Colors.white;
  static const Color textBlack = Color(0xFF0F172A);
  static const Color textGreyLight = Color(0xFF64748B);
  static const Color logoBgLight = Color(
    0xFFE2E8F0,
  ); // Lighter background for logo in day mode

  // Dark Theme
  static const Color scaffoldDark = Color(0xFF161C2E); // Deep Navy Black
  static const Color cardDark = Color(0xFF161C2E); // Navy Card
  static const Color inputDark = Color(0xFF1F2D5D);
  static const Color textWhite = Colors.white;
  static const Color textGreyDark = Color(0xFFB5B6B7); // Silver as Grey

  // Gradients (Dynamic)
  static LinearGradient get primaryGradient => LinearGradient(
    colors: [primaryBlue, secondaryBlue, const Color(0xFF0B101D)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradient => LinearGradient(
    colors: [primaryBlue, scaffoldDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF00C853), Color(0xFF00E676)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient warningGradient = LinearGradient(
    colors: [Color(0xFFFF6F00), Color(0xFFFFA726)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient errorGradient = LinearGradient(
    colors: [Color(0xFFD32F2F), Color(0xFFEF5350)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient logoGradientDay = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFE2E8F0)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static LinearGradient get buttonGradient => LinearGradient(
    colors: [secondaryBlue, primaryBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static LinearGradient get buttonHoverGradient => LinearGradient(
    colors: [glowBlue, secondaryBlue],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Additional Professional Colors
  static const Color successGreen = Color(0xFF00C853);
  static const Color warningOrange = Color(0xFFFF6F00);
  static const Color errorRed = Color(0xFFD32F2F);
  static const Color infoBlue = Color(0xFF2196F3);

  // Surface Colors
  static const Color surfaceLight = Color(0xFFFAFBFC);
  static const Color surfaceDark = Color(0xFF0F1419);

  // Border Colors
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2F3C5F);

  // Shadow Colors
  static const Color shadowLight = Color(0x10000000);
  static const Color shadowDark = Color(0x20000000);

  // Interactive States
  static const Color hoverColor = Color(0x0A3D5AFE);
  static const Color focusColor = Color(0x153D5AFE);
  static const Color pressedColor = Color(0x1F3D5AFE);
}
