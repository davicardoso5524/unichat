import 'package:flutter/material.dart';

/// Paleta de cores do UniChat baseada no protótipo hi-fi.
/// Primary: roxo/violeta acadêmico
/// Accent: verde-água (teal) para badges e sucesso
class AppColors {
  AppColors._();

  // ─── Primary ───
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF9B94FF);
  static const Color primaryDark = Color(0xFF4A42DB);

  // ─── Accent (verde-água) ───
  static const Color accent = Color(0xFF2DD4BF);
  static const Color accentLight = Color(0xFF5EEAD4);

  // ─── Background ───
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color backgroundDark = Color(0xFF0F172A);

  // ─── Card / Surface ───
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1E293B);

  // ─── Foreground (texto) ───
  static const Color foregroundLight = Color(0xFF0F172A);
  static const Color foregroundDark = Color(0xFFF1F5F9);

  // ─── Muted ───
  static const Color mutedForegroundLight = Color(0xFF64748B);
  static const Color mutedForegroundDark = Color(0xFF94A3B8);

  // ─── Border ───
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF334155);

  // ─── Destructive ───
  static const Color destructive = Color(0xFFEF4444);
  static const Color destructiveLight = Color(0x1AEF4444); // 10% opacity

  // ─── Extras ───
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color online = Color(0xFF22C55E);
}
