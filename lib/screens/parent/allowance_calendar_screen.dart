// Allowance calendar screen for viewing schedules and upcoming payments
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/allowance_model.dart';
import '../../services/allowance_service.dart';
import '../../services/auth_service.dart';

class AllowanceCalendarScreen extends StatefulWidget {
  const AllowanceCalendarScreen({super.key});

  @override
  State<AllowanceCalendarScreen> createState() => _AllowanceCalendarScreenState();
}

class _AllowanceCalendarScreenState extends State<AllowanceCalendarScreen> {
  final AllowanceService _allowanceService = AllowanceService();
  final AuthService _authService = AuthService();

  List<Allowance> _allowances = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAllowances();
  }

  Future<void> _loadAllowances() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final allowances = await _allowanceService.getAllowances(user.uid);
      if (mounted) {
        setState(() {
          _allowances = allowances;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleAllowanceStatus(Allowance allowance) async {
    final newStatus = allowance.status == AllowanceStatus.active
        ? AllowanceStatus.paused
        : AllowanceStatus.active;

    try {
      await _allowanceService.updateAllowanceStatus(allowance.id, newStatus);
      _loadAllowances();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update allowance: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allowance Calendar'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllowances,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _allowances.isEmpty
                  ? _buildEmptyState()
                  : _buildCalendarView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_today,
              size: 60,
              color: Colors.blue.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No allowances scheduled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create allowances for your children to see upcoming payments here',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarView() {
    final now = DateTime.now();
    final upcomingAllowances = _getUpcomingAllowances(now);

    return RefreshIndicator(
      onRefresh: _loadAllowances,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Today's allowances
          _buildSectionHeader('Today', Icons.today),
          _buildAllowanceList(_getTodaysAllowances(now)),

          // Upcoming allowances
          if (upcomingAllowances.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionHeader('Upcoming', Icons.schedule),
            _buildAllowanceList(upcomingAllowances),
          ],

          // All allowances
          const SizedBox(height: 24),
          _buildSectionHeader('All Allowances', Icons.list),
          _buildAllAllowancesList(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildAllowanceList(List<Allowance> allowances) {
    if (allowances.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'No allowances scheduled',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: allowances.length,
      itemBuilder: (context, index) {
        return _buildAllowanceCard(allowances[index]);
      },
    );
  }

  Widget _buildAllAllowancesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _allowances.length,
      itemBuilder: (context, index) {
        final allowance = _allowances[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: allowance.status.color.withOpacity(0.2),
              child: Icon(
                _getAllowanceIcon(allowance.type),
                color: allowance.status.color,
              ),
            ),
            title: Text('${allowance.childName} - ${allowance.frequency.displayName}'),
            subtitle: Text('R ${allowance.amount.toStringAsFixed(2)} • ${allowance.status.displayName}'),
            trailing: Switch(
              value: allowance.status == AllowanceStatus.active,
              onChanged: (_) => _toggleAllowanceStatus(allowance),
              activeColor: Colors.green,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAllowanceCard(Allowance allowance) {
    final nextPayment = allowance.nextExecutionDate;
    final isOverdue = nextPayment != null && nextPayment.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: allowance.status.color.withOpacity(0.2),
                  child: Icon(
                    _getAllowanceIcon(allowance.type),
                    color: allowance.status.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        allowance.childName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '${allowance.frequency.displayName} Allowance',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R ${allowance.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    if (nextPayment != null)
                      Text(
                        isOverdue ? 'Overdue' : _formatDate(nextPayment),
                        style: TextStyle(
                          color: isOverdue ? Colors.red : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSplitIndicator('Spend', allowance.spendPercentage, Colors.green),
                const SizedBox(width: 12),
                _buildSplitIndicator('Save', allowance.savePercentage, Colors.orange),
              ],
            ),
            if (allowance.status != AllowanceStatus.active) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: allowance.status.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  allowance.status.displayName,
                  style: TextStyle(
                    color: allowance.status.color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSplitIndicator(String label, double percentage, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          const SizedBox(height: 2),
          Text(
            '${(percentage * 100).round()}%',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAllowanceIcon(AllowanceType type) {
    switch (type) {
      case AllowanceType.standard:
        return Icons.account_balance_wallet;
      case AllowanceType.rewardBased:
        return Icons.star;
    }
  }

  List<Allowance> _getTodaysAllowances(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));

    return _allowances.where((allowance) {
      final nextDate = allowance.nextExecutionDate;
      return nextDate != null &&
             nextDate.isAfter(today) &&
             nextDate.isBefore(tomorrow) &&
             allowance.status == AllowanceStatus.active;
    }).toList();
  }

  List<Allowance> _getUpcomingAllowances(DateTime now) {
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    return _allowances.where((allowance) {
      final nextDate = allowance.nextExecutionDate;
      return nextDate != null &&
             nextDate.isAfter(tomorrow) &&
             allowance.status == AllowanceStatus.active;
    }).toList()
      ..sort((a, b) => a.nextExecutionDate!.compareTo(b.nextExecutionDate!));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}