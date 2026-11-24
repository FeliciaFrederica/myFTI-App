import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/user_model.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/top_notice.dart';
import '../services/auth_service.dart';
import '../widgets/auth_field.dart';
import '../widgets/user_avatar.dart';
import 'change_password_page.dart';

const Color _kCardColor = Color(0xFFF3EEFC);

class EditProfilePage extends StatefulWidget {
  final UserModel user;
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameC;
  late final TextEditingController _emailC;
  bool _saving = false;
  String? _error;

  // Foto baru yang dipilih (belum dikirim ke server) dan status hapus foto
  Uint8List? _newBytes;
  bool _removeAvatar = false;

  bool get _profileChanged =>
      _nameC.text.trim().toUpperCase() != widget.user.name.toUpperCase() ||
      _emailC.text.trim() != widget.user.email;

  bool get _avatarChanged => _newBytes != null || _removeAvatar;

  // Tombol simpan hanya aktif kalau ada data yang berubah
  bool get _changed => _profileChanged || _avatarChanged;

  bool get _hasPhoto =>
      _newBytes != null ||
      (!_removeAvatar && (widget.user.avatar?.isNotEmpty ?? false));

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.user.name.toUpperCase());
    _emailC = TextEditingController(text: widget.user.email);
    _nameC.addListener(_onChanged);
    _emailC.addListener(_onChanged);
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      // Ukuran dikecilkan dulu supaya ringan saat dikirim dan disimpan
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 75,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _newBytes = bytes;
        _removeAvatar = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Tidak dapat mengakses foto');
    }
  }

  void _showPhotoSheet() {
    if (_saving) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: _kCardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Pilih dari galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.primary),
              title: const Text('Ambil foto'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            if (_hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.error),
                title: const Text('Hapus foto',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _newBytes = null;
                    _removeAvatar = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openChangePassword() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const ChangePasswordPage()),
    );
    if (ok == true && mounted) {
      // Notifikasi tampil di bagian atas halaman
      TopNotice.show(context, 'Password berhasil diubah', success: true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      // Foto dikirim dulu kalau berubah, lalu nama dan email
      if (_avatarChanged) {
        final data = _removeAvatar
            ? null
            : 'data:image/jpeg;base64,${base64Encode(_newBytes!)}';
        await AuthService.updateAvatar(data);
      }
      if (_profileChanged) {
        await AuthService.updateProfile(
          name: _nameC.text.trim().toUpperCase(),
          email: _emailC.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Tidak bisa kembali saat sedang menyimpan
      canPop: !_saving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.text),
            onPressed: _saving ? null : () => Navigator.pop(context),
          ),
          title: const Text(
            'Edit Profil',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _showPhotoSheet,
                        child: Stack(
                          children: [
                            UserAvatar(
                              initials: widget.user.initials,
                              avatar: _removeAvatar ? null : widget.user.avatar,
                              localBytes: _newBytes,
                              radius: 48,
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.primary, width: 1.5),
                                ),
                                child: const Icon(Icons.photo_camera,
                                    size: 16, color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      AuthField(
                        controller: _nameC,
                        label: 'Nama Lengkap',
                        icon: Icons.person_outline,
                        onLight: true,
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().length < 3)
                            ? 'Nama minimal 3 karakter'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      AuthField(
                        controller: _emailC,
                        label: 'Email',
                        icon: Icons.email_outlined,
                        onLight: true,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email wajib diisi';
                          }
                          final ok = RegExp(r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$')
                              .hasMatch(v.trim());
                          return ok ? null : 'Format email tidak valid';
                        },
                      ),
                      const SizedBox(height: 24),
                      Card(
                        color: _kCardColor,
                        elevation: 0,
                        // Hilangkan margin bawaan Card (4px) supaya lebarnya
                        // sama dengan field Nama dan Email
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          leading: const Icon(Icons.lock_outline,
                              color: AppColors.primary),
                          title: const Text('Ubah Password'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _saving ? null : _openChangePassword,
                        ),
                      ),
                      // Error dari server
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: (_saving || !_changed) ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      disabledForegroundColor: Colors.grey.shade500,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}