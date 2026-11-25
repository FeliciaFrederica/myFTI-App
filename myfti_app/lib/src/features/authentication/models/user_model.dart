class UserModel {
  final String id;
  final String name;
  final String email;
  final String nim;
  final String walletId;
  final num balance;
  final String role;
  final String? avatar;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.nim,
    required this.walletId,
    required this.balance,
    required this.role,
    this.avatar,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] is Map
        ? Map<String, dynamic>.from(json['wallet'])
        : <String, dynamic>{};

    // Foto profil dari server (data URL base64), kosong dianggap tidak ada foto
    final avatar = json['avatarUrl'] ?? json['avatar'];

    return UserModel(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['nama_lengkap'] ?? '')
          .toString(),
      email: (json['email'] ?? '').toString(),
      nim: (json['nim'] ?? '').toString(),
      walletId: (json['wallet_id'] ?? wallet['walletId'] ?? '').toString(),
      balance:
          num.tryParse(
            (json['balance'] ?? json['saldo'] ?? wallet['balance'] ?? 0)
                .toString(),
          ) ??
          0,
      role: (json['role'] ?? 'STUDENT').toString(),
      avatar: (avatar == null || avatar.toString().isEmpty)
          ? null
          : avatar.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'nim': nim,
    'wallet_id': walletId,
    'balance': balance,
    'role': role,
    'avatar': avatar,
  };

  // Inisial untuk CircleAvatar, contoh "Budi Santoso" -> "BS"
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}