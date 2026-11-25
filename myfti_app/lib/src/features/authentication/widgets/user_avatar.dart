import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// Avatar user akan berupa foto apabila user menambahkan atau mengubah foto profil, atau hanya akan berupa inisial nama 
class UserAvatar extends StatelessWidget {
  final String initials;
  final String? avatar;
  final Uint8List? localBytes;
  final double radius;

  const UserAvatar({
    super.key,
    required this.initials,
    this.avatar,
    this.localBytes,
    this.radius = 48,
  });

  Uint8List? _bytes() {
    if (localBytes != null) return localBytes;
    if (avatar == null || avatar!.isEmpty) return null;
    try {
      final raw = avatar!.contains(',') ? avatar!.split(',').last : avatar!;
      return base64Decode(raw);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes();
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      backgroundImage: bytes == null ? null : MemoryImage(bytes),
      child: bytes == null
          ? Text(
              initials,
              style: TextStyle(
                fontSize: radius * 0.66,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}