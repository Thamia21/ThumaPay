import 'package:cloud_firestore/cloud_firestore.dart';

class WalletModel {
  final String id;
  final String userId;
  final String userName;
  final double balance;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTransactionAt;
  final Map<String, dynamic>? metadata;

  const WalletModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.balance,
    this.isActive = true,
    required this.createdAt,
    this.lastTransactionAt,
    this.metadata,
  });

  factory WalletModel.fromMap(String id, Map<String, dynamic> data) {
    return WalletModel(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      balance: (data['balance'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastTransactionAt: data['lastTransactionAt'] != null
          ? (data['lastTransactionAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'balance': balance,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastTransactionAt': lastTransactionAt != null
          ? Timestamp.fromDate(lastTransactionAt!)
          : null,
      'metadata': metadata,
    };
  }

  String get formattedBalance {
    return 'R ${balance.toStringAsFixed(2)}';
  }

  WalletModel copyWith({
    String? id,
    String? userId,
    String? userName,
    double? balance,
    bool? isActive,
    DateTime? createdAt,
    DateTime? lastTransactionAt,
    Map<String, dynamic>? metadata,
  }) {
    return WalletModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      balance: balance ?? this.balance,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      lastTransactionAt: lastTransactionAt ?? this.lastTransactionAt,
      metadata: metadata ?? this.metadata,
    );
  }
}