import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new transaction
  Future<String> createTransaction(TransactionModel transaction) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('transactions').add(transaction.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create transaction: $e');
    }
  }

  // Get transactions for a vendor
  Stream<List<TransactionModel>> getVendorTransactions(String vendorId) {
    return _firestore
        .collection('transactions')
        .where('vendorId', isEqualTo: vendorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Get transactions for a customer
  Stream<List<TransactionModel>> getCustomerTransactions(String customerId) {
    return _firestore
        .collection('transactions')
        .where('customerId', isEqualTo: customerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  // Update transaction status
  Future<void> updateTransactionStatus(
      String transactionId, TransactionStatus status) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'status': status.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update transaction status: $e');
    }
  }

  // Rollback transaction
  Future<void> rollbackTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).update({
        'isRolledBack': true,
        'status': TransactionStatus.cancelled.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to rollback transaction: $e');
    }
  }

  // Get transaction by ID
  Future<TransactionModel?> getTransactionById(String transactionId) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('transactions').doc(transactionId).get();
      if (doc.exists) {
        return TransactionModel.fromMap(
            doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get transaction: $e');
    }
  }
}
