// Transaction model for recording all money movements
import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  deposit,
  withdrawal,
  transfer,
  refund,
}

enum TransactionStatus {
  pending,
  completed,
  failed,
  cancelled,
  scheduled,
}

enum TransferType {
  toChild,
  toParent,
  toExternal,
}

class Transaction {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final double amount;
  final String? message;
  final TransactionType type;
  final TransactionStatus status;
  final TransferType? transferType;
  final DateTime createdAt;
  final DateTime? completedAt;
  final bool isScheduled;
  final DateTime? scheduledFor;
  final String? referenceId;
  final Map<String, dynamic>? metadata;

  const Transaction({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.amount,
    this.message,
    required this.type,
    required this.status,
    this.transferType,
    required this.createdAt,
    this.completedAt,
    this.isScheduled = false,
    this.scheduledFor,
    this.referenceId,
    this.metadata,
  });

  factory Transaction.fromMap(String id, Map<String, dynamic> data) {
    return Transaction(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      receiverId: data['receiverId'] ?? '',
      receiverName: data['receiverName'] ?? '',
      amount: (data['amount'] ?? 0.0).toDouble(),
      message: data['message'],
      type: TransactionType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => TransactionType.transfer,
      ),
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => TransactionStatus.pending,
      ),
      transferType: data['transferType'] != null
          ? TransferType.values.firstWhere(
              (e) => e.name == data['transferType'],
              orElse: () => TransferType.toChild,
            )
          : null,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] as Timestamp).toDate()
          : null,
      isScheduled: data['isScheduled'] ?? false,
      scheduledFor: data['scheduledFor'] != null
          ? (data['scheduledFor'] as Timestamp).toDate()
          : null,
      referenceId: data['referenceId'],
      metadata: data['metadata'] != null
          ? Map<String, dynamic>.from(data['metadata'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'amount': amount,
      'message': message,
      'type': type.name,
      'status': status.name,
      'transferType': transferType?.name,
      'createdAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'isScheduled': isScheduled,
      'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
      'referenceId': referenceId,
      'metadata': metadata,
    };
  }

  String get formattedAmount {
    return 'R ${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  Map<String, dynamic> get receiptData {
    return {
      'transactionId': id,
      'date': createdAt.toIso8601String(),
      'sender': senderName,
      'receiver': receiverName,
      'amount': amount,
      'message': message,
      'status': status.name,
      'transferType': transferType?.name,
    };
  }
}

class TransferLimits {
  final String userId;
  final double dailyLimit;
  final double singleTransactionLimit;
  final double weeklyLimit;
  final double monthlyLimit;
  final DateTime lastResetDate;
  final double dailyUsed;
  final double weeklyUsed;
  final double monthlyUsed;

  const TransferLimits({
    required this.userId,
    this.dailyLimit = 5000.0,
    this.singleTransactionLimit = 2000.0,
    this.weeklyLimit = 25000.0,
    this.monthlyLimit = 100000.0,
    required this.lastResetDate,
    this.dailyUsed = 0.0,
    this.weeklyUsed = 0.0,
    this.monthlyUsed = 0.0,
  });

  factory TransferLimits.defaultLimits(String userId) {
    return TransferLimits(
      userId: userId,
      lastResetDate: _getStartOfDay(DateTime.now()),
    );
  }

