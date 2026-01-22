import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/customer_card_model.dart';

class CustomerCardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new customer card
  Future<String> createCustomerCard(CustomerCardModel card) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('customerCards').add(card.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create customer card: $e');
    }
  }

  // Get customer card by card number
  Future<CustomerCardModel?> getCustomerCardByNumber(String cardNumber) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('customerCards')
          .where('cardNumber', isEqualTo: cardNumber)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return CustomerCardModel.fromMap(snapshot.docs.first.id,
            snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get customer card: $e');
    }
  }

  // Get customer cards by parent ID
  Stream<List<CustomerCardModel>> getCustomerCardsByParentId(String parentId) {
    return _firestore
        .collection('customerCards')
        .where('parentId', isEqualTo: parentId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CustomerCardModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Update customer card balance
  Future<void> updateCardBalance(String cardId, double newBalance) async {
    try {
      await _firestore.collection('customerCards').doc(cardId).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update card balance: $e');
    }
  }

  // Add funds to card
  Future<void> addFundsToCard(String cardId, double amount) async {
    try {
      await _firestore.collection('customerCards').doc(cardId).update({
        'balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add funds to card: $e');
    }
  }

  // Deduct funds from card
  Future<bool> deductFundsFromCard(String cardId, double amount) async {
    try {
      DocumentReference cardRef =
          _firestore.collection('customerCards').doc(cardId);
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(cardRef);
        if (!snapshot.exists) {
          throw Exception('Customer card not found');
        }

        CustomerCardModel card = CustomerCardModel.fromMap(
            snapshot.id, snapshot.data() as Map<String, dynamic>);

        if (!card.isActive) {
          throw Exception('Card is inactive');
        }

        if (card.balance < amount) {
          throw Exception('Insufficient funds on card');
        }

        transaction.update(cardRef, {
          'balance': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      throw Exception('Failed to deduct funds from card: $e');
    }
  }

  // Deactivate card
  Future<void> deactivateCard(String cardId) async {
    try {
      await _firestore.collection('customerCards').doc(cardId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to deactivate card: $e');
    }
  }

  // Update spending limit
  Future<void> updateSpendingLimit(String cardId, double spendingLimit) async {
    try {
      await _firestore.collection('customerCards').doc(cardId).update({
        'spendingLimit': spendingLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update spending limit: $e');
    }
  }
}
