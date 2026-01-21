import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id;
  final String userId;
  final double balance;
  final String currency;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? spendingLimit;

  WalletModel({
    required this.id,
    required this.userId,
    required this.balance,
    required this.currency,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.spendingLimit,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'balance': balance,
      'currency': currency,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'spendingLimit': spendingLimit,
    };
  }

  factory WalletModel.fromMap(String id, Map<String, dynamic> map) {
    return WalletModel(
      id: id,
      userId: map['userId'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'ZAR',
      isActive: map['isActive'] ?? true,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      spendingLimit: map['spendingLimit'] != null
          ? (map['spendingLimit'] as num).toDouble()
          : null,
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
