import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  const AuthField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.validator,
  });

  OutlineInputBorder _border(Color color, [double width = 0]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: width == 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label di atas kotak -> tidak akan pernah terpotong
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          style: const TextStyle(color: Color(0xFF2D2640), fontSize: 15),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              color: const Color(0xFF2D2640).withOpacity(0.4),
            ),
            filled: true,
            fillColor: const Color(0xFFEDE7F6),
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorStyle: const TextStyle(
              color: Color(0xFFFFCDD2), // merah muda terang, kontras di ungu
              fontWeight: FontWeight.w600,
            ),
            border: _border(Colors.transparent),
            enabledBorder: _border(Colors.transparent),
            focusedBorder: _border(AppColors.primary, 1.5),
            errorBorder: _border(const Color(0xFFFFCDD2), 1.2),
            focusedErrorBorder: _border(const Color(0xFFFFCDD2), 1.8),
          ),
        ),
      ],
    );
  }
}