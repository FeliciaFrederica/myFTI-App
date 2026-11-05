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
    return UserModel(
      id: (json['id'] ?? json['user_id'] ?? '').toString(),
      name: json['name'] ?? json['nama_lengkap'] ?? '',
      email: json['email'] ?? '',
      nim: (json['nim'] ?? '').toString(),
      walletId: (json['wallet_id'] ?? '').toString(),
      balance: num.tryParse((json['balance'] ?? json['saldo'] ?? 0).toString()) ?? 0,
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