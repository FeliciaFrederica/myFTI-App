import 'package:flutter/material.dart';
import 'package:myfti_app/src/core/theme/app_theme.dart';

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
    this.textInputAction,
  });

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: textInputAction,
      style: const TextStyle(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.secondary),
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.card,
        border: _border(Colors.transparent),
        enabledBorder: _border(Colors.transparent),
        focusedBorder: _border(AppColors.primary, 1.5),
        errorBorder: _border(AppColors.error),
        focusedErrorBorder: _border(AppColors.error, 1.5),
      ),
    );
  }
}