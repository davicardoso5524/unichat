import 'package:flutter/material.dart';
import 'package:unichat/theme/app_colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final bool obscure;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const CustomTextField({
    super.key,
    this.controller,
    this.hint,
    this.obscure = false,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: theme.colorScheme.surfaceContainerHighest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(
            color: AppColors.destructive,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(26),
          borderSide: const BorderSide(
            color: AppColors.destructive,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
