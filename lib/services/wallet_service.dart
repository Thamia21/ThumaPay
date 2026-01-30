import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new wallet
  Future<String> createWallet(WalletModel wallet) async {
    try {
      DocumentReference docRef =
          await _firestore.collection('wallets').add(wallet.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create wallet: $e');
    }
  }

  // Get wallet by user ID
  Future<WalletModel?> getWalletByUserId(String userId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('wallets')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return WalletModel.fromMap(snapshot.docs.first.id,
            snapshot.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get wallet: $e');
    }
  }

  // Update wallet balance
  Future<void> updateWalletBalance(String walletId, double newBalance) async {
    try {
      await _firestore.collection('wallets').doc(walletId).update({
        'balance': newBalance,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update wallet balance: $e');
    }
  }

  // Add funds to wallet
  Future<void> addFunds(String walletId, double amount) async {
    try {
      await _firestore.collection('wallets').doc(walletId).update({
        'balance': FieldValue.increment(amount),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add funds: $e');
    }
  }

  // Deduct funds from wallet with spending limit check
  Future<bool> deductFunds(String walletId, double amount,
      {double? spendingLimit}) async {
    try {
      DocumentReference walletRef =
          _firestore.collection('wallets').doc(walletId);
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(walletRef);
        if (!snapshot.exists) {
          throw Exception('Wallet not found');
        }

        WalletModel wallet = WalletModel.fromMap(
            snapshot.id, snapshot.data() as Map<String, dynamic>);

        if (!wallet.isActive) {
          throw Exception('Wallet is inactive');
        }

        if (wallet.balance < amount) {
          throw Exception('Insufficient funds');
        }

        if (spendingLimit != null && amount > spendingLimit) {
          throw Exception('Amount exceeds spending limit');
        }

        transaction.update(walletRef, {
          'balance': FieldValue.increment(-amount),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      throw Exception('Failed to deduct funds: $e');
    }
  }

  // Update spending limit
  Future<void> updateSpendingLimit(
      String walletId, double? spendingLimit) async {
    try {
      await _firestore.collection('wallets').doc(walletId).update({
        'spendingLimit': spendingLimit,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update spending limit: $e');
    }
  }
}
