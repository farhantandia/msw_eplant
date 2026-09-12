import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF090E1A);
  static const surface = Color(0xFF111827);
  static const surface2 = Color(0xFF1C2539);
  static const border = Color(0xFF1F2D45);
  static const primary = Color(0xFF00C2FF);
  static const maintenance = Color(0xFFFFB020);
  static const general = Color(0xFF00E5A0);
  static const solar = Color(0xFF00E5A0); // Green energy theme for Solar PV
  static const danger = Color(0xFFFF4D6A);
  @Deprecated('Avoid aggressive colors; prefer AppColors.primary or domain colors.')
  static const purple = Color(0xFFC084FC);
  @Deprecated('Avoid aggressive colors; prefer AppColors.primary or domain colors.')
  static const pink = Color(0xFFF472B6);
  static const text = Color(0xFFF0F4FF);
  static const textSub = Color.fromARGB(255, 198, 202, 213);
  static const textDim = Color(0xFF6B7FA3);

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

class AppFontSize {
  static const double fs11 = 12;
  static const double fs12 = 12;
  static const double fs13 = 13;
  static const double fs14 = 14;
  static const double fs15 = 15;
  static const double fs16 = 16;
  static const double fs17 = 17;
  static const double fs18 = 18;
  static const double fs20 = 20;
  static const double fs22 = 22;
  static const double fs28 = 28;
  static const double fs34 = 34;
  static const double fs36 = 36;
  static const double fs42 = 42;
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
  // Font scale tokens (minimal fs11)
  static const double fs11 = AppFontSize.fs11;
  static const double fs12 = AppFontSize.fs12;
  static const double fs13 = AppFontSize.fs13;
  static const double fs14 = AppFontSize.fs14;
  static const double fs15 = AppFontSize.fs15;
  static const double fs16 = AppFontSize.fs16;
  static const double fs17 = AppFontSize.fs17;
  static const double fs18 = AppFontSize.fs18;
  static const double fs20 = AppFontSize.fs20;
  static const double fs22 = AppFontSize.fs22;
  static const double fs28 = AppFontSize.fs28;
  static const double fs34 = AppFontSize.fs34;
  static const double fs36 = AppFontSize.fs36;
  static const double fs42 = AppFontSize.fs42;

  static ThemeData get dark {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: Color(0xA6000000),
        error: AppColors.danger,
      ),
      cardTheme: const CardThemeData(
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
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          elevation: 0,
          textStyle: const TextStyle(
            fontSize: AppTheme.fs14,
            fontWeight: FontWeight.w700,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(smallRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.text,
          side: const BorderSide(color: AppColors.border),
          textStyle: const TextStyle(
            fontSize: AppTheme.fs14,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(smallRadius),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: AppColors.text),
        bodyMedium: TextStyle(color: AppColors.textSub),
        labelSmall: TextStyle(color: AppColors.textDim),
      ),
    );
  }
}
