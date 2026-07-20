import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    textTheme: GoogleFonts.interTextTheme(),
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      primaryContainer: AppColors.secondaryLight,
      secondary: AppColors.accent,
      secondaryContainer: AppColors.mutedLight,
      surface: AppColors.cardLight,
      error: AppColors.destructive,
      onPrimary: AppColors.primaryForegroundLight,
      onSecondary: AppColors.accentForegroundLight,
      onSurface: AppColors.foregroundLight,
      outline: AppColors.borderLight,
    ),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardLight,
      foregroundColor: AppColors.foregroundLight,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.foregroundLight,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardLight,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderLight),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.backgroundLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.destructive),
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.mutedForegroundLight,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.primaryForegroundLight,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        elevation: 0,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.primaryForegroundLight,
      shape: CircleBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderLight,
      thickness: 1,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    textTheme: GoogleFonts.interTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ),
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryLight,
      primaryContainer: AppColors.secondaryDark,
      secondary: AppColors.accentLight,
      secondaryContainer: AppColors.mutedDark,
      surface: AppColors.cardDark,
      error: AppColors.destructiveDark,
      onPrimary: AppColors.primaryForegroundDark,
      onSecondary: AppColors.accentForegroundDark,
      onSurface: AppColors.foregroundDark,
      outline: AppColors.borderDark,
    ),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.cardDark,
      foregroundColor: AppColors.foregroundDark,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.foregroundDark,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.cardDark,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderDark),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.secondaryDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.borderDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(100),
        borderSide: const BorderSide(color: AppColors.destructiveDark),
      ),
      hintStyle: GoogleFonts.inter(
        fontSize: 15,
        color: AppColors.mutedForegroundDark,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.primaryForegroundDark,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
        elevation: 0,
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primaryLight,
      foregroundColor: AppColors.primaryForegroundDark,
      shape: CircleBorder(),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.borderDark,
      thickness: 1,
    ),
  );
}
