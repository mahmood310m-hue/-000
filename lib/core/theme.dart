import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFFF3FAF6);
  static const mint = Color(0xFF8ED8C0);
  static const mintSoft = Color(0xFFE3F5EE);
  static const green = Color(0xFF2F8F78);
  static const dark = Color(0xFF1F3D36);
  static const muted = Color(0xFF6B8A81);
  static const border = Color(0xFFDDEFE7);
  static const danger = Color(0xFFD9534F);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green, surface: Colors.white),
    scaffoldBackgroundColor: AppColors.bg,
  );
  final text = GoogleFonts.cairoTextTheme(base.textTheme)
      .apply(bodyColor: AppColors.dark, displayColor: AppColors.dark);
  OutlineInputBorder ob(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c),
      );
  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.dark,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      titleTextStyle: GoogleFonts.cairo(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.dark),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: ob(AppColors.border),
      enabledBorder: ob(AppColors.border),
      focusedBorder: ob(AppColors.green),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.mint.withAlpha(110),
      height: 66,
      labelTextStyle: WidgetStatePropertyAll(
          GoogleFonts.cairo(fontSize: 10.5, fontWeight: FontWeight.w600)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
  );
}
