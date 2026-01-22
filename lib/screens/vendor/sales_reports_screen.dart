import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
  final TransactionService _transactionService = TransactionService();
  late Stream<List<TransactionModel>> _transactionsStream;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // TODO: Get current vendor ID from auth
    _transactionsStream =
        _transactionService.getVendorTransactions('current_vendor_id');
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Map<String, double> _calculateSummary(List<TransactionModel> transactions) {
    double totalSales = 0.0;
    double totalPayments = 0.0;
    double totalRefunds = 0.0;
    int transactionCount = 0;

    final filteredTransactions = transactions.where((t) {
      return t.createdAt
              .isAfter(_startDate.subtract(const Duration(days: 1))) &&
          t.createdAt.isBefore(_endDate.add(const Duration(days: 1)));
    }).toList();

    for (final transaction in filteredTransactions) {
      if (transaction.status == TransactionStatus.completed) {
        transactionCount++;
        switch (transaction.type) {
          case TransactionType.payment:
          case TransactionType.purchase:
            totalSales += transaction.amount;
            break;
          case TransactionType.refund:
            totalRefunds += transaction.amount;
            break;
          default:
            break;
        }
      }
    }

    return {
      'totalSales': totalSales,
      'totalPayments': totalPayments,
      'totalRefunds': totalRefunds,
      'netSales': totalSales - totalRefunds,
      'transactionCount': transactionCount.toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
        ],
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: _transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final transactions = snapshot.data ?? [];
          final summary = _calculateSummary(transactions);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Date Range Display
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            '${_startDate.toString().split(' ')[0]} - ${_endDate.toString().split(' ')[0]}',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        TextButton(
                          onPressed: _selectDateRange,
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Summary Cards
                const Text(
                  'Summary',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _buildSummaryCard(
                      title: 'Total Sales',
                      value: 'R${summary['totalSales']!.toStringAsFixed(2)}',
                      color: Colors.green,
                      icon: Icons.trending_up,
                    ),
                    _buildSummaryCard(
                      title: 'Net Sales',
                      value: 'R${summary['netSales']!.toStringAsFixed(2)}',
                      color: Colors.blue,
                      icon: Icons.account_balance_wallet,
                    ),
                    _buildSummaryCard(
                      title: 'Transactions',
                      value: summary['transactionCount']!.toInt().toString(),
                      color: Colors.orange,
                      icon: Icons.receipt_long,
                    ),
                    _buildSummaryCard(
                      title: 'Refunds',
                      value: 'R${summary['totalRefunds']!.toStringAsFixed(2)}',
                      color: Colors.red,
                      icon: Icons.undo,
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Recent Transactions
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                _buildTransactionsList(transactions),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionsList(List<TransactionModel> transactions) {
    final filteredTransactions = transactions
        .where((t) =>
            t.createdAt.isAfter(_startDate.subtract(const Duration(days: 1))) &&
            t.createdAt.isBefore(_endDate.add(const Duration(days: 1))))
        .take(10)
        .toList();

    if (filteredTransactions.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(
            child: Text('No transactions in selected period'),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: filteredTransactions.length,
      itemBuilder: (context, index) {
        final transaction = filteredTransactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(
              _getTransactionIcon(transaction.type),
              color: _getTransactionColor(transaction.status),
            ),
            title: Text(_getTransactionTitle(transaction)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'R${transaction.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
                Text(
                  '${transaction.createdAt.toString().split('.')[0]}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(transaction.status),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                transaction.status.name.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return Icons.payment;
      case TransactionType.purchase:
        return Icons.shopping_cart;
      case TransactionType.airtime:
        return Icons.phone_android;
      case TransactionType.transport:
        return Icons.directions_bus;
      case TransactionType.refund:
        return Icons.undo;
      default:
        return Icons.receipt;
    }
  }

  Color _getTransactionColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }

  Color _getStatusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.completed:
        return Colors.green;
      case TransactionStatus.pending:
        return Colors.orange;
      case TransactionStatus.failed:
        return Colors.red;
      case TransactionStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getTransactionTitle(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.payment:
        return 'Payment Received';
      case TransactionType.purchase:
        return 'Product Purchase';
      case TransactionType.airtime:
        return 'Airtime Sale';
      case TransactionType.transport:
        return 'Transport Ticket';
      case TransactionType.refund:
        return 'Refund';
      default:
        return 'Transaction';
    }
  }
}
