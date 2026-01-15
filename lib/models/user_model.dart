import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    required this.createdAt,
  });

  // Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'createdAt': createdAt,
    };
  }

  // Create from Firestore document
  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    log('Firestore user raw data: $map');
    return UserModel(
      uid: uid,
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? '',
      createdAt: _parseTimestamp(map['createdAt']),
    );
  }

  // Safe timestamp parsing
  static DateTime _parseTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    } else if (timestamp is DateTime) {
      return timestamp;
    } else if (timestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    } else {
      log('Unrecognized timestamp type: ${timestamp?.runtimeType.toString() ?? 'null'}');
      return DateTime.now(); // fallback
    }
  }

  // User roles enum
  static const String parent = 'parent';
  static const String vendor = 'vendor';
  static const String admin = 'admin';

  static List<String> get availableRoles => [parent, vendor];
}
