import 'package:flutter/material.dart';
import '../../models/wallet_model.dart';
import '../../models/transaction_model.dart' as tx;
import '../../services/auth_service.dart';
import '../../services/wallet_service.dart';
import '../../services/deposit_service.dart';
import 'deposit_bottom_sheet.dart';
import 'deposit_history_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final AuthService _authService = AuthService();
  final WalletService _walletService = WalletService();
  final DepositService _depositService = DepositService();

  WalletModel? _wallet;
  List<tx.Transaction> _recentTransactions = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _obscureBalance = false;

  @override
  void initState() {
    super.initState();
    _loadWalletData();
    _executeAutoDeposits();
  }

  Future<void> _loadWalletData() async {
    setState(() => _isLoading = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final wallet = await _walletService.getWallet(user.uid);
      if (wallet == null) {
        // Create wallet if it doesn't exist
        final newWallet = await _walletService.createWallet(
          userId: user.uid,
          userName: user.displayName ?? 'User',
        );
        _wallet = newWallet;
      } else {
        _wallet = wallet;
      }

      // Load recent transactions (deposits and transfers)
      await _loadRecentTransactions(user.uid);

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

  Future<void> _loadRecentTransactions(String userId) async {
    // Load recent deposits
    final deposits = await _depositService.getDepositHistory(userId);
    _recentTransactions = deposits.take(10).toList();
  }

  Future<void> _executeAutoDeposits() async {
    try {
      await _depositService.executeAutoDeposits();
      // Refresh data if auto-deposits were executed
      _loadWalletData();
    } catch (e) {
      // Silently handle auto-deposit execution errors
      debugPrint('Auto-deposit execution failed: $e');
    }
  }

  void _showDepositBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const DepositBottomSheet(),
    ).then((result) {
      if (result != null && result is tx.Transaction) {
        // Deposit successful, refresh data
        _loadWalletData();
      }
    });
  }

  void _showDepositHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const DepositHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadWalletData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _showDepositHistory,
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Balance Card
            _buildBalanceCard(),

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _showDepositBottomSheet,
                    icon: const Icon(Icons.add),
                    label: const Text('Deposit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Transactions
            const Text(
              'Recent Deposits',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            _buildRecentTransactions(),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Colors.blueAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Available Balance',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _obscureBalance = !_obscureBalance);
                },
                icon: Icon(
                  _obscureBalance ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _obscureBalance
                ? 'R ••••••'
                : 'R ${_wallet?.balance.toStringAsFixed(2) ?? '0.00'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Last updated: ${_wallet?.lastTransactionAt != null ? _formatDate(_wallet!.lastTransactionAt!) : 'Never'}',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    if (_recentTransactions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No recent deposits',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _recentTransactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.add,
                color: Colors.green,
              ),
            ),
            title: Text(
              'Deposit via ${transaction.metadata?['depositMethod'] ?? 'Unknown'}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(_formatDate(transaction.createdAt)),
            trailing: Text(
              '+ R ${transaction.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
