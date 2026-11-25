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
  final ValueChanged<String>? onChanged;

  // Dipakai kalau field perlu divalidasi ulang dari luar
  // (contoh: konfirmasi password saat password berubah)
  final GlobalKey<FormFieldState<String>>? fieldKey;

  // true  = akan dipakai ketika latar terang
  // false = akan dipakai ketika latar ungu, default aplikasi
  final bool onLight;

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
    this.onChanged,
    this.fieldKey,
    this.onLight = false,
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
    final labelColor = onLight ? AppColors.text : Colors.white;

    final errorColor = onLight ? AppColors.error : const Color(0xFFFF5252);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextFormField(
          key: fieldKey,
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          onChanged: onChanged,
          // Warning akan langsung muncul pada saat user mulai mengetik
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(color: Color(0xFF2D2640), fontSize: 15),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: label,
            hintStyle: TextStyle(
              color: const Color(0xFF2D2640).withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: const Color(0xFFEDE7F6),
            prefixIcon: Icon(icon, color: AppColors.primary),
            suffixIcon: suffix,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            errorStyle: TextStyle(
              color: errorColor,
              fontWeight: FontWeight.w600,
            ),
            border: _border(Colors.transparent),
            enabledBorder: _border(Colors.transparent),
            focusedBorder: _border(AppColors.primary, 1.5),
            // Frame merah saat tidak valid
            errorBorder: _border(errorColor, 1.8),
            focusedErrorBorder: _border(errorColor, 2.2),
          ),
        ),
      ],
    );
  }
}