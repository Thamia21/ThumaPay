// Allowance management models for the ThumaPay application
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum AllowanceFrequency {
  daily,
  weekly,
  monthly,
}

extension AllowanceFrequencyExtension on AllowanceFrequency {
  String get displayName {
    switch (this) {
      case AllowanceFrequency.daily:
        return 'Daily';
      case AllowanceFrequency.weekly:
        return 'Weekly';
      case AllowanceFrequency.monthly:
        return 'Monthly';
    }
  }

  int get daysInterval {
    switch (this) {
      case AllowanceFrequency.daily:
        return 1;
      case AllowanceFrequency.weekly:
        return 7;
      case AllowanceFrequency.monthly:
        return 30; // Approximate
    }
  }
}

enum AllowanceStatus {
  active,
  paused,
  cancelled,
  completed,
}

extension AllowanceStatusExtension on AllowanceStatus {
  String get displayName {
    switch (this) {
      case AllowanceStatus.active:
        return 'Active';
      case AllowanceStatus.paused:
        return 'Paused';
      case AllowanceStatus.cancelled:
        return 'Cancelled';
      case AllowanceStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case AllowanceStatus.active:
        return Colors.green;
      case AllowanceStatus.paused:
        return Colors.orange;
      case AllowanceStatus.cancelled:
        return Colors.red;
      case AllowanceStatus.completed:
        return Colors.blue;
    }
  }
}

enum AllowanceType {
  standard,
  rewardBased,
}

class Allowance {
  final String id;
  final String parentId;
  final String childId;
  final String childName;
  final double amount;
  final AllowanceFrequency frequency;
  final AllowanceStatus status;
  final AllowanceType type;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final DateTime? lastExecutedAt;
  final DateTime? nextExecutionDate;

  // Split configuration
  final double spendPercentage; // 0.0 to 1.0
  final double savePercentage; // 0.0 to 1.0

  // Reward-based settings
  final bool requiresApproval;
  final List<String> linkedChores; // Chore IDs

  const Allowance({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.childName,
    required this.amount,
    required this.frequency,
    required this.status,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    this.lastExecutedAt,
    this.nextExecutionDate,
    this.spendPercentage = 1.0,
    this.savePercentage = 0.0,
    this.requiresApproval = false,
    this.linkedChores = const [],
  });

  factory Allowance.fromMap(String id, Map<String, dynamic> map) {
    return Allowance(
      id: id,
      parentId: map['parentId'] ?? '',
      childId: map['childId'] ?? '',
      childName: map['childName'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      frequency: AllowanceFrequency.values.firstWhere(
        (e) => e.name == map['frequency'],
        orElse: () => AllowanceFrequency.weekly,
      ),
      status: AllowanceStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AllowanceStatus.active,
      ),
      type: AllowanceType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AllowanceType.standard,
      ),
      startDate: _parseTimestamp(map['startDate']),
      endDate: map['endDate'] != null ? _parseTimestamp(map['endDate']) : null,
      createdAt: _parseTimestamp(map['createdAt']),
      lastExecutedAt: map['lastExecutedAt'] != null
          ? _parseTimestamp(map['lastExecutedAt'])
          : null,
      nextExecutionDate: map['nextExecutionDate'] != null
          ? _parseTimestamp(map['nextExecutionDate'])
          : null,
      spendPercentage: (map['spendPercentage'] ?? 1.0).toDouble(),
      savePercentage: (map['savePercentage'] ?? 0.0).toDouble(),
      requiresApproval: map['requiresApproval'] ?? false,
      linkedChores: List<String>.from(map['linkedChores'] ?? []),
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'childId': childId,
      'childName': childName,
      'amount': amount,
      'frequency': frequency.name,
      'status': status.name,
      'type': type.name,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastExecutedAt': lastExecutedAt != null
          ? Timestamp.fromDate(lastExecutedAt!)
          : null,
      'nextExecutionDate': nextExecutionDate != null
          ? Timestamp.fromDate(nextExecutionDate!)
          : null,
      'spendPercentage': spendPercentage,
      'savePercentage': savePercentage,
      'requiresApproval': requiresApproval,
      'linkedChores': linkedChores,
    };
  }

  double get spendAmount => amount * spendPercentage;
  double get saveAmount => amount * savePercentage;

  bool get isDue {
    if (status != AllowanceStatus.active) return false;
    if (nextExecutionDate == null) return false;
    return DateTime.now().isAfter(nextExecutionDate!);
  }

  Allowance copyWith({
    String? id,
    String? parentId,
    String? childId,
    String? childName,
    double? amount,
    AllowanceFrequency? frequency,
    AllowanceStatus? status,
    AllowanceType? type,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? lastExecutedAt,
    DateTime? nextExecutionDate,
    double? spendPercentage,
    double? savePercentage,
    bool? requiresApproval,
    List<String>? linkedChores,
  }) {
    return Allowance(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      childName: childName ?? this.childName,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      status: status ?? this.status,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      lastExecutedAt: lastExecutedAt ?? this.lastExecutedAt,
      nextExecutionDate: nextExecutionDate ?? this.nextExecutionDate,
      spendPercentage: spendPercentage ?? this.spendPercentage,
      savePercentage: savePercentage ?? this.savePercentage,
      requiresApproval: requiresApproval ?? this.requiresApproval,
      linkedChores: linkedChores ?? this.linkedChores,
    );
  }
}

