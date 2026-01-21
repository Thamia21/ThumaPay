import 'package:flutter/material.dart';
import '../../models/child_model.dart';
import '../../services/child_service.dart';
import 'child_transaction_history_screen.dart';
import 'edit_child_dialog.dart';
import 'allowance_setup_screen.dart';
import 'allowance_calendar_screen.dart';

class ChildDetailScreen extends StatefulWidget {
  final ChildModel child;

  const ChildDetailScreen({super.key, required this.child});

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  late ChildModel _child;
  final ChildService _childService = ChildService();

  @override
  void initState() {
    super.initState();
    _child = widget.child;
  }

  Future<void> _loadChildData() async {
    final updatedChild = await _childService.getChild(widget.child.id);
    if (updatedChild != null && mounted) {
      setState(() {
        _child = updatedChild;
      });
    }
  }

  Future<void> _toggleFreeze() async {
    await _childService.toggleFreeze(_child.id, !_child.isFrozen);
    _loadChildData();
  }

  Future<void> _setSpendingLimits() async {
    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (context) => SpendingLimitsDialog(
        currentDaily: _child.spendingLimits['daily'] ?? 0,
        currentWeekly: _child.spendingLimits['weekly'] ?? 0,
      ),
    );

    if (result != null) {
      await _childService.setSpendingLimits(
        childId: _child.id,
        dailyLimit: result['daily']!,
        weeklyLimit: result['weekly']!,
      );
      _loadChildData();
    }
  }

  Future<void> _setSavingsGoal() async {
    final result = await showDialog<double>(
      context: context,
      builder: (context) => SavingsGoalDialog(
        currentGoal: _child.savingsGoal,
      ),
    );

    if (result != null) {
      await _childService.setSavingsGoal(
        childId: _child.id,
        goalAmount: result,
      );
      _loadChildData();
    }
  }

  Future<void> _setCategoryRestrictions() async {
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder: (context) => CategoryRestrictionsDialog(
        currentRestrictions: Map<String, bool>.from(_child.categoryRestrictions),
      ),
    );

    if (result != null) {
      await _childService.setCategoryRestrictions(
        childId: _child.id,
        restrictions: result,
      );
      _loadChildData();
    }
  }

  Future<void> _editChild() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => EditChildDialog(child: _child),
    );

    if (result == true) {
      _loadChildData();
    }
  }

  void _sendMoney() {
    // Navigate to send money screen or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Send money feature coming soon')),
    );
  }

  void _viewHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChildTransactionHistoryScreen(child: _child),
      ),
    );
  }

  void _setupAllowance() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AllowanceSetupScreen(child: _child),
      ),
    );
  }

  void _viewCalendar() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AllowanceCalendarScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          _child.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: _editChild,
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Child',
          ),
          Switch(
            value: !_child.isFrozen,
            onChanged: (_) => _toggleFreeze(),
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadChildData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBalanceCard(),
              const SizedBox(height: 20),
              const Text(
                'Controls',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              _buildControlCard(
                icon: Icons.account_balance_wallet,
                title: 'Spending Limits',
                subtitle: _child.spendingLimits['daily']! > 0
                    ? 'Daily: R ${_child.spendingLimits['daily']} | Weekly: R ${_child.spendingLimits['weekly']}'
                    : 'No limits set',
                color: Colors.blue,
                onTap: _setSpendingLimits,
              ),
              const SizedBox(height: 12),
              _buildControlCard(
                icon: Icons.category,
                title: 'Category Restrictions',
                subtitle: _getCategoriesSummary(),
                color: Colors.orange,
                onTap: _setCategoryRestrictions,
              ),
              const SizedBox(height: 12),
              _buildControlCard(
                icon: Icons.savings,
                title: 'Savings Goal',
                subtitle: _child.savingsGoal != null
                    ? 'Goal: R ${_child.savingsGoal!.toStringAsFixed(2)}'
                    : 'No savings goal set',
                color: Colors.green,
                onTap: _setSavingsGoal,
              ),
              const SizedBox(height: 20),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildQuickAction(Icons.send, 'Send Money', Colors.blue, onTap: _sendMoney)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickAction(Icons.history, 'History', Colors.purple, onTap: _viewHistory)),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildQuickAction(Icons.attach_money, 'Allowance', Colors.green, onTap: _setupAllowance)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildQuickAction(Icons.calendar_today, 'Calendar', Colors.orange, onTap: _viewCalendar)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _child.isFrozen
              ? [Colors.grey.shade400, Colors.grey.shade600]
              : [const Color(0xFF2196F3), const Color(0xFF1976D2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _child.isFrozen ? 'Wallet Frozen' : 'Available Balance',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'R ${_child.balance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _child.isFrozen ? Icons.lock : Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ],
          ),
          if (_child.savingsGoal != null) ...[
            const SizedBox(height: 16),
            _buildSavingsProgress(),
          ],
        ],
      ),
    );
  }

  Widget _buildSavingsProgress() {
    final progress = (_child.savingsCurrent ?? 0.0) / _child.savingsGoal!;
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Savings Goal',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${(clampedProgress * 100).toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: clampedProgress,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            'R ${(_child.savingsCurrent ?? 0.0).toStringAsFixed(2)} of R ${_child.savingsGoal!.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoriesSummary() {
    if (_child.categoryRestrictions.isEmpty) {
      return 'No restrictions';
    }
    final restrictedCount = _child.categoryRestrictions.values.where((v) => v).length;
    return '$restrictedCount categories restricted';
  }
}

class SpendingLimitsDialog extends StatefulWidget {
  final double currentDaily;
  final double currentWeekly;

  const SpendingLimitsDialog({
    super.key,
    required this.currentDaily,
    required this.currentWeekly,
  });

  @override
  State<SpendingLimitsDialog> createState() => _SpendingLimitsDialogState();
}

class _SpendingLimitsDialogState extends State<SpendingLimitsDialog> {
  late TextEditingController _dailyController;
  late TextEditingController _weeklyController;

  @override
  void initState() {
    super.initState();
    _dailyController = TextEditingController(
      text: widget.currentDaily > 0 ? widget.currentDaily.toString() : '',
    );
    _weeklyController = TextEditingController(
      text: widget.currentWeekly > 0 ? widget.currentWeekly.toString() : '',
    );
  }

  @override
  void dispose() {
    _dailyController.dispose();
    _weeklyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.account_balance_wallet, color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Text(
              'Spending Limits',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _dailyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Daily Limit (R)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weeklyController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Weekly Limit (R)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop({
                        'daily': double.tryParse(_dailyController.text) ?? 0,
                        'weekly': double.tryParse(_weeklyController.text) ?? 0,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SavingsGoalDialog extends StatefulWidget {
  final double? currentGoal;

  const SavingsGoalDialog({super.key, this.currentGoal});

  @override
  State<SavingsGoalDialog> createState() => _SavingsGoalDialogState();
}

class _SavingsGoalDialogState extends State<SavingsGoalDialog> {
  late TextEditingController _goalController;

  @override
  void initState() {
    super.initState();
    _goalController = TextEditingController(
      text: widget.currentGoal != null ? widget.currentGoal.toString() : '',
    );
  }

  @override
  void dispose() {
    _goalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.savings, color: Colors.green),
            ),
            const SizedBox(height: 16),
            const Text('Savings Goal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _goalController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Goal Amount (R)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(double.tryParse(_goalController.text) ?? 0);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryRestrictionsDialog extends StatelessWidget {
  final Map<String, bool> currentRestrictions;

  const CategoryRestrictionsDialog({super.key, required this.currentRestrictions});

  @override
  Widget build(BuildContext context) {
    final restrictions = Map<String, bool>.from(currentRestrictions);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.category, color: Colors.orange),
            ),
            const SizedBox(height: 16),
            const Text(
              'Category Restrictions',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: ChildModel.allowedCategories.length,
                itemBuilder: (context, index) {
                  final category = ChildModel.allowedCategories[index];
                  final isRestricted = restrictions[category] ?? false;
                  return CheckboxListTile(
                    value: isRestricted,
                    onChanged: (value) {
                      restrictions[category] = value ?? false;
                    },
                    title: Text(category),
                    subtitle: Text(isRestricted ? 'Blocked' : 'Allowed'),
                    activeColor: Colors.orange,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(restrictions),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
