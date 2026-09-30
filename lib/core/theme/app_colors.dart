import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFFE64A19);
  static const Color primaryDark = Color(0xFFBF360C);
  static const Color primaryLight = Color(0xFFFF7043);
  static const Color accent = Color(0xFFFFB300);

  static const Color backgroundLight = Color(0xFFFFF7F2);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF2B2B2B);
  static const Color textSecondary = Color(0xFF7E7E7E);
  static const Color success = Color(0xFF43A047);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: <Color>[primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: <Color>[backgroundLight, Color(0xFFFFEDE4)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
