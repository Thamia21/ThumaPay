import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Transaction {
  final String title;
  final double amount;
  final bool incoming;
  final DateTime date;
  final String? sourceAccount;
  final String? destinationAccount;

  const Transaction({
    required this.title,
    required this.amount,
    required this.incoming,
    required this.date,
    this.sourceAccount,
    this.destinationAccount,
  });

  String get formattedAmount {
    final prefix = incoming ? '+ ' : '- ';
    return '$prefix R ${amount.toStringAsFixed(2)}';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
    }
  }

  Transaction copyWith({
    String? title,
    double? amount,
    bool? incoming,
    DateTime? date,
    String? sourceAccount,
    String? destinationAccount,
  }) {
    return Transaction(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      incoming: incoming ?? this.incoming,
      date: date ?? this.date,
      sourceAccount: sourceAccount ?? this.sourceAccount,
      destinationAccount: destinationAccount ?? this.destinationAccount,
    );
  }
}

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool _obscureBalance = false;
  String _fromAccount = 'My Wallet';
  String _toAccount = 'Senzo Pocket Money';
  final TextEditingController _amountController = TextEditingController();

  // Mock balances
  final Map<String, double> _balances = {
    'My Wallet': 12450.00,
    'Senzo Pocket Money': 5300.25,
    'Amara Pocket Money': 24500.90,
    'Kaelo Pocket Money': 500.90,
  };

  // Recent transactions list - limited to 10 for performance
  List<Transaction> _recentTransactions = [];

  @override
  void initState() {
    super.initState();
    _initializeMockTransactions();
  }

  void _initializeMockTransactions() {
    final now = DateTime.now();
    setState(() {
      _recentTransactions = [
        Transaction(
          title: 'Deposit',
          amount: 1500.00,
          incoming: true,
          date: now.subtract(const Duration(hours: 2)),
        ),
        Transaction(
          title: 'Internal Transfer',
          amount: 250.00,
          incoming: false,
          date: now.subtract(const Duration(days: 1)),
          sourceAccount: 'My Wallet',
          destinationAccount: 'Senzo Pocket Money',
        ),
        Transaction(
          title: 'Deposit',
          amount: 120.00,
          incoming: true,
          date: now.subtract(const Duration(days: 2)),
        ),
        Transaction(
          title: 'Withdrawal',
          amount: 600.00,
          incoming: false,
          date: now.subtract(const Duration(days: 3)),
        ),
        Transaction(
          title: 'Internal Transfer',
          amount: 750.00,
          incoming: true,
          date: now.subtract(const Duration(days: 5)),
          sourceAccount: 'Senzo Pocket Money',
          destinationAccount: 'My Wallet',
        ),
        Transaction(
          title: 'Deposit',
          amount: 320.50,
          incoming: true,
          date: now.subtract(const Duration(days: 7)),
        ),
        Transaction(
          title: 'Internal Transfer',
          amount: 180.00,
          incoming: false,
          date: now.subtract(const Duration(days: 10)),
          sourceAccount: 'My Wallet',
          destinationAccount: 'Amara Pocket Money',
        ),
      ];
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  double get _parsedAmount {
    final raw = _amountController.text.replaceAll(',', '').trim();
    return double.tryParse(raw) ?? 0.0;
  }

  bool get _canConfirm {
    return _parsedAmount > 0 && _fromAccount != _toAccount;
  }

  void _showAccountSelectorBottomSheet({
    required String title,
    required String selectedAccount,
    required String? excludeAccount,
    required Function(String) onAccountSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AccountSelectorBottomSheet(
        title: title,
        accounts: _balances,
        selectedAccount: selectedAccount,
        excludeAccount: excludeAccount,
        onAccountSelected: onAccountSelected,
      ),
    );
  }

  void _onConfirm() {
    final amount = _parsedAmount;
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return AlertDialog(
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            'Confirm Transfer',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? theme.colorScheme.onSurface : Colors.black87,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Transfer Details:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow('From', _fromAccount, context),
              _buildDetailRow('To', _toAccount, context),
              _buildDetailRow('Amount', 'R ${amount.toStringAsFixed(2)}', context),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _executeTransfer(amount);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _executeTransfer(double amount) {
    final now = DateTime.now();
    
    // Create two transactions for the transfer
    final outgoingTransaction = Transaction(
      title: 'Internal Transfer',
      amount: amount,
      incoming: false,
      date: now,
      sourceAccount: _fromAccount,
      destinationAccount: _toAccount,
    );
    
    final incomingTransaction = Transaction(
      title: 'Internal Transfer',
      amount: amount,
      incoming: true,
      date: now,
      sourceAccount: _fromAccount,
      destinationAccount: _toAccount,
    );
    
    setState(() {
      // Add new transactions to the top of the list
      _recentTransactions.insert(0, outgoingTransaction);
      _recentTransactions.insert(1, incomingTransaction);
      
      // Keep only the last 10 transactions for performance
      if (_recentTransactions.length > 10) {
        _recentTransactions = _recentTransactions.take(10).toList();
      }
      
      _amountController.clear();
    });
    
    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Dialog(
          backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: Colors.green.shade600,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Success Title
                Text(
                  'Transfer Complete!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? theme.colorScheme.onSurface : Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                // Success Message
                Text(
                  'Successfully transferred R ${amount.toStringAsFixed(2)}\nfrom $_fromAccount to $_toAccount',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? theme.colorScheme.onSurface.withOpacity(0.6) : Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? theme.colorScheme.onSurface : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final onSurface = theme.colorScheme.onSurface;

    return Scaffold(
      backgroundColor: isDark ? theme.scaffoldBackgroundColor : surface,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroCard(context),
            const SizedBox(height: 16),
            _buildInternalTransferCard(surface, onSurface, theme),
            const SizedBox(height: 24),
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? theme.colorScheme.onSurface : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            _buildRecentTransactions(theme),
          ],
        ),
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
            'Wallet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: isDark ? theme.colorScheme.onSurface : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Main wallet',
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

  Widget _buildHeroCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 33, 150, 243), Color.fromARGB(255,33,151,247)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Total Available Balance',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _obscureBalance
                        ? 'R ••••••'
                        : 'R ${_balances['My Wallet']!.toStringAsFixed(2)}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () =>
                    setState(() => _obscureBalance = !_obscureBalance),
                icon: Icon(
                  _obscureBalance
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: Colors.white,
                ),
                tooltip: _obscureBalance ? 'Show balance' : 'Hide balance',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.15),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // Deposit action
                  },
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                  label: const Text(
                    'Deposit',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.65),
                      width: 1.2,
                    ),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    // Withdraw action
                  },
                  icon: const Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                  ),
                  label: const Text(
                    'Withdraw',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInternalTransferCard(
    Color surface,
    Color onSurface,
    ThemeData theme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Internal Transfer',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Transfer From
          _Labeled(
            label: 'Transfer From',
            child: _AccountSelector(
              selectedAccount: _fromAccount,
              onTap: () => _showAccountSelectorBottomSheet(
                title: 'Select source account',
                selectedAccount: _fromAccount,
                excludeAccount: _toAccount,
                onAccountSelected: (account) {
                  setState(() => _fromAccount = account);
                },
              ),
              theme: theme,
            ),
          ),

          const SizedBox(height: 8),

          // Directional arrow
          Center(
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_downward_rounded,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Transfer To
          _Labeled(
            label: 'Transfer To',
            child: _AccountSelector(
              selectedAccount: _toAccount,
              onTap: () => _showAccountSelectorBottomSheet(
                title: 'Select destination account',
                selectedAccount: _toAccount,
                excludeAccount: _fromAccount,
                onAccountSelected: (account) {
                  setState(() => _toAccount = account);
                },
              ),
              theme: theme,
            ),
          ),

          const SizedBox(height: 12),

          // Amount input
          _Labeled(
            label: 'Amount',
            child: TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'^[0-9]*[\.]?[0-9]{0,2}'),
                ),
              ],
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixText: 'R ',
                hintText: '0.00',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Confirm button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canConfirm ? _onConfirm : null,
              child: const Text('Confirm Transfer'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    if (_recentTransactions.isEmpty) {
      return _buildEmptyState(theme);
    }
    
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTransactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final transaction = _recentTransactions[index];
        
        // Determine transaction type and colors
        Color backgroundColor;
        IconData iconData;
        Color iconColor;
        String transactionTitle = transaction.title;
        
        if (transaction.title == 'Deposit') {
          backgroundColor = Colors.green.withOpacity(0.1);
          iconData = Icons.arrow_downward_rounded;
          iconColor = Colors.green.shade600;
        } else if (transaction.title == 'Internal Transfer') {
          backgroundColor = Colors.blue.withOpacity(0.1);
          iconData = Icons.swap_horiz_rounded;
          iconColor = Colors.blue.shade600;
          transactionTitle = transaction.incoming 
              ? 'Transfer from ${transaction.sourceAccount}'
              : 'Transfer to ${transaction.destinationAccount}';
        } else if (transaction.title == 'Withdrawal') {
          backgroundColor = Colors.red.withOpacity(0.1);
          iconData = Icons.arrow_upward_rounded;
          iconColor = Colors.red.shade600;
        } else {
          // Default styling for other transaction types
          backgroundColor = Colors.grey.withOpacity(0.1);
          iconData = Icons.receipt_long_rounded;
          iconColor = Colors.grey.shade600;
        }
            
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
              onTap: () {
                // Optional: Show transaction details
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Left Side (Icon Container)
                    Container(
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
                    ),
                    const SizedBox(width: 12),
                    
                    // Center (Details Column)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transactionTitle,
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
                            transaction.formattedDate,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? theme.colorScheme.onSurface.withOpacity(0.5) : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Right Side (Amount)
                    Text(
                      transaction.formattedAmount,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: iconColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getTransactionSubtitle(Transaction transaction) {
    if (transaction.title == 'Internal Transfer') {
      if (transaction.sourceAccount != null && transaction.destinationAccount != null) {
        return '${transaction.sourceAccount} → ${transaction.destinationAccount}';
      }
    } else if (transaction.title == 'Deposit') {
      return 'External Account → Main Wallet';
    } else if (transaction.title == 'Withdrawal') {
      return 'Main Wallet → External Account';
    }
    return 'Main Wallet';
  }
  
  Widget _buildEmptyState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: isDark ? theme.colorScheme.onSurface.withOpacity(0.4) : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No recent transactions',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? theme.colorScheme.onSurface.withOpacity(0.6) : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your transaction history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? theme.colorScheme.onSurface.withOpacity(0.5) : Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AccountSelector extends StatelessWidget {
  final String selectedAccount;
  final VoidCallback onTap;
  final ThemeData theme;

  const _AccountSelector({
    required this.selectedAccount,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: theme.colorScheme.surface,
          isDense: true,
          suffixIcon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedAccount,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountSelectorBottomSheet extends StatelessWidget {
  final String title;
  final Map<String, double> accounts;
  final String selectedAccount;
  final String? excludeAccount;
  final Function(String) onAccountSelected;

  const _AccountSelectorBottomSheet({
    required this.title,
    required this.accounts,
    required this.selectedAccount,
    this.excludeAccount,
    required this.onAccountSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableAccounts = accounts.keys
        .where((account) => account != excludeAccount)
        .toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Account list
          Flexible(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shrinkWrap: true,
              itemCount: availableAccounts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final account = availableAccounts[index];
                final isSelected = account == selectedAccount;
                final balance = accounts[account]!;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      onAccountSelected(account);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.2),
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : theme.colorScheme.surface,
                      ),
                      child: Row(
                        children: [
                          // Wallet icon
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                                  : theme.colorScheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.account_balance_wallet_outlined,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),

                          const SizedBox(width: 12),

                          // Account info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  account,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'R ${balance.toStringAsFixed(2)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Checkmark for selected account
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: theme.colorScheme.primary,
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _Labeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _Labeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        child,
      ],
    );
  }
}
