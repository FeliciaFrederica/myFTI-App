class TransactionModel {
  final String id;
  final String reference;
  final String type;
  final String status;
  final int amount;
  final String? description;
  final String? counterpartName;
  final String? bankCode;
  final String? accountNumber;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.reference,
    required this.type,
    required this.status,
    required this.amount,
    this.description,
    this.counterpartName,
    this.bankCode,
    this.accountNumber,
    required this.createdAt,
  });

  // TOP_UP, TRANSFER_IN, dan PAYMENT_IN menambah saldo.
  bool get isIncoming =>
      type == 'TOP_UP' || type == 'TRANSFER_IN' || type == 'PAYMENT_IN';

  bool get isOutgoing => !isIncoming;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      reference: json['reference'] as String,
      type: json['type'] as String,
      status: json['status'] as String,
      amount: (json['amount'] as num).toInt(),
      description: json['description'] as String?,
      counterpartName: json['counterpartName'] as String?,
      bankCode: json['bankCode'] as String?,
      accountNumber: json['accountNumber'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
