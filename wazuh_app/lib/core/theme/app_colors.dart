import 'package:flutter/material.dart';

class AppColors {
  static const int _primaryValue = 0xFF1976D2;
  static const int _secondaryValue = 0xFF00ACC1;

  static const MaterialColor primary = MaterialColor(_primaryValue, {
    50: Color(0xFFE3F2FD),
    100: Color(0xFFBBDEFB),
    200: Color(0xFF90CAF9),
    300: Color(0xFF64B5F6),
    400: Color(0xFF42A5F5),
    500: Color(0xFF2196F3),
    600: Color(0xFF1E88E5),
    700: Color(0xFF1976D2),
    800: Color(_primaryValue),
    900: Color(0xFF0D47A1),
  });

  static const MaterialColor secondary = MaterialColor(_secondaryValue, {
    50: Color(0xFFE0F7FA),
    100: Color(0xFFB2EBF2),
    200: Color(0xFF80DEEA),
    300: Color(0xFF4DD0E1),
    400: Color(0xFF26C6DA),
    500: Color(0xFF00BCD4),
    600: Color(0xFF00ACC1),
    700: Color(0xFF0097A7),
    800: Color(_secondaryValue),
    900: Color(0xFF00838F),
  });

  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color surface = Color(0xFFF5F5F5);
}

class SeverityColors {
  static Color getColor(int level) {
    if (level >= 12) return AppColors.error;
    if (level >= 7) return AppColors.warning;
    return AppColors.secondary;
  }
}
