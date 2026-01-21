// Deposit-related models for the ThumaPay application
import 'package:cloud_firestore/cloud_firestore.dart';

enum DepositMethod {
  bankCard,
  eft,
  mobileMoney,
  qrCode,
}

extension DepositMethodExtension on DepositMethod {
  String get displayName {
    switch (this) {
      case DepositMethod.bankCard:
        return 'Bank Card';
      case DepositMethod.eft:
        return 'EFT / Bank Transfer';
      case DepositMethod.mobileMoney:
        return 'Mobile Money';
      case DepositMethod.qrCode:
        return 'QR Code';
    }
  }

  String get iconName {
    switch (this) {
      case DepositMethod.bankCard:
        return 'credit_card';
      case DepositMethod.eft:
        return 'account_balance';
      case DepositMethod.mobileMoney:
        return 'phone_android';
      case DepositMethod.qrCode:
        return 'qr_code';
    }
  }
}

class AutoDeposit {
  final String id;
  final String userId;
  final double amount;
  final DepositMethod method;
  final int dayOfMonth; // 1-31
  final DateTime createdAt;
  final DateTime? lastExecutedAt;
  final bool isActive;
  final DateTime? endDate;
  final Map<String, dynamic>? paymentMetadata; // Card details, EFT info, etc.

  const AutoDeposit({
    required this.id,
    required this.userId,
    required this.amount,
    required this.method,
    required this.dayOfMonth,
    required this.createdAt,
    this.lastExecutedAt,
    this.isActive = true,
    this.endDate,
    this.paymentMetadata,
  });

  factory AutoDeposit.fromMap(String id, Map<String, dynamic> data) {
    return AutoDeposit(
      id: id,
      userId: data['userId'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      method: DepositMethod.values.firstWhere(
        (e) => e.name == data['method'],
        orElse: () => DepositMethod.bankCard,
      ),
      dayOfMonth: data['dayOfMonth'] ?? 1,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastExecutedAt: data['lastExecutedAt'] != null
          ? (data['lastExecutedAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      paymentMetadata: data['paymentMetadata'] != null
          ? Map<String, dynamic>.from(data['paymentMetadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'amount': amount,
      'method': method.name,
      'dayOfMonth': dayOfMonth,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastExecutedAt': lastExecutedAt != null
          ? Timestamp.fromDate(lastExecutedAt!)
          : null,
      'isActive': isActive,
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'paymentMetadata': paymentMetadata,
    };
  }

  bool get shouldExecuteToday {
    if (!isActive) return false;
    final now = DateTime.now();
    if (endDate != null && now.isAfter(endDate!)) return false;
    return now.day == dayOfMonth &&
           (lastExecutedAt == null ||
            !lastExecutedAt!.isAtSameMomentAs(DateTime(now.year, now.month, dayOfMonth)));
  }

  AutoDeposit copyWith({
    String? id,
    String? userId,
    double? amount,
    DepositMethod? method,
    int? dayOfMonth,
    DateTime? createdAt,
    DateTime? lastExecutedAt,
    bool? isActive,
    DateTime? endDate,
    Map<String, dynamic>? paymentMetadata,
  }) {
    return AutoDeposit(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      createdAt: createdAt ?? this.createdAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      isActive: isActive ?? this.isActive,
      endDate: endDate ?? this.endDate,
      paymentMetadata: paymentMetadata ?? this.paymentMetadata,
    );
  }
}

class Alert {
  final String id;
  final String userId;
  final AlertType type;
  final double threshold; // For low balance, the amount
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastTriggeredAt;
  final Map<String, dynamic>? metadata;

  const Alert({
    required this.id,
    required this.userId,
    required this.type,
    required this.threshold,
    this.isActive = true,
    required this.createdAt,
    this.lastTriggeredAt,
    this.metadata,
  });

  factory Alert.fromMap(String id, Map<String, dynamic> data) {
    return Alert(
      id: id,
      userId: data['userId'] ?? '',
      type: AlertType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => AlertType.lowBalance,
      ),
      threshold: (data['threshold'] ?? 0.0).toDouble(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastTriggeredAt: data['lastTriggeredAt'] != null
          ? (data['lastTriggeredAt'] as Timestamp).toDate()
          : null,
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'threshold': threshold,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastTriggeredAt': lastTriggeredAt != null
          ? Timestamp.fromDate(lastTriggeredAt!)
          : null,
      'metadata': metadata,
    };
  }
}

enum AlertType {
  lowBalance,
  depositReminder,
  spendingLimit,
}

extension AlertTypeExtension on AlertType {
  String get displayName {
    switch (this) {
      case AlertType.lowBalance:
        return 'Low Balance Alert';
      case AlertType.depositReminder:
        return 'Deposit Reminder';
      case AlertType.spendingLimit:
        return 'Spending Limit Alert';
    }
  }
}

class DepositSuggestion {
  final double amount;
  final String reason;
  final DateTime basedOnDate;

  const DepositSuggestion({
    required this.amount,
    required this.reason,
    required this.basedOnDate,
  });
}