import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryBlue = Color(0xFF1A73E8);
  static const Color primaryGreen = Color(0xFF34A853);
  static const Color gradientStart = Color(0xFF0F172A);
  static const Color gradientEnd = Color(0xFF1E293B);
  static const Color background = Color(0xFF0A0E21);
  static const Color surface = Color(0xFF1D1E33);
  static const Color cardColor = Color(0xFF252742);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color accentGold = Color(0xFFFFD740); // Jeton rengi

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [gradientStart, gradientEnd],
  );
}
