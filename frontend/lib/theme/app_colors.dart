import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1A3A6B);
  static const Color primaryLight = Color(0xFF4F8FE8);
  static const Color primaryDark = Color(0xFF0F4C75);
  static const Color primaryForegroundLight = Color(0xFFFFFFFF);
  static const Color primaryForegroundDark = Color(0xFF0C1626);

  static const Color accent = Color(0xFF2DD4BF);
  static const Color accentLight = Color(0xFF5EEAD4);
  static const Color accentForegroundLight = Color(0xFF0F1B2D);
  static const Color accentForegroundDark = Color(0xFF0C1626);

  static const Color backgroundLight = Color(0xFFF5F8FC);
  static const Color backgroundDark = Color(0xFF0C1626);

  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF142036);
  static const Color secondaryLight = Color(0xFFEAF0F8);
  static const Color secondaryDark = Color(0xFF1B2A44);
  static const Color mutedLight = Color(0xFFEEF2F8);
  static const Color mutedDark = Color(0xFF1B2A44);

  static const Color foregroundLight = Color(0xFF0F1B2D);
  static const Color foregroundDark = Color(0xFFE8EDF5);

  static const Color mutedForegroundLight = Color(0xFF5C6B82);
  static const Color mutedForegroundDark = Color(0xFF8B9BB6);

  static const Color borderLight = Color(0xFFDDE6F1);
  static const Color borderDark = Color(0xFF22324C);

  static const Color destructive = Color(0xFFE11D48);
  static const Color destructiveDark = Color(0xFFF43F5E);
  static const Color destructiveLight = Color(0x1AE11D48);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color online = accent;

  static Color primaryFor(Brightness brightness) =>
      brightness == Brightness.dark ? primaryLight : primary;

  static Color primaryForegroundFor(Brightness brightness) =>
      brightness == Brightness.dark
      ? primaryForegroundDark
      : primaryForegroundLight;

  static Color accentFor(Brightness brightness) =>
      brightness == Brightness.dark ? accentLight : accent;

  static Color accentForegroundFor(Brightness brightness) =>
      brightness == Brightness.dark
      ? accentForegroundDark
      : accentForegroundLight;

  static Color destructiveFor(Brightness brightness) =>
      brightness == Brightness.dark ? destructiveDark : destructive;
}
