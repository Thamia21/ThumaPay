// Deposit history screen with filtering capabilities
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/deposit_model.dart';
import '../../models/transaction_model.dart' as tx;
import '../../services/deposit_service.dart';
import '../../services/auth_service.dart';

class DepositHistoryScreen extends StatefulWidget {
  const DepositHistoryScreen({super.key});

  @override
  State<DepositHistoryScreen> createState() => _DepositHistoryScreenState();
}

class _DepositHistoryScreenState extends State<DepositHistoryScreen> {
  final DepositService _depositService = DepositService();
  final AuthService _authService = AuthService();

  List<tx.Transaction> _deposits = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  DepositMethod? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _loadDeposits();
  }

  Future<void> _loadDeposits() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final deposits = await _depositService.getDepositHistory(
        user.uid,
        startDate: _startDate,
        endDate: _endDate,
        method: _selectedMethod,
      );

      if (mounted) {
        setState(() {
          _deposits = deposits;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deposit History'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
          ),
        ],
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
                        onPressed: _loadDeposits,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _deposits.isEmpty
                  ? const Center(
                      child: Text('No deposits found'),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _deposits.length,
                      itemBuilder: (context, index) {
                        final deposit = _deposits[index];
                        return _buildDepositCard(deposit);
                      },
                    ),
    );
  }

  Widget _buildDepositCard(tx.Transaction deposit) {
    final method = DepositMethod.values.firstWhere(
      (m) => m.name == deposit.metadata?['depositMethod'],
      orElse: () => DepositMethod.bankCard,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_getMethodIcon(method), color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        method.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(deposit.createdAt),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '+ R ${deposit.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(deposit.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        deposit.status.name.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(deposit.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (deposit.metadata?['paymentReference'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Ref: ${deposit.metadata!['paymentReference']}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadReceipt(deposit),
                    icon: const Icon(Icons.download, size: 16),
                    label: const Text('Receipt'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue,
                      side: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showDepositDetails(deposit),
                    icon: const Icon(Icons.info_outline, size: 16),
                    label: const Text('Details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(tx.TransactionStatus status) {
    switch (status) {
      case tx.TransactionStatus.completed:
        return Colors.green;
      case tx.TransactionStatus.pending:
        return Colors.orange;
      case tx.TransactionStatus.failed:
        return Colors.red;
      case tx.TransactionStatus.cancelled:
        return Colors.grey;
      case tx.TransactionStatus.scheduled:
        return Colors.blue;
    }
  }

  IconData _getMethodIcon(DepositMethod method) {
    switch (method) {
      case DepositMethod.bankCard:
        return Icons.credit_card;
      case DepositMethod.eft:
        return Icons.account_balance;
      case DepositMethod.mobileMoney:
        return Icons.phone_android;
      case DepositMethod.qrCode:
        return Icons.qr_code;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Deposits'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date range
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _startDate = date);
                        }
                      },
                      child: Text(
                        _startDate != null
                            ? DateFormat('MMM dd').format(_startDate!)
                            : 'Start Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _endDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _endDate = date);
                        }
                      },
                      child: Text(
                        _endDate != null
                            ? DateFormat('MMM dd').format(_endDate!)
                            : 'End Date',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Method filter
              DropdownButtonFormField<DepositMethod>(
                value: _selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Methods'),
                  ),
                  ...DepositMethod.values.map((method) {
                    return DropdownMenuItem(
                      value: method,
                      child: Text(method.displayName),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedMethod = value);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _startDate = null;
                  _endDate = null;
                  _selectedMethod = null;
                });
                Navigator.of(context).pop();
                _loadDeposits();
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadDeposits();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadReceipt(tx.Transaction deposit) async {
    try {
      final receipt = await _depositService.generateReceipt(deposit.id);
      // In real app, would save to file or share
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt downloaded')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to download receipt: $e')),
      );
    }
  }

  void _showDepositDetails(tx.Transaction deposit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deposit Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Amount', 'R ${deposit.amount.toStringAsFixed(2)}'),
            _detailRow('Method', deposit.metadata?['depositMethod'] ?? 'Unknown'),
            _detailRow('Date', DateFormat('MMM dd, yyyy HH:mm').format(deposit.createdAt)),
            _detailRow('Status', deposit.status.name),
            if (deposit.metadata?['paymentReference'] != null)
              _detailRow('Reference', deposit.metadata!['paymentReference']),
            if (deposit.completedAt != null)
              _detailRow('Completed', DateFormat('MMM dd, yyyy HH:mm').format(deposit.completedAt!)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}