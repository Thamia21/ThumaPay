// Child transaction history screen with filtering
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/child_model.dart';
import '../../models/transaction_model.dart' as tx;
import '../../services/child_service.dart';

class ChildTransactionHistoryScreen extends StatefulWidget {
  final ChildModel child;

  const ChildTransactionHistoryScreen({super.key, required this.child});

  @override
  State<ChildTransactionHistoryScreen> createState() => _ChildTransactionHistoryScreenState();
}

class _ChildTransactionHistoryScreenState extends State<ChildTransactionHistoryScreen> {
  final ChildService _childService = ChildService();

  List<tx.Transaction> _transactions = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Filters
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    try {
      // In a real implementation, you'd have a method to get transactions for a child
      // For now, we'll simulate with some mock data
      await Future.delayed(const Duration(seconds: 1)); // Simulate loading

      // Mock transactions for demo
      final now = DateTime.now();
      _transactions = [
        tx.Transaction(
          id: '1',
          senderId: 'parent',
          senderName: 'Parent',
          receiverId: widget.child.id,
          receiverName: widget.child.name,
          amount: 500.00,
          type: tx.TransactionType.transfer,
          status: tx.TransactionStatus.completed,
          transferType: tx.TransferType.toChild,
          createdAt: now.subtract(const Duration(hours: 2)),
          completedAt: now.subtract(const Duration(hours: 2)),
          metadata: {'category': 'Allowance'},
        ),
        tx.Transaction(
          id: '2',
          senderId: widget.child.id,
          senderName: widget.child.name,
          receiverId: 'merchant',
          receiverName: 'School Canteen',
          amount: 45.50,
          type: tx.TransactionType.transfer,
          status: tx.TransactionStatus.completed,
          transferType: tx.TransferType.toExternal,
          createdAt: now.subtract(const Duration(days: 1)),
          completedAt: now.subtract(const Duration(days: 1)),
          metadata: {'category': 'Food & Drinks'},
        ),
        tx.Transaction(
          id: '3',
          senderId: widget.child.id,
          senderName: widget.child.name,
          receiverId: 'merchant',
          receiverName: 'Book Store',
          amount: 120.00,
          type: tx.TransactionType.transfer,
          status: tx.TransactionStatus.failed,
          transferType: tx.TransferType.toExternal,
          createdAt: now.subtract(const Duration(days: 2)),
          completedAt: now.subtract(const Duration(days: 2)),
          metadata: {'category': 'Books', 'failureReason': 'Insufficient funds'},
        ),
      ];

      // Apply filters
      if (_startDate != null) {
        _transactions = _transactions.where((t) => t.createdAt.isAfter(_startDate!)).toList();
      }
      if (_endDate != null) {
        _transactions = _transactions.where((t) => t.createdAt.isBefore(_endDate!)).toList();
      }
      if (_selectedCategory != null) {
        _transactions = _transactions.where((t) => t.metadata?['category'] == _selectedCategory).toList();
      }

      if (mounted) {
        setState(() {
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
        title: Text('${widget.child.name} - Transactions'),
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
                        onPressed: _loadTransactions,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _transactions.isEmpty
                  ? _buildEmptyState()
                  : _buildTransactionList(),
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
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.receipt_long,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No transactions found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Transactions will appear here once ${widget.child.name} makes purchases',
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

  Widget _buildTransactionList() {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          return _buildTransactionCard(transaction);
        },
      ),
    );
  }

  Widget _buildTransactionCard(tx.Transaction transaction) {
    final isIncoming = transaction.senderId != widget.child.id;
    final category = transaction.metadata?['category'] ?? 'Other';
    final failureReason = transaction.metadata?['failureReason'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: _getCategoryColor(category),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.receiverName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • HH:mm').format(transaction.createdAt),
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
                      '${isIncoming ? '+' : '-'} R ${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isIncoming ? Colors.green : Colors.red,
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
                        color: _getStatusColor(transaction.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        transaction.status.name.toUpperCase(),
                        style: TextStyle(
                          color: _getStatusColor(transaction.status),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      color: _getCategoryColor(category),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                if (failureReason != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      failureReason,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
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

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food & Drinks':
        return Colors.orange;
      case 'Transportation':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Books':
        return Colors.green;
      case 'Allowance':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food & Drinks':
        return Icons.restaurant;
      case 'Transportation':
        return Icons.directions_bus;
      case 'Entertainment':
        return Icons.movie;
      case 'Books':
        return Icons.book;
      case 'Allowance':
        return Icons.account_balance_wallet;
      default:
        return Icons.category;
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filter Transactions'),
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
              // Category filter
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...ChildModel.allowedCategories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => _selectedCategory = value);
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
                  _selectedCategory = null;
                });
                Navigator.of(context).pop();
                _loadTransactions();
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _loadTransactions();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}