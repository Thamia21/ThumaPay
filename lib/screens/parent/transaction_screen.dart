import 'package:flutter/material.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Sent', 'Received', 'Pending'];

  // Mock transaction data
  final List<Transaction> _transactions = [
    Transaction(
      id: 'TXN001',
      title: 'Thuma Pay Store',
      amount: 250.00,
      type: TransactionType.sent,
      date: 'Today, 14:30',
      status: TransactionStatus.completed,
      description: 'Grocery shopping',
    ),
    Transaction(
      id: 'TXN002',
      title: 'John Doe',
      amount: 500.00,
      type: TransactionType.received,
      date: 'Today, 12:15',
      status: TransactionStatus.completed,
      description: 'Payment for services',
    ),
    Transaction(
      id: 'TXN003',
      title: 'Electricity Bill',
      amount: 850.00,
      type: TransactionType.sent,
      date: 'Yesterday, 18:45',
      status: TransactionStatus.completed,
      description: 'Monthly electricity payment',
    ),
    Transaction(
      id: 'TXN004',
      title: 'Jane Smith',
      amount: 200.00,
      type: TransactionType.pending,
      date: 'Yesterday, 15:20',
      status: TransactionStatus.pending,
      description: 'Awaiting confirmation',
    ),
    Transaction(
      id: 'TXN005',
      title: 'Salary Deposit',
      amount: 5000.00,
      type: TransactionType.received,
      date: 'Jan 13, 09:00',
      status: TransactionStatus.completed,
      description: 'Monthly salary',
    ),
    Transaction(
      id: 'TXN006',
      title: 'Internet Bill',
      amount: 299.00,
      type: TransactionType.sent,
      date: 'Jan 12, 16:30',
      status: TransactionStatus.completed,
      description: 'Monthly internet subscription',
    ),
  ];

  List<Transaction> get _filteredTransactions {
    switch (_selectedFilter) {
      case 'Sent':
        return _transactions.where((t) => t.type == TransactionType.sent).toList();
      case 'Received':
        return _transactions.where((t) => t.type == TransactionType.received).toList();
      case 'Pending':
        return _transactions.where((t) => t.status == TransactionStatus.pending).toList();
      default:
        return _transactions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _showFilterDialog,
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredTransactions.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final transaction = _filteredTransactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
              backgroundColor: Colors.grey.shade200,
              selectedColor: Colors.blue.shade100,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(Transaction transaction) {
    Color iconColor;
    IconData iconData;
    
    switch (transaction.type) {
      case TransactionType.sent:
        iconColor = Colors.red;
        iconData = Icons.arrow_upward_rounded;
        break;
      case TransactionType.received:
        iconColor = Colors.green;
        iconData = Icons.arrow_downward_rounded;
        break;
      case TransactionType.pending:
        iconColor = Colors.orange;
        iconData = Icons.schedule;
        break;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(
            iconData,
            color: iconColor,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              transaction.description,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              transaction.date,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${transaction.type == TransactionType.received ? '+' : '-'}R ${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: iconColor,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: transaction.status == TransactionStatus.completed
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                transaction.status == TransactionStatus.completed ? 'Completed' : 'Pending',
                style: TextStyle(
                  color: transaction.status == TransactionStatus.completed ? Colors.green : Colors.orange,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Transaction Details',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildDetailRow('Transaction ID', transaction.id),
            _buildDetailRow('Title', transaction.title),
            _buildDetailRow('Description', transaction.description),
            _buildDetailRow('Date', transaction.date),
            _buildDetailRow('Status', transaction.status == TransactionStatus.completed ? 'Completed' : 'Pending'),
            _buildDetailRow('Amount', 'R ${transaction.amount.toStringAsFixed(2)}'),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _shareTransaction(transaction);
                    },
                    child: const Text('Share'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _downloadReceipt(transaction);
                    },
                    child: const Text('Download Receipt'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Transactions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _filters.map((filter) {
            return RadioListTile<String>(
              title: Text(filter),
              value: filter,
              groupValue: _selectedFilter,
              onChanged: (value) {
                setState(() {
                  _selectedFilter = value!;
                });
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _shareTransaction(Transaction transaction) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Transaction details shared!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _downloadReceipt(Transaction transaction) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt downloaded!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

enum TransactionType { sent, received, pending }

enum TransactionStatus { completed, pending }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String date;
  final TransactionStatus status;
  final String description;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.status,
    required this.description,
  });
}
