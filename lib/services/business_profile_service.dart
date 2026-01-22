import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/business_profile_model.dart';

class BusinessProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new business profile
  Future<String> createBusinessProfile(BusinessProfileModel profile) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('businessProfiles').add(profile.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create business profile: $e');
    }
  }

  // Get business profile by vendor ID
  Future<BusinessProfileModel?> getBusinessProfileByVendorId(
      String vendorId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('businessProfiles')
          .where('vendorId', isEqualTo: vendorId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return BusinessProfileModel.fromMap(snapshot.docs.first.id,
            snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get business profile: $e');
    }
  }

  // Update business profile
  Future<void> updateBusinessProfile(
      String profileId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore
          .collection('businessProfiles')
          .doc(profileId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update business profile: $e');
    }
  }

  // Delete business profile
  Future<void> deleteBusinessProfile(String profileId) async {
    try {
      await _firestore.collection('businessProfiles').doc(profileId).delete();
    } catch (e) {
      throw Exception('Failed to delete business profile: $e');
    }
  }
}
