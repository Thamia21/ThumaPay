import 'package:flutter/material.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _selectedWalletFilter = 'All Wallets';
  String _selectedChildFilter = 'All Children';
  String _selectedTransactionType = 'All';

  // Wallet filter options
  final List<String> _walletFilters = ['All Wallets', 'Main Wallet', 'Child Wallets'];
  
  // Child data (placeholder)
  final List<Child> _children = [
    Child(id: '1', name: 'Senzo', avatar: 'S'),
    Child(id: '2', name: 'Amara', avatar: 'A'),
    Child(id: '3', name: 'Kaelo', avatar: 'K'),
  ];

  // Transaction type filters
  final List<String> _transactionTypes = ['All', 'Deposits', 'Transfers', 'Withdrawals', 'Spending'];

  // Mock transaction data with proper wallet context
  final List<Transaction> _transactions = [
    // Main wallet transactions
    Transaction(
      id: 'TXN001',
      title: 'Monthly Salary Deposit',
      amount: 15000.00,
      type: TransactionType.deposit,
      date: DateTime.now().subtract(const Duration(hours: 2)),
      status: TransactionStatus.completed,
      sourceWallet: 'External Bank',
      destinationWallet: 'Main Wallet',
      description: 'Monthly salary credit',
    ),
    Transaction(
      id: 'TXN002',
      title: 'Transfer to Senzo',
      amount: 500.00,
      type: TransactionType.transfer,
      date: DateTime.now().subtract(const Duration(hours: 4)),
      status: TransactionStatus.completed,
      sourceWallet: 'Main Wallet',
      destinationWallet: "Senzo's Wallet",
      childName: 'Senzo',
      description: 'Weekly allowance',
    ),
    Transaction(
      id: 'TXN003',
      title: 'Transfer to Amara',
      amount: 300.00,
      type: TransactionType.transfer,
      date: DateTime.now().subtract(const Duration(hours: 6)),
      status: TransactionStatus.completed,
      sourceWallet: 'Main Wallet',
      destinationWallet: "Amara's Wallet",
      childName: 'Amara',
      description: 'School supplies',
    ),
    Transaction(
      id: 'TXN004',
      title: 'ATM Withdrawal',
      amount: 1000.00,
      type: TransactionType.withdrawal,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: TransactionStatus.completed,
      sourceWallet: 'Main Wallet',
      destinationWallet: 'External',
      description: 'Cash withdrawal',
    ),

    // Child wallet transactions
    Transaction(
      id: 'TXN005',
      title: 'School Canteen',
      amount: 45.50,
      type: TransactionType.spending,
      date: DateTime.now().subtract(const Duration(hours: 3)),
      status: TransactionStatus.completed,
      sourceWallet: "Senzo's Wallet",
      destinationWallet: 'School Canteen',
      childName: 'Senzo',
      category: 'Food',
      description: 'Lunch purchase',
    ),
    Transaction(
      id: 'TXN006',
      title: 'Stationery Shop',
      amount: 120.00,
      type: TransactionType.spending,
      date: DateTime.now().subtract(const Duration(hours: 5)),
      status: TransactionStatus.completed,
      sourceWallet: "Amara's Wallet",
      destinationWallet: 'Stationery Shop',
      childName: 'Amara',
      category: 'Stationery',
      description: 'Notebooks and pens',
    ),
    Transaction(
      id: 'TXN007',
      title: 'Tuck Shop',
      amount: 25.00,
      type: TransactionType.spending,
      date: DateTime.now().subtract(const Duration(days: 1)),
      status: TransactionStatus.completed,
      sourceWallet: "Senzo's Wallet",
      destinationWallet: 'School Tuck Shop',
      childName: 'Senzo',
      category: 'Food',
      description: 'Snacks and drinks',
    ),
    Transaction(
      id: 'TXN008',
      title: 'Book Store',
      amount: 280.00,
      type: TransactionType.spending,
      date: DateTime.now().subtract(const Duration(days: 2)),
      status: TransactionStatus.completed,
      sourceWallet: "Kaelo's Wallet",
      destinationWallet: 'Book Store',
      childName: 'Kaelo',
      category: 'Education',
      description: 'Textbook purchase',
    ),
  ];

  List<Transaction> get _filteredTransactions {
    List<Transaction> filtered = List.from(_transactions);

    // Apply wallet filter
    switch (_selectedWalletFilter) {
      case 'Main Wallet':
        filtered = filtered.where((t) => 
          t.sourceWallet == 'Main Wallet' || t.destinationWallet == 'Main Wallet'
        ).toList();
        break;
      case 'Child Wallets':
        filtered = filtered.where((t) => 
          t.sourceWallet.contains('Wallet') && t.sourceWallet != 'Main Wallet' ||
          t.destinationWallet.contains('Wallet') && t.destinationWallet != 'Main Wallet'
        ).toList();
        break;
    }

    // Apply child filter (only when Child Wallets is selected)
    if (_selectedWalletFilter == 'Child Wallets' && _selectedChildFilter != 'All Children') {
      filtered = filtered.where((t) => t.childName == _selectedChildFilter).toList();
    }

    // Apply transaction type filter
    switch (_selectedTransactionType) {
      case 'Deposits':
        filtered = filtered.where((t) => t.type == TransactionType.deposit).toList();
        break;
      case 'Transfers':
        filtered = filtered.where((t) => t.type == TransactionType.transfer).toList();
        break;
      case 'Withdrawals':
        filtered = filtered.where((t) => t.type == TransactionType.withdrawal).toList();
        break;
      case 'Spending':
        filtered = filtered.where((t) => t.type == TransactionType.spending).toList();
        break;
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.date.compareTo(a.date));

    return filtered;
  }

  Map<String, List<Transaction>> get _groupedTransactions {
    final Map<String, List<Transaction>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final transaction in _filteredTransactions) {
      String groupKey;
      final transactionDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );

      if (transactionDate.isAtSameMomentAs(today)) {
        groupKey = 'TODAY';
      } else if (transactionDate.isAtSameMomentAs(yesterday)) {
        groupKey = 'YESTERDAY';
      } else {
        groupKey = '${transaction.date.day}/${transaction.date.month}/${transaction.date.year}';
      }

      grouped.putIfAbsent(groupKey, () => []).add(transaction);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.grey.shade50,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildWalletFilterSection(context),
          if (_selectedWalletFilter == 'Child Wallets') _buildChildFilterSection(context),
          _buildTransactionTypeFilter(context),
          Expanded(
            child: _filteredTransactions.isEmpty ? _buildEmptyState(context) : _buildTransactionList(context),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return AppBar(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      elevation: 0,
      centerTitle: true,
      title: Column(
        children: [
          Text(
            'Transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? theme.colorScheme.onSurface : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Main wallet & child accounts',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletFilterSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: _walletFilters.map((filter) {
          final isSelected = filter == _selectedWalletFilter;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                right: _walletFilters.last != filter ? 8 : 0,
              ),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedWalletFilter = filter;
                    if (filter != 'Child Wallets') {
                      _selectedChildFilter = 'All Children';
                    }
                  });
                },
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : (isDark ? theme.colorScheme.surface : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      filter,
                      style: TextStyle(
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChildFilterSection(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Child',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildChildChip('All Children', null, true, context),
                ..._children.map((child) => _buildChildChip(child.name, child.avatar, false, context)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChildChip(String name, String? avatar, bool isAll, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSelected = isAll ? _selectedChildFilter == 'All Children' : _selectedChildFilter == name;
    
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedChildFilter = name;
          });
        },
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : (isDark ? theme.colorScheme.surface : Colors.grey.shade200),
                shape: BoxShape.circle,
                border: isSelected ? Border.all(color: theme.colorScheme.primary, width: 2) : null,
              ),
              child: isAll
                  ? Icon(
                      Icons.group,
                      color: isSelected ? theme.colorScheme.primary : (isDark ? theme.colorScheme.onSurface : Colors.grey.shade600),
                      size: 24,
                    )
                  : Center(
                      child: Text(
                        avatar!,
                        style: TextStyle(
                          color: isSelected ? theme.colorScheme.primary : (isDark ? theme.colorScheme.onSurface : Colors.grey.shade700),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? theme.colorScheme.primary : (isDark ? theme.colorScheme.onSurface : Colors.grey.shade600),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTypeFilter(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      color: isDark ? theme.scaffoldBackgroundColor : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: _transactionTypes.map((type) {
            final isSelected = type == _selectedTransactionType;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedTransactionType = type;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : (isDark ? theme.colorScheme.outline : Colors.grey.shade300),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      type,
                      style: TextStyle(
                        color: isSelected ? theme.colorScheme.primary : (isDark ? theme.colorScheme.onSurface : Colors.grey.shade700),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTransactionList(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final grouped = _groupedTransactions;
    final keys = grouped.keys.toList();

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: keys.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final dateKey = keys[index];
        final transactions = grouped[dateKey]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isDark ? theme.colorScheme.onSurface.withOpacity(0.6) : Colors.grey.shade600,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            ...transactions.map((transaction) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildTransactionCard(transaction, context),
            )),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(Transaction transaction, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _showTransactionDetails(transaction, context),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildTransactionIcon(transaction, context),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark ? theme.colorScheme.onSurface : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getTransactionSubtitle(transaction),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatTime(transaction.date),
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? theme.colorScheme.onSurface.withOpacity(0.5) : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _getAmountPrefix(transaction) + 'R ${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _getTransactionColor(transaction, context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: transaction.status == TransactionStatus.completed
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        transaction.status == TransactionStatus.completed ? 'Completed' : 'Pending',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: transaction.status == TransactionStatus.completed
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionIcon(Transaction transaction, BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    IconData iconData;
    Color iconColor;

    switch (transaction.type) {
      case TransactionType.deposit:
        backgroundColor = Colors.green.withOpacity(0.1);
        iconData = Icons.arrow_downward_rounded;
        iconColor = Colors.green.shade600;
        break;
      case TransactionType.transfer:
        backgroundColor = Colors.blue.withOpacity(0.1);
        iconData = Icons.swap_horiz_rounded;
        iconColor = Colors.blue.shade600;
        break;
      case TransactionType.withdrawal:
        backgroundColor = Colors.red.withOpacity(0.1);
        iconData = Icons.arrow_upward_rounded;
        iconColor = Colors.red.shade600;
        break;
      case TransactionType.spending:
        backgroundColor = Colors.orange.withOpacity(0.1);
        iconData = Icons.shopping_cart_rounded;
        iconColor = Colors.orange.shade600;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 20,
      ),
    );
  }

  String _getTransactionSubtitle(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.transfer:
        return '${transaction.sourceWallet} → ${transaction.destinationWallet}';
      case TransactionType.spending:
        final category = transaction.category != null ? ' · ${transaction.category}' : '';
        return '${transaction.sourceWallet}$category';
      case TransactionType.deposit:
      case TransactionType.withdrawal:
        return transaction.destinationWallet;
    }
  }

  String _getAmountPrefix(Transaction transaction) {
    switch (transaction.type) {
      case TransactionType.deposit:
      case TransactionType.transfer:
        return '+';
      case TransactionType.withdrawal:
      case TransactionType.spending:
        return '-';
    }
  }

  Color _getTransactionColor(Transaction transaction, BuildContext context) {
    switch (transaction.type) {
      case TransactionType.deposit:
        return Colors.green.shade600;
      case TransactionType.transfer:
        return Colors.blue.shade600;
      case TransactionType.withdrawal:
        return Colors.red.shade600;
      case TransactionType.spending:
        return Colors.orange.shade600;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    String message;
    IconData iconData;

    if (_selectedWalletFilter == 'Child Wallets' && _selectedChildFilter != 'All Children') {
      message = 'No transactions for ${_selectedChildFilter}';
      iconData = Icons.account_balance_wallet_outlined;
    } else {
      message = 'No transactions yet';
      iconData = Icons.receipt_long_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 64,
            color: isDark ? theme.colorScheme.onSurface.withOpacity(0.4) : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? theme.colorScheme.onSurface.withOpacity(0.6) : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Transaction transaction, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surface : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaction Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? theme.colorScheme.onSurface : Colors.black87,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: isDark ? theme.colorScheme.onSurface : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildDetailRow('Transaction ID', transaction.id, context),
              _buildDetailRow('Title', transaction.title, context),
              _buildDetailRow('Description', transaction.description, context),
              _buildDetailRow('Source Wallet', transaction.sourceWallet, context),
              _buildDetailRow('Destination', transaction.destinationWallet, context),
              if (transaction.childName != null)
                _buildDetailRow('Child', transaction.childName!, context),
              if (transaction.category != null)
                _buildDetailRow('Category', transaction.category!, context),
              _buildDetailRow('Date', _formatFullDate(transaction.date), context),
              _buildDetailRow('Time', _formatFullTime(transaction.date), context),
              _buildDetailRow('Status', transaction.status == TransactionStatus.completed ? 'Completed' : 'Pending', context),
              _buildDetailRow('Amount', '${_getAmountPrefix(transaction)}R ${transaction.amount.toStringAsFixed(2)}', context),
              const SizedBox(height: 24),
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
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? theme.colorScheme.onSurface.withOpacity(0.6) : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? theme.colorScheme.onSurface : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFullDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String _formatFullTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
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

enum TransactionType { deposit, transfer, withdrawal, spending }

enum TransactionStatus { completed, pending }

class Transaction {
  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final DateTime date;
  final TransactionStatus status;
  final String description;
  final String sourceWallet;
  final String destinationWallet;
  final String? childName;
  final String? category;

  Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.date,
    required this.status,
    required this.description,
    required this.sourceWallet,
    required this.destinationWallet,
    this.childName,
    this.category,
  });
}

class Child {
  final String id;
  final String name;
  final String avatar;

  Child({
    required this.id,
    required this.name,
    required this.avatar,
  });
}
