import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessProfileModel {
  final String id;
  final String vendorId;
  final String businessName;
  final String description;
  final String address;
  final String phone;
  final String email;
  final String logoUrl;
  final List<String> categories;
  final Map<String, String> businessHours;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusinessProfileModel({
    required this.id,
    required this.vendorId,
    required this.businessName,
    required this.description,
    required this.address,
    required this.phone,
    required this.email,
    required this.logoUrl,
    required this.categories,
    required this.businessHours,
    required this.isVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'businessName': businessName,
      'description': description,
      'address': address,
      'phone': phone,
      'email': email,
      'logoUrl': logoUrl,
      'categories': categories,
      'businessHours': businessHours,
      'isVerified': isVerified,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory BusinessProfileModel.fromMap(String id, Map<String, dynamic> map) {
    return BusinessProfileModel(
      id: id,
      vendorId: map['vendorId'] ?? '',
      businessName: map['businessName'] ?? '',
      description: map['description'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      logoUrl: map['logoUrl'] ?? '',
      categories: List<String>.from(map['categories'] ?? []),
      businessHours: Map<String, String>.from(map['businessHours'] ?? {}),
      isVerified: map['isVerified'] ?? false,
      createdAt: _parseTimestamp(map['createdAt']),
      updatedAt: _parseTimestamp(map['updatedAt']),
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

  BusinessProfileModel copyWith({
    String? id,
    String? vendorId,
    String? businessName,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? logoUrl,
    List<String>? categories,
    Map<String, String>? businessHours,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessProfileModel(
      id: id ?? this.id,
      vendorId: vendorId ?? this.vendorId,
      businessName: businessName ?? this.businessName,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      logoUrl: logoUrl ?? this.logoUrl,
      categories: categories ?? this.categories,
      businessHours: businessHours ?? this.businessHours,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