  factory TransferLimits.fromMap(String userId, Map<String, dynamic> data) {
    return TransferLimits(
      userId: userId,
      dailyLimit: (data['dailyLimit'] ?? 5000.0).toDouble(),
      singleTransactionLimit: (data['singleTransactionLimit'] ?? 2000.0).toDouble(),
      weeklyLimit: (data['weeklyLimit'] ?? 25000.0).toDouble(),
      monthlyLimit: (data['monthlyLimit'] ?? 100000.0).toDouble(),
      lastResetDate: (data['lastResetDate'] as Timestamp).toDate(),
      dailyUsed: (data['dailyUsed'] ?? 0.0).toDouble(),
      weeklyUsed: (data['weeklyUsed'] ?? 0.0).toDouble(),
      monthlyUsed: (data['monthlyUsed'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dailyLimit': dailyLimit,
      'singleTransactionLimit': singleTransactionLimit,
      'weeklyLimit': weeklyLimit,
      'monthlyLimit': monthlyLimit,
      'lastResetDate': Timestamp.fromDate(lastResetDate),
      'dailyUsed': dailyUsed,
      'weeklyUsed': weeklyUsed,
      'monthlyUsed': monthlyUsed,
    };
  }

  TransferLimitResult canTransfer(double amount) {
    if (amount > singleTransactionLimit) {
      return TransferLimitResult(
        allowed: false,
        reason: TransferLimitReason.singleTransactionExceeded,
        maxAmount: singleTransactionLimit,
      );
    }

    final dailyRemaining = dailyLimit - dailyUsed;
    if (amount > dailyRemaining) {
      return TransferLimitResult(
        allowed: false,
        reason: TransferLimitReason.dailyLimitExceeded,
        maxAmount: dailyRemaining,
        currentUsage: dailyUsed,
        limit: dailyLimit,
      );
    }

    final weeklyRemaining = weeklyLimit - weeklyUsed;
    if (amount > weeklyRemaining) {
      return TransferLimitResult(
        allowed: false,
        reason: TransferLimitReason.weeklyLimitExceeded,
        maxAmount: weeklyRemaining,
        currentUsage: weeklyUsed,
        limit: weeklyLimit,
      );
    }

    final monthlyRemaining = monthlyLimit - monthlyUsed;
    if (amount > monthlyRemaining) {
      return TransferLimitResult(
        allowed: false,
        reason: TransferLimitReason.monthlyLimitExceeded,
        maxAmount: monthlyRemaining,
        currentUsage: monthlyUsed,
        limit: monthlyLimit,
      );
    }

    return TransferLimitResult(allowed: true, reason: TransferLimitReason.none);
  }

  double get dailyUsagePercentage => (dailyUsed / dailyLimit).clamp(0.0, 1.0);

  static DateTime _getStartOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  TransferLimits resetIfNeeded() {
    final now = DateTime.now();
    final today = _getStartOfDay(now);
    final lastReset = _getStartOfDay(lastResetDate);

    if (today.difference(lastReset).inDays >= 1) {
      return TransferLimits(
        userId: userId,
        dailyLimit: dailyLimit,
        singleTransactionLimit: singleTransactionLimit,
        weeklyLimit: weeklyLimit,
        monthlyLimit: monthlyLimit,
        lastResetDate: today,
        dailyUsed: 0,
        weeklyUsed: weeklyUsed,
        monthlyUsed: monthlyUsed,
      );
    }

    return this;
  }

  TransferLimits copyWithUsage(double amount) {
    return TransferLimits(
      userId: userId,
      dailyLimit: dailyLimit,
      singleTransactionLimit: singleTransactionLimit,
      weeklyLimit: weeklyLimit,
      monthlyLimit: monthlyLimit,
      lastResetDate: lastResetDate,
      dailyUsed: dailyUsed + amount,
      weeklyUsed: weeklyUsed + amount,
      monthlyUsed: monthlyUsed + amount,
    );
  }
}

class TransferLimitResult {
  final bool allowed;
  final TransferLimitReason reason;
  final double? maxAmount;
  final double? currentUsage;
  final double? limit;

  const TransferLimitResult({
    required this.allowed,
    required this.reason,
    this.maxAmount,
    this.currentUsage,
    this.limit,
  });

  String get errorMessage {
    switch (reason) {
      case TransferLimitReason.singleTransactionExceeded:
        return 'Single transaction limit exceeded. Maximum: R ${maxAmount?.toStringAsFixed(2)}';
      case TransferLimitReason.dailyLimitExceeded:
        return 'Daily limit reached. Remaining: R ${maxAmount?.toStringAsFixed(2)}';
      case TransferLimitReason.weeklyLimitExceeded:
        return 'Weekly limit reached. Remaining: R ${maxAmount?.toStringAsFixed(2)}';
      case TransferLimitReason.monthlyLimitExceeded:
        return 'Monthly limit reached. Remaining: R ${maxAmount?.toStringAsFixed(2)}';
      case TransferLimitReason.none:
        return '';
    }
  }
}

enum TransferLimitReason {
  none,
  singleTransactionExceeded,
  dailyLimitExceeded,
  weeklyLimitExceeded,
  monthlyLimitExceeded,
}

class ScheduledTransfer {
  final String id;
  final String senderId;
  final String receiverId;
  final double amount;
  final String? message;
  final TransferType transferType;
  final DateTime scheduledFor;
  final DateTime createdAt;
  final bool isActive;
  final int? recurringDayOfWeek;
  final DateTime? recurringEndDate;

  const ScheduledTransfer({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    this.message,
    required this.transferType,
    required this.scheduledFor,
    required this.createdAt,
    this.isActive = true,
    this.recurringDayOfWeek,
    this.recurringEndDate,
  });

  factory ScheduledTransfer.fromMap(String id, Map<String, dynamic> data) {
    return ScheduledTransfer(
      id: id,
      senderId: data['senderId'],
      receiverId: data['receiverId'],
      amount: (data['amount'] ?? 0.0).toDouble(),
      message: data['message'],
      transferType: TransferType.values.firstWhere(
        (e) => e.name == data['transferType'],
        orElse: () => TransferType.toChild,
      ),
      scheduledFor: (data['scheduledFor'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
      recurringDayOfWeek: data['recurringDayOfWeek'],
      recurringEndDate: data['recurringEndDate'] != null
          ? (data['recurringEndDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'message': message,
      'transferType': transferType.name,
      'scheduledFor': Timestamp.fromDate(scheduledFor),
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
      'recurringDayOfWeek': recurringDayOfWeek,
      'recurringEndDate': recurringEndDate != null
          ? Timestamp.fromDate(recurringEndDate!)
          : null,
    };
  }

  bool get shouldExecute => isActive && DateTime.now().isAfter(scheduledFor);
  bool get isOneTime => recurringDayOfWeek == null;
}