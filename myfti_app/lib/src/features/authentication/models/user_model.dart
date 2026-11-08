class UserModel {
  final String id;
  final String name;
  final String email;
  final String nim;
  final String walletId;
  final num balance;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.nim,
    required this.walletId,
    required this.balance,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final wallet = json['wallet'] is Map
        ? Map<String, dynamic>.from(json['wallet'])
        : <String, dynamic>{};

    return UserModel(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      name: (json['name'] ?? json['fullName'] ?? json['nama_lengkap'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      nim: (json['nim'] ?? '').toString(),
      walletId: (json['wallet_id'] ?? wallet['walletId'] ?? '').toString(),
      balance: num.tryParse(
            (json['balance'] ?? json['saldo'] ?? wallet['balance'] ?? 0).toString(),
          ) ??
          0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'nim': nim,
        'wallet_id': walletId,
        'balance': balance,
      };

  /// Inisial untuk CircleAvatar, contoh "Budi Santoso" -> "BS"
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}