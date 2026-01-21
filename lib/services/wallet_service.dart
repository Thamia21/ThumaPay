import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart' as tx;

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _walletsCollection = 'wallets';
  final String _transactionsCollection = 'transactions';

  // Create a new wallet for a user
  Future<WalletModel> createWallet({
    required String userId,
    required String userName,
    double initialBalance = 0.0,
  }) async {
    final walletRef = _firestore.collection(_walletsCollection).doc();
    final wallet = WalletModel(
      id: walletRef.id,
      userId: userId,
      userName: userName,
      balance: initialBalance,
      createdAt: DateTime.now(),
    );

    await walletRef.set(wallet.toMap());
    return wallet;
  }

  // Get wallet by user ID
  Future<WalletModel?> getWallet(String userId) async {
    final snapshot = await _firestore
        .collection(_walletsCollection)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final doc = snapshot.docs.first;
      return WalletModel.fromMap(doc.id, doc.data());
    }
    return null;
  }

  // Get wallet by ID
  Future<WalletModel?> getWalletById(String walletId) async {
    final doc = await _firestore.collection(_walletsCollection).doc(walletId).get();
    if (doc.exists) {
      return WalletModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // Update wallet balance
  Future<void> updateBalance(String walletId, double newBalance) async {
    await _firestore.collection(_walletsCollection).doc(walletId).update({
      'balance': newBalance,
      'lastTransactionAt': FieldValue.serverTimestamp(),
    });
  }

  // Add to balance (for deposits)
  Future<void> addToBalance(String walletId, double amount) async {
    final wallet = await getWalletById(walletId);
    if (wallet != null) {
      await updateBalance(walletId, wallet.balance + amount);
    }
  }

  // Deduct from balance (for transfers/withdrawals)
  Future<bool> deductFromBalance(String walletId, double amount) async {
    final wallet = await getWalletById(walletId);
    if (wallet == null || wallet.balance < amount) {
      return false;
    }

    await updateBalance(walletId, wallet.balance - amount);
    return true;
  }

  // Check if wallet has sufficient balance
  Future<bool> hasSufficientBalance(String walletId, double amount) async {
    final wallet = await getWalletById(walletId);
    return wallet != null && wallet.balance >= amount;
  }

  // Transfer money between wallets
  Future<bool> transferBetweenWallets({
    required String fromWalletId,
    required String toWalletId,
    required double amount,
    String? message,
    tx.TransferType transferType = tx.TransferType.toExternal,
  }) async {
    final fromWallet = await getWalletById(fromWalletId);
    final toWallet = await getWalletById(toWalletId);

    if (fromWallet == null || toWallet == null || fromWallet.balance < amount) {
      return false;
    }

    // Deduct from sender
    await updateBalance(fromWalletId, fromWallet.balance - amount);

    // Add to receiver
    await updateBalance(toWalletId, toWallet.balance + amount);

    // Record transaction
    final transactionId = _firestore.collection(_transactionsCollection).doc().id;
    final transaction = tx.Transaction(
      id: transactionId,
      senderId: fromWallet.userId,
      senderName: fromWallet.userName,
      receiverId: toWallet.userId,
      receiverName: toWallet.userName,
      amount: amount,
      message: message,
      type: tx.TransactionType.transfer,
      status: tx.TransactionStatus.completed,
      transferType: transferType,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );

    await _firestore.collection(_transactionsCollection).doc(transactionId).set(transaction.toMap());

    return true;
  }

  // Get recent transactions for a wallet
  Future<List<tx.Transaction>> getRecentTransactions(String userId, {int limit = 10}) async {
    final snapshot = await _firestore
        .collection(_transactionsCollection)
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => tx.Transaction.fromMap(doc.id, doc.data())).toList();
  }

  // Get wallet balance
  Future<double> getBalance(String walletId) async {
    final wallet = await getWalletById(walletId);
    return wallet?.balance ?? 0.0;
  }

  // Get wallet by user ID (create if doesn't exist)
  Future<WalletModel> getOrCreateWallet(String userId, String userName) async {
    final existingWallet = await getWallet(userId);
    if (existingWallet != null) {
      return existingWallet;
    }

    return await createWallet(userId: userId, userName: userName);
  }
}