import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF090E1A);
  static const surface = Color(0xFF111827);
  static const surface2 = Color(0xFF1C2539);
  static const border = Color(0xFF1F2D45);
  static const primary = Color(0xFF00C2FF);
  static const maintenance = Color(0xFFFFB020);
  static const general = Color(0xFF00E5A0);
  static const danger = Color(0xFFFF4D6A);
  static const purple = Color(0xFFC084FC);
  static const pink = Color(0xFFF472B6);
  static const text = Color(0xFFF0F4FF);
  static const textSub = Color(0xFF6B7FA3);
  static const textDim = Color(0xFF3D4F6E);

  static Color roleColor(String role) {
    switch (role) {
      case 'Operation':
        return primary;
      case 'Maintenance':
        return maintenance;
      case 'General':
        return general;
      default:
        return primary;
    }
  }
}

class AppTheme {
  // Design tokens
  static const double cardRadius = 14;
  static const double smallRadius = 10;
  static const double miniRadius = 7;
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 12;
  static const double spacingLg = 16;
  static const double spacingXl = 20;
  // Font scale: 8 sizes, min 10
  static const double fs10 = 10;
  static const double fs12 = 12;
  static const double fs14 = 14;
  static const double fs16 = 16;
  static const double fs18 = 18;
  static const double fs22 = 22;
  static const double fs28 = 28;
  static const double fs36 = 36;

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primary,
        surface: Color(0xA6000000),
        error: AppColors.danger,
      ),
      cardTheme: CardThemeData(
        color: Color(0xA6000000),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(cardRadius)),
          side: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(color: AppColors.text, fontSize: AppTheme.fs16, fontWeight: FontWeight.w700),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.black.withOpacity(0.65),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textDim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.textSub),
        labelSmall: TextStyle(color: AppColors.textDim),
      ),
    );
  }
}
