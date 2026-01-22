import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerCardModel {
  final String id;
  final String parentId;
  final String cardNumber;
  final String cardName;
  final double balance;
  final String currency;
  final double spendingLimit;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;

  CustomerCardModel({
    required this.id,
    required this.parentId,
    required this.cardNumber,
    required this.cardName,
    required this.balance,
    required this.currency,
    required this.spendingLimit,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'cardNumber': cardNumber,
      'cardName': cardName,
      'balance': balance,
      'currency': currency,
      'spendingLimit': spendingLimit,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'expiresAt': expiresAt,
    };
  }

  factory CustomerCardModel.fromMap(String id, Map<String, dynamic> map) {
    return CustomerCardModel(
      id: id,
      parentId: map['parentId'] ?? '',
      cardNumber: map['cardNumber'] ?? '',
      cardName: map['cardName'] ?? '',
      balance: (map['balance'] ?? 0.0).toDouble(),
      currency: map['currency'] ?? 'ZAR',
      spendingLimit: (map['spendingLimit'] ?? 0.0).toDouble(),
      isActive: map['isActive'] ?? true,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
      expiresAt:
          map['expiresAt'] != null ? _parseTimestamp(map['expiresAt']) : null,
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
