import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  payment,
  purchase,
  transfer,
  airtime,
  transport,
  refund,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
}

class TransactionModel {
  final String id;
  final String vendorId;
  final String customerId;
  final TransactionType type;
  final double amount;
  final String currency;
  final TransactionStatus status;
  final String description;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? receiptId;
  final bool isRolledBack;

  TransactionModel({
    required this.id,
    required this.vendorId,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.currency,
    required this.status,
    required this.description,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
    this.receiptId,
    this.isRolledBack = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'customerId': customerId,
      'type': type.name,
      'amount': amount,
      'currency': currency,
      'status': status.name,
      'description': description,
      'metadata': metadata,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'receiptId': receiptId,
      'isRolledBack': isRolledBack,
    };
  }

  factory TransactionModel.fromMap(String id, Map<String, dynamic> map) {
    return TransactionModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      customerId: map['customerId'] ?? '',
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.payment,
      ),
      amount: (map['amount'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'ZAR',
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      description: map['description'] ?? '',
      metadata: map['metadata'] ?? {},
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      receiptId: map['receiptId'],
      isRolledBack: map['isRolledBack'] ?? false,
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      return DateTime.now();
    }
  }
}
