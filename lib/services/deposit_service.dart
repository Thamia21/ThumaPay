// Deposit service for handling payment processing and deposit operations
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/deposit_model.dart';
import '../models/transaction_model.dart' as tx;
import '../models/wallet_model.dart';
import 'wallet_service.dart';
import 'security_service.dart';

class DepositService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WalletService _walletService = WalletService();
  final SecurityService _securityService = SecurityService();
  final String _depositsCollection = 'deposits';
  final String _autoDepositsCollection = 'auto_deposits';
  final String _alertsCollection = 'alerts';
  final _uuid = const Uuid();

  // Process a deposit
  Future<DepositResult> processDeposit({
    required String userId,
    required double amount,
    required DepositMethod method,
    Map<String, dynamic>? paymentDetails,
    String? idempotencyKey,
  }) async {
    // Validate amount
    if (amount <= 0 || amount > 100000) {
      return DepositResult.failure('Invalid deposit amount');
    }

    // Check idempotency
    if (idempotencyKey != null) {
      final existingId = await _checkIdempotency(idempotencyKey);
      if (existingId != null) {
        final existingTx = await _firestore.collection('transactions').doc(existingId).get();
        if (existingTx.exists) {
          final transaction = tx.Transaction.fromMap(existingTx.id, existingTx.data()!);
          return DepositResult.success(transaction);
        }
      }
    }

    // Get user's wallet
    final wallet = await _walletService.getWallet(userId);
    if (wallet == null) {
      return DepositResult.failure('Wallet not found');
    }

    // Validate payment method details
    final validation = await _validatePaymentMethod(method, paymentDetails);
    if (!validation.isValid) {
      return DepositResult.failure(validation.errorMessage);
    }

    // Process payment (in real app, integrate with payment gateway)
    final paymentResult = await _processPayment(amount, method, paymentDetails);
    if (!paymentResult.success) {
      return DepositResult.failure(paymentResult.error ?? 'Payment failed');
    }

    // Create transaction
    final transactionId = _uuid.v4();
    final transaction = tx.Transaction(
      id: transactionId,
      senderId: 'external', // External source
      senderName: method.displayName,
      receiverId: userId,
      receiverName: wallet.userName,
      amount: amount,
      type: tx.TransactionType.deposit,
      status: tx.TransactionStatus.completed,
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      metadata: {
        'depositMethod': method.name,
        'paymentReference': paymentResult.reference,
        'idempotencyKey': idempotencyKey,
        ...?paymentDetails,
      },
    );

    // Save transaction
    await _firestore.collection('transactions').doc(transactionId).set(transaction.toMap());

    // Update wallet balance
    await _walletService.addToBalance(wallet.id, amount);

    // Store idempotency key
    if (idempotencyKey != null) {
      await _storeIdempotencyKey(idempotencyKey, transactionId);
    }

    // Check for alerts
    await _checkAlerts(userId, wallet.balance + amount);

    return DepositResult.success(transaction);
  }

  // Get deposit history
  Future<List<tx.Transaction>> getDepositHistory(String userId, {
    DateTime? startDate,
    DateTime? endDate,
    DepositMethod? method,
  }) async {
    Query query = _firestore
        .collection('transactions')
        .where('receiverId', isEqualTo: userId)
        .where('type', isEqualTo: tx.TransactionType.deposit.name)
        .orderBy('createdAt', descending: true);

    if (startDate != null) {
      query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    }
    if (endDate != null) {
      query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    final snapshot = await query.get();
    final transactions = snapshot.docs
        .map((doc) => tx.Transaction.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();

    // Filter by method if specified
    if (method != null) {
      return transactions.where((t) =>
          t.metadata?['depositMethod'] == method.name).toList();
    }

    return transactions;
  }

  // Auto deposit management
  Future<String> createAutoDeposit({
    required String userId,
    required double amount,
    required DepositMethod method,
    required int dayOfMonth,
    Map<String, dynamic>? paymentMetadata,
    DateTime? endDate,
  }) async {
    final autoDeposit = AutoDeposit(
      id: _uuid.v4(),
      userId: userId,
      amount: amount,
      method: method,
      dayOfMonth: dayOfMonth,
      createdAt: DateTime.now(),
      paymentMetadata: paymentMetadata,
      endDate: endDate,
    );

    await _firestore.collection(_autoDepositsCollection).doc(autoDeposit.id).set(autoDeposit.toMap());
    return autoDeposit.id;
  }

  Future<List<AutoDeposit>> getAutoDeposits(String userId) async {
    final snapshot = await _firestore
        .collection(_autoDepositsCollection)
        .where('userId', isEqualTo: userId)
        .get();

    return snapshot.docs
        .map((doc) => AutoDeposit.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<void> executeAutoDeposits() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(_autoDepositsCollection)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      final autoDeposit = AutoDeposit.fromMap(doc.id, doc.data());
      if (autoDeposit.shouldExecuteToday) {
        final result = await processDeposit(
          userId: autoDeposit.userId,
          amount: autoDeposit.amount,
          method: autoDeposit.method,
          paymentDetails: autoDeposit.paymentMetadata,
          idempotencyKey: 'auto_${autoDeposit.id}_${now.year}_${now.month}',
        );

        if (result.success) {
          // Update last executed
          await _firestore.collection(_autoDepositsCollection).doc(autoDeposit.id).update({
            'lastExecutedAt': Timestamp.fromDate(now),
          });
        }
      }
    }
  }

  // Alert management
  Future<String> createAlert({
    required String userId,
    required AlertType type,
    required double threshold,
  }) async {
    final alert = Alert(
      id: _uuid.v4(),
      userId: userId,
      type: type,
      threshold: threshold,
      createdAt: DateTime.now(),
    );

    await _firestore.collection(_alertsCollection).doc(alert.id).set(alert.toMap());
    return alert.id;
  }

  Future<List<Alert>> getAlerts(String userId) async {
    final snapshot = await _firestore
        .collection(_alertsCollection)
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => Alert.fromMap(doc.id, doc.data()))
        .toList();
  }

  // Generate deposit suggestions based on usage patterns
  Future<List<DepositSuggestion>> getDepositSuggestions(String userId) async {
    final suggestions = <DepositSuggestion>[];

    // Get recent transactions
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final transactions = await _firestore
        .collection('transactions')
        .where('senderId', isEqualTo: userId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(thirtyDaysAgo))
        .get();

    final txList = transactions.docs
        .map((doc) => tx.Transaction.fromMap(doc.id, doc.data()))
        .toList();

    // Calculate average monthly spending
    final totalSpent = txList
        .where((t) => t.type == tx.TransactionType.transfer)
        .fold(0.0, (sum, t) => sum + t.amount);

    final avgMonthlySpending = totalSpent / 30 * 30; // Rough estimate

    // Suggest based on spending patterns
    if (avgMonthlySpending > 0) {
      suggestions.add(DepositSuggestion(
        amount: avgMonthlySpending,
        reason: 'Based on your average monthly spending',
        basedOnDate: DateTime.now(),
      ));

      // Suggest 20% more for buffer
      suggestions.add(DepositSuggestion(
        amount: avgMonthlySpending * 1.2,
        reason: '20% buffer above your average spending',
        basedOnDate: DateTime.now(),
      ));
    }

    return suggestions;
  }

  // Generate receipt (in real app, would generate PDF)
  Future<String> generateReceipt(String transactionId) async {
    final doc = await _firestore.collection('transactions').doc(transactionId).get();
    if (!doc.exists) throw Exception('Transaction not found');

    final transaction = tx.Transaction.fromMap(doc.id, doc.data()!);
    final receiptData = transaction.receiptData;

    // In real app, generate PDF here
    // For now, return JSON string
    return receiptData.toString();
  }

  // Private methods
  Future<PaymentResult> _processPayment(double amount, DepositMethod method, Map<String, dynamic>? details) async {
    // In real implementation, integrate with payment gateway
    // For demo, simulate success
    await Future.delayed(const Duration(seconds: 2)); // Simulate processing time

    return PaymentResult(
      success: true,
      reference: 'PAY_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<ValidationResult> _validatePaymentMethod(DepositMethod method, Map<String, dynamic>? details) async {
    switch (method) {
      case DepositMethod.bankCard:
        if (details?['cardNumber'] == null || details?['expiry'] == null) {
          return ValidationResult.invalid('Card details required');
        }
        // Validate card format, expiry, etc.
        break;
      case DepositMethod.eft:
        if (details?['accountNumber'] == null || details?['bankCode'] == null) {
          return ValidationResult.invalid('Bank details required');
        }
        break;
      case DepositMethod.mobileMoney:
        if (details?['phoneNumber'] == null) {
          return ValidationResult.invalid('Phone number required');
        }
        break;
      case DepositMethod.qrCode:
        // QR code validation
        break;
    }
    return ValidationResult.valid();
  }

  Future<String?> _checkIdempotency(String key) async {
    final doc = await _firestore.collection('idempotency_keys').doc(key).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['transactionId'];
    }
    return null;
  }

  Future<void> _storeIdempotencyKey(String key, String transactionId) async {
    await _firestore.collection('idempotency_keys').doc(key).set({
      'transactionId': transactionId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> _checkAlerts(String userId, double newBalance) async {
    final alerts = await getAlerts(userId);
    for (final alert in alerts) {
      if (alert.type == AlertType.lowBalance && newBalance < alert.threshold) {
        // Trigger alert (in real app, send notification)
        await _firestore.collection(_alertsCollection).doc(alert.id).update({
          'lastTriggeredAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }
}

class DepositResult {
  final bool success;
  final tx.Transaction? transaction;
  final String? error;

  DepositResult.success(this.transaction)
      : success = true,
        error = null;

  DepositResult.failure(this.error)
      : success = false,
        transaction = null;
}

class PaymentResult {
  final bool success;
  final String? reference;
  final String? error;

  PaymentResult({required this.success, this.reference, this.error});
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  ValidationResult.valid()
      : isValid = true,
        errorMessage = null;

  ValidationResult.invalid(this.errorMessage)
      : isValid = false;
}