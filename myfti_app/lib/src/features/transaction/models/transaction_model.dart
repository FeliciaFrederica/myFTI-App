class TransactionModel {
  final String id;
  final String reference;
  final String type;
  final String status;
  final int amount;
  final String? description;
  final String? counterpartName;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.reference,
    required this.type,
    required this.status,
    required this.amount,
    this.description,
    this.counterpartName,
    required this.createdAt,
  });

  // TOP_UP dan TRANSFER_IN menambah saldo.
  bool get isIncoming =>
      type == 'TOP_UP' || type == 'TRANSFER_IN';

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
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
