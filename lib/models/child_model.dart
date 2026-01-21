import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class ChildModel {
  final String id;
  final String parentId;
  final String name;
  final int age;
  final String? profilePhoto;
  final double balance;
  final bool isFrozen;
  final Map<String, dynamic> spendingLimits;
  final Map<String, dynamic> categoryRestrictions;
  final double? savingsGoal;
  final double? savingsCurrent;
  final DateTime createdAt;

  ChildModel({
    required this.id,
    required this.parentId,
    required this.name,
    required this.age,
    this.profilePhoto,
    this.balance = 0.0,
    this.isFrozen = false,
    this.spendingLimits = const {'daily': 0, 'weekly': 0},
    this.categoryRestrictions = const {},
    this.savingsGoal,
    this.savingsCurrent = 0.0,
    required this.createdAt,
  });

  factory ChildModel.fromMap(String id, Map<String, dynamic> map) {
    return ChildModel(
      id: id,
      parentId: map['parentId'] ?? '',
      name: map['name'] ?? '',
      age: map['age'] ?? 0,
      profilePhoto: map['profilePhoto'],
      balance: (map['balance'] ?? 0.0).toDouble(),
      isFrozen: map['isFrozen'] ?? false,
      spendingLimits: Map<String, dynamic>.from(map['spendingLimits'] ?? {}),
      categoryRestrictions: Map<String, dynamic>.from(map['categoryRestrictions'] ?? {}),
      savingsGoal: map['savingsGoal'],
      savingsCurrent: (map['savingsCurrent'] ?? 0.0).toDouble(),
      createdAt: _parseTimestamp(map['createdAt']),
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
      'name': name,
      'age': age,
      'profilePhoto': profilePhoto,
      'balance': balance,
      'isFrozen': isFrozen,
      'spendingLimits': spendingLimits,
      'categoryRestrictions': categoryRestrictions,
      'savingsGoal': savingsGoal,
      'savingsCurrent': savingsCurrent,
      'createdAt': createdAt,
    };
  }

  // Helper to get initials from name
  String get initials {
    List<String> parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  // Category constants
  static const List<String> allowedCategories = [
    'Food & Drinks',
    'Stationery',
    'Transportation',
    'Entertainment',
    'Clothing',
    'Electronics',
    'Sports',
    'Books',
    'Gaming',
    'Other'
  ];
}

