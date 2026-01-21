// Allowance service for managing automated allowances and rewards
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/allowance_model.dart';
import '../models/child_model.dart';
import '../services/child_service.dart';
import '../services/auth_service.dart';

class AllowanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ChildService _childService = ChildService();
  final AuthService _authService = AuthService();
  final _uuid = const Uuid();

  final String _allowancesCollection = 'allowances';
  final String _executionsCollection = 'allowance_executions';
  final String _choresCollection = 'chores';

  // Create a new allowance
  Future<String> createAllowance({
    required String childId,
    required String childName,
    required double amount,
    required AllowanceFrequency frequency,
    required AllowanceType type,
    double spendPercentage = 1.0,
    double savePercentage = 0.0,
    bool requiresApproval = false,
    List<String> linkedChores = const [],
    DateTime? endDate,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Validate percentages
    if (spendPercentage + savePercentage != 1.0) {
      throw Exception('Spend and save percentages must add up to 100%');
    }

    // Validate amount
    if (amount <= 0) {
      throw Exception('Allowance amount must be greater than 0');
    }

    final allowanceId = _uuid.v4();
    final now = DateTime.now();
    final nextExecution = _calculateNextExecution(now, frequency);

    final allowance = Allowance(
      id: allowanceId,
      parentId: user.uid,
      childId: childId,
      childName: childName,
      amount: amount,
      frequency: frequency,
      status: AllowanceStatus.active,
      type: type,
      startDate: now,
      endDate: endDate,
      createdAt: now,
      nextExecutionDate: nextExecution,
      spendPercentage: spendPercentage,
      savePercentage: savePercentage,
      requiresApproval: requiresApproval,
      linkedChores: linkedChores,
    );

    await _firestore.collection(_allowancesCollection).doc(allowanceId).set(allowance.toMap());
    return allowanceId;
  }

  // Get all allowances for a parent
  Future<List<Allowance>> getAllowances(String parentId) async {
    final snapshot = await _firestore
        .collection(_allowancesCollection)
        .where('parentId', isEqualTo: parentId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Allowance.fromMap(doc.id, doc.data())).toList();
  }

  // Get allowances for a specific child
  Future<List<Allowance>> getChildAllowances(String childId) async {
    final snapshot = await _firestore
        .collection(_allowancesCollection)
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Allowance.fromMap(doc.id, doc.data())).toList();
  }

  // Update allowance status
  Future<void> updateAllowanceStatus(String allowanceId, AllowanceStatus status) async {
    final updateData = {
      'status': status.name,
      'lastExecutedAt': status == AllowanceStatus.active
          ? null // Reset for reactivation
          : FieldValue.serverTimestamp(),
    };

    if (status == AllowanceStatus.active) {
      // Recalculate next execution date
      final allowance = await getAllowance(allowanceId);
      if (allowance != null) {
        final nextExecution = _calculateNextExecution(DateTime.now(), allowance.frequency);
        updateData['nextExecutionDate'] = Timestamp.fromDate(nextExecution);
      }
    }

    await _firestore.collection(_allowancesCollection).doc(allowanceId).update(updateData);
  }

  // Update allowance configuration
  Future<void> updateAllowance(String allowanceId, {
    double? amount,
    AllowanceFrequency? frequency,
    double? spendPercentage,
    double? savePercentage,
    DateTime? endDate,
  }) async {
    final updateData = <String, dynamic>{};

    if (amount != null) updateData['amount'] = amount;
    if (frequency != null) updateData['frequency'] = frequency.name;
    if (spendPercentage != null) updateData['spendPercentage'] = spendPercentage;
    if (savePercentage != null) updateData['savePercentage'] = savePercentage;
    if (endDate != null) updateData['endDate'] = Timestamp.fromDate(endDate);

    // Recalculate next execution if frequency changed
    if (frequency != null) {
      final nextExecution = _calculateNextExecution(DateTime.now(), frequency);
      updateData['nextExecutionDate'] = Timestamp.fromDate(nextExecution);
    }

    await _firestore.collection(_allowancesCollection).doc(allowanceId).update(updateData);
  }

  // Delete allowance
  Future<void> deleteAllowance(String allowanceId) async {
    await _firestore.collection(_allowancesCollection).doc(allowanceId).delete();
  }

  // Get single allowance
  Future<Allowance?> getAllowance(String allowanceId) async {
    final doc = await _firestore.collection(_allowancesCollection).doc(allowanceId).get();
    if (doc.exists) {
      return Allowance.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // Execute allowance payment
  Future<AllowanceExecutionResult> executeAllowance(String allowanceId) async {
    final allowance = await getAllowance(allowanceId);
    if (allowance == null) {
      return AllowanceExecutionResult.failure('Allowance not found');
    }

    if (allowance.status != AllowanceStatus.active) {
      return AllowanceExecutionResult.failure('Allowance is not active');
    }

    if (!allowance.isDue) {
      return AllowanceExecutionResult.failure('Allowance is not due yet');
    }

    // Check if already executed today (idempotency)
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final executions = await _firestore
        .collection(_executionsCollection)
        .where('allowanceId', isEqualTo: allowanceId)
        .where('executedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .get();

    if (executions.docs.isNotEmpty) {
      return AllowanceExecutionResult.failure('Allowance already executed today');
    }

    try {
      // Calculate amounts
      final spendAmount = allowance.spendAmount;
      final saveAmount = allowance.saveAmount;

      // Add to child's spend wallet
      if (spendAmount > 0) {
        await _childService.addToBalance(allowance.childId, spendAmount);
      }

      // Add to child's savings
      if (saveAmount > 0) {
        await _childService.addToSavings(allowance.childId, saveAmount);
      }

      // Record execution
      final executionId = _uuid.v4();
      final execution = AllowanceExecution(
        id: executionId,
        allowanceId: allowanceId,
        childId: allowance.childId,
        totalAmount: allowance.amount,
        spendAmount: spendAmount,
        saveAmount: saveAmount,
        executedAt: DateTime.now(),
        status: AllowanceExecutionStatus.completed,
      );

      await _firestore.collection(_executionsCollection).doc(executionId).set(execution.toMap());

      // Update allowance's last execution and next execution dates
      final nextExecution = _calculateNextExecution(DateTime.now(), allowance.frequency);
      await _firestore.collection(_allowancesCollection).doc(allowanceId).update({
        'lastExecutedAt': FieldValue.serverTimestamp(),
        'nextExecutionDate': Timestamp.fromDate(nextExecution),
      });

      return AllowanceExecutionResult.success(execution);
    } catch (e) {
      // Record failed execution
      final executionId = _uuid.v4();
      final execution = AllowanceExecution(
        id: executionId,
        allowanceId: allowanceId,
        childId: allowance.childId,
        totalAmount: allowance.amount,
        spendAmount: allowance.spendAmount,
        saveAmount: allowance.saveAmount,
        executedAt: DateTime.now(),
        status: AllowanceExecutionStatus.failed,
        failureReason: e.toString(),
      );

      await _firestore.collection(_executionsCollection).doc(executionId).set(execution.toMap());
      return AllowanceExecutionResult.failure('Execution failed: $e');
    }
  }

  // Execute all due allowances (called by background service)
  Future<void> executeDueAllowances() async {
    final now = DateTime.now();
    final snapshot = await _firestore
        .collection(_allowancesCollection)
        .where('status', isEqualTo: AllowanceStatus.active.name)
        .where('nextExecutionDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    for (final doc in snapshot.docs) {
      final allowance = Allowance.fromMap(doc.id, doc.data());
      if (allowance.isDue) {
        await executeAllowance(allowance.id);
      }
    }
  }

  // Get allowance execution history
  Future<List<AllowanceExecution>> getAllowanceHistory(String allowanceId) async {
    final snapshot = await _firestore
        .collection(_executionsCollection)
        .where('allowanceId', isEqualTo: allowanceId)
        .orderBy('executedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => AllowanceExecution.fromMap(doc.id, doc.data())).toList();
  }

  // Get all executions for a child
  Future<List<AllowanceExecution>> getChildAllowanceHistory(String childId) async {
    final snapshot = await _firestore
        .collection(_executionsCollection)
        .where('childId', isEqualTo: childId)
        .orderBy('executedAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => AllowanceExecution.fromMap(doc.id, doc.data())).toList();
  }

  // Chore management for reward-based allowances
  Future<String> createChore({
    required String childId,
    required String title,
    required String description,
    required double rewardAmount,
    String? allowanceId,
  }) async {
    final user = _authService.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final choreId = _uuid.v4();
    final chore = Chore(
      id: choreId,
      parentId: user.uid,
      childId: childId,
      title: title,
      description: description,
      rewardAmount: rewardAmount,
      status: ChoreStatus.pending,
      createdAt: DateTime.now(),
      allowanceId: allowanceId,
    );

    await _firestore.collection(_choresCollection).doc(choreId).set(chore.toMap());
    return choreId;
  }

  // Get chores for a child
  Future<List<Chore>> getChildChores(String childId) async {
    final snapshot = await _firestore
        .collection(_choresCollection)
        .where('childId', isEqualTo: childId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs.map((doc) => Chore.fromMap(doc.id, doc.data())).toList();
  }

  // Update chore status
  Future<void> updateChoreStatus(String choreId, ChoreStatus status) async {
    final updateData = <String, dynamic>{
      'status': status.name,
    };

    if (status == ChoreStatus.completed) {
      updateData['completedAt'] = FieldValue.serverTimestamp();
    } else if (status == ChoreStatus.approved) {
      updateData['approvedAt'] = FieldValue.serverTimestamp();
    }

    await _firestore.collection(_choresCollection).doc(choreId).update(updateData);
  }

  // Approve and pay chore reward
  Future<void> approveAndPayChore(String choreId) async {
    final chore = await getChore(choreId);
    if (chore == null || chore.status != ChoreStatus.completed) return;

    // Add reward to child's spend wallet
    await _childService.addToBalance(chore.childId, chore.rewardAmount);

    // Update chore status
    await updateChoreStatus(choreId, ChoreStatus.paid);

    // Record transaction
    await _firestore.collection('transactions').add({
      'type': 'allowance',
      'fromType': 'parent',
      'fromId': chore.parentId,
      'toType': 'child',
      'toId': chore.childId,
      'amount': chore.rewardAmount,
      'message': 'Chore reward: ${chore.title}',
      'status': 'completed',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get single chore
  Future<Chore?> getChore(String choreId) async {
    final doc = await _firestore.collection(_choresCollection).doc(choreId).get();
    if (doc.exists) {
      return Chore.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  // Get allowance analytics
  Future<AllowanceAnalytics> getAllowanceAnalytics(String childId) async {
    final executions = await getChildAllowanceHistory(childId);
    final allowances = await getChildAllowances(childId);

    final totalPaid = executions
        .where((e) => e.status == AllowanceExecutionStatus.completed)
        .fold(0.0, (sum, e) => sum + e.totalAmount);

    final totalSaved = executions
        .where((e) => e.status == AllowanceExecutionStatus.completed)
        .fold(0.0, (sum, e) => sum + e.saveAmount);

    final activeAllowances = allowances.where((a) => a.status == AllowanceStatus.active).length;
    final completedExecutions = executions.where((e) => e.status == AllowanceExecutionStatus.completed).length;

    return AllowanceAnalytics(
      totalPaid: totalPaid,
      totalSaved: totalSaved,
      activeAllowances: activeAllowances,
      completedExecutions: completedExecutions,
      executions: executions,
    );
  }

  // Helper methods
  DateTime _calculateNextExecution(DateTime from, AllowanceFrequency frequency) {
    switch (frequency) {
      case AllowanceFrequency.daily:
        return DateTime(from.year, from.month, from.day + 1);
      case AllowanceFrequency.weekly:
        return DateTime(from.year, from.month, from.day + 7);
      case AllowanceFrequency.monthly:
        final nextMonth = from.month + 1;
        final year = nextMonth > 12 ? from.year + 1 : from.year;
        final month = nextMonth > 12 ? 1 : nextMonth;
        return DateTime(year, month, from.day);
    }
  }
}

class AllowanceExecutionResult {
  final bool success;
  final AllowanceExecution? execution;
  final String? error;

  AllowanceExecutionResult.success(this.execution)
      : success = true,
        error = null;

  AllowanceExecutionResult.failure(this.error)
      : success = false,
        execution = null;
}

class AllowanceAnalytics {
  final double totalPaid;
  final double totalSaved;
  final int activeAllowances;
  final int completedExecutions;
  final List<AllowanceExecution> executions;

  const AllowanceAnalytics({
    required this.totalPaid,
    required this.totalSaved,
    required this.activeAllowances,
    required this.completedExecutions,
    required this.executions,
  });

  double get savingsRate => totalPaid > 0 ? (totalSaved / totalPaid) * 100 : 0;
}