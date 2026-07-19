import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'text_styles.dart';

/// Estilos de botão do UniChat — pill shape conforme protótipo.
class AppButtonStyles {
  AppButtonStyles._();

  static ButtonStyle get primary => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    textStyle: AppTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    elevation: 0,
  );

  static ButtonStyle get secondary => OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: AppTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    side: const BorderSide(color: AppColors.primary, width: 1.5),
  );

  static ButtonStyle get ghost => TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: AppTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
  );

  static ButtonStyle get accent => ElevatedButton.styleFrom(
    backgroundColor: AppColors.accent,
    foregroundColor: AppColors.white,
    textStyle: AppTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
    elevation: 0,
  );

  static ButtonStyle get destructive => TextButton.styleFrom(
    foregroundColor: AppColors.destructive,
    backgroundColor: AppColors.destructiveLight,
    textStyle: AppTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
  );
}
