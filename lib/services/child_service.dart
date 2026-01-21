import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';

class ChildService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _childrenCollection = 'children';

  // Create a new child
  Future<ChildModel> createChild({
    required String parentId,
    required String name,
    required int age,
    String? profilePhoto,
  }) async {
    final childRef = _firestore.collection(_childrenCollection).doc();
    final child = ChildModel(
      id: childRef.id,
      parentId: parentId,
      name: name,
      age: age,
      profilePhoto: profilePhoto,
      balance: 0.0,
      isFrozen: false,
      spendingLimits: {'daily': 0, 'weekly': 0},
      categoryRestrictions: {},
      savingsGoal: null,
      savingsCurrent: 0.0,
      createdAt: DateTime.now(),
    );

    await childRef.set(child.toMap());
    return child;
  }

  // Get all children for a parent
  Future<List<ChildModel>> getChildren(String parentId) async {
    final snapshot = await _firestore
        .collection(_childrenCollection)
        .where('parentId', isEqualTo: parentId)
        .get();

    return snapshot.docs.map((doc) => ChildModel.fromMap(doc.id, doc.data())).toList();
  }

  // Get a single child by ID
  Future<ChildModel?> getChild(String childId) async {
    final doc = await _firestore.collection(_childrenCollection).doc(childId).get();
    if (doc.exists) {
      return ChildModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // Update child information
  Future<void> updateChild(String childId, Map<String, dynamic> data) async {
    await _firestore.collection(_childrenCollection).doc(childId).update(data);
  }

  // Update child balance
  Future<void> updateBalance(String childId, double newBalance) async {
    await _firestore.collection(_childrenCollection).doc(childId).update({
      'balance': newBalance,
    });
  }

  // Add to balance (for deposits)
  Future<void> addToBalance(String childId, double amount) async {
    final child = await getChild(childId);
    if (child != null) {
      await updateBalance(childId, child.balance + amount);
    }
  }

  // Deduct from balance (for spending/transfers)
  Future<bool> deductFromBalance(String childId, double amount) async {
    final child = await getChild(childId);
    if (child == null) return false;
    
    if (child.balance < amount) return false;
    
    await updateBalance(childId, child.balance - amount);
    return true;
  }

  // Freeze/unfreeze child wallet
  Future<void> toggleFreeze(String childId, bool freeze) async {
    await _firestore.collection(_childrenCollection).doc(childId).update({
      'isFrozen': freeze,
    });
  }

  // Set spending limits
  Future<void> setSpendingLimits({
    required String childId,
    required double dailyLimit,
    required double weeklyLimit,
  }) async {
    await _firestore.collection(_childrenCollection).doc(childId).update({
      'spendingLimits': {
        'daily': dailyLimit,
        'weekly': weeklyLimit,
      },
    });
  }

  // Set category restrictions
  Future<void> setCategoryRestrictions({
    required String childId,
    required Map<String, bool> restrictions,
  }) async {
    await _firestore.collection(_childrenCollection).doc(childId).update({
      'categoryRestrictions': restrictions,
    });
  }

  // Set savings goal
  Future<void> setSavingsGoal({
    required String childId,
    required double goalAmount,
  }) async {
    await _firestore.collection(_childrenCollection).doc(childId).update({
      'savingsGoal': goalAmount,
    });
  }

  // Add to savings
  Future<void> addToSavings(String childId, double amount) async {
    final child = await getChild(childId);
    if (child != null) {
      await _firestore.collection(_childrenCollection).doc(childId).update({
        'savingsCurrent': (child.savingsCurrent ?? 0.0) + amount,
      });
    }
  }

  // Delete a child
  Future<void> deleteChild(String childId) async {
    await _firestore.collection(_childrenCollection).doc(childId).delete();
  }

  // Transfer money from parent to child
  Future<bool> transferToChild({
    required String parentId,
    required String childId,
    required double amount,
    String? message,
  }) async {
    final child = await getChild(childId);
    if (child == null || child.isFrozen) return false;
    
    await addToBalance(childId, amount);
    
    // Record transaction
    await _firestore.collection('transactions').add({
      'type': 'transfer',
      'fromType': 'parent',
      'fromId': parentId,
      'toType': 'child',
      'toId': childId,
      'amount': amount,
      'message': message,
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    return true;
  }

  // Check if transaction exceeds daily limit
  Future<bool> checkDailyLimit(String childId, double amount) async {
    final child = await getChild(childId);
    if (child == null) return true;
    
    final dailyLimit = (child.spendingLimits['daily'] ?? 0.0);
    if (dailyLimit == 0) return true; // No limit set
    
    // Get today's transactions for this child
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    final snapshot = await _firestore
        .collection('transactions')
        .where('toId', isEqualTo: childId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();
    
    double todaySpent = 0;
    for (var doc in snapshot.docs) {
      todaySpent += (doc.data()['amount'] ?? 0.0);
    }
    
    return (todaySpent + amount) <= dailyLimit;
  }
}