class AllowanceExecution {
  final String id;
  final String allowanceId;
  final String childId;
  final double totalAmount;
  final double spendAmount;
  final double saveAmount;
  final DateTime executedAt;
  final AllowanceExecutionStatus status;
  final String? failureReason;
  final String? transactionId;

  const AllowanceExecution({
    required this.id,
    required this.allowanceId,
    required this.childId,
    required this.totalAmount,
    required this.spendAmount,
    required this.saveAmount,
    required this.executedAt,
    required this.status,
    this.failureReason,
    this.transactionId,
  });

  factory AllowanceExecution.fromMap(String id, Map<String, dynamic> map) {
    return AllowanceExecution(
      id: id,
      allowanceId: map['allowanceId'] ?? '',
      childId: map['childId'] ?? '',
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      spendAmount: (map['spendAmount'] ?? 0.0).toDouble(),
      saveAmount: (map['saveAmount'] ?? 0.0).toDouble(),
      executedAt: _parseTimestamp(map['executedAt']),
      status: AllowanceExecutionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AllowanceExecutionStatus.pending,
      ),
      failureReason: map['failureReason'],
      transactionId: map['transactionId'],
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'allowanceId': allowanceId,
      'childId': childId,
      'totalAmount': totalAmount,
      'spendAmount': spendAmount,
      'saveAmount': saveAmount,
      'executedAt': Timestamp.fromDate(executedAt),
      'status': status.name,
      'failureReason': failureReason,
      'transactionId': transactionId,
    };
  }
}

enum AllowanceExecutionStatus {
  pending,
  completed,
  failed,
  skipped,
}

class Chore {
  final String id;
  final String parentId;
  final String childId;
  final String title;
  final String description;
  final double rewardAmount;
  final ChoreStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? approvedAt;
  final String? allowanceId; // Linked allowance for reward-based payments

  const Chore({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.title,
    required this.description,
    required this.rewardAmount,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.approvedAt,
    this.allowanceId,
  });

  factory Chore.fromMap(String id, Map<String, dynamic> map) {
    return Chore(
      id: id,
      parentId: map['parentId'] ?? '',
      childId: map['childId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      rewardAmount: (map['rewardAmount'] ?? 0.0).toDouble(),
      status: ChoreStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ChoreStatus.pending,
      ),
      createdAt: _parseTimestamp(map['createdAt']),
      completedAt: map['completedAt'] != null
          ? _parseTimestamp(map['completedAt'])
          : null,
      approvedAt: map['approvedAt'] != null
          ? _parseTimestamp(map['approvedAt'])
          : null,
      allowanceId: map['allowanceId'],
    );
  }

  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is String) {
      return DateTime.parse(timestamp);
    }
    return DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'parentId': parentId,
      'childId': childId,
      'title': title,
      'description': description,
      'rewardAmount': rewardAmount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'approvedAt': approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'allowanceId': allowanceId,
    };
  }
}

enum ChoreStatus {
  pending,
  completed,
  approved,
  rejected,
  paid,
}

extension ChoreStatusExtension on ChoreStatus {
  String get displayName {
    switch (this) {
      case ChoreStatus.pending:
        return 'Pending';
      case ChoreStatus.completed:
        return 'Completed';
      case ChoreStatus.approved:
        return 'Approved';
      case ChoreStatus.rejected:
        return 'Rejected';
      case ChoreStatus.paid:
        return 'Paid';
    }
  }

  Color get color {
    switch (this) {
      case ChoreStatus.pending:
        return Colors.grey;
      case ChoreStatus.completed:
        return Colors.blue;
      case ChoreStatus.approved:
        return Colors.green;
      case ChoreStatus.rejected:
        return Colors.red;
      case ChoreStatus.paid:
        return Colors.purple;
    }
  }
}