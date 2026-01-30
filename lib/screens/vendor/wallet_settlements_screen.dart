import 'package:flutter/material.dart';
import '../../models/wallet_model.dart';
import '../../services/wallet_service.dart';

class WalletSettlementsScreen extends StatefulWidget {
  const WalletSettlementsScreen({super.key});

  @override
  State<WalletSettlementsScreen> createState() =>
      _WalletSettlementsScreenState();
}

class _WalletSettlementsScreenState extends State<WalletSettlementsScreen> {
  final WalletService _walletService = WalletService();
  WalletModel? _wallet;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadWallet();
  }

  Future<void> _loadWallet() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Get current vendor ID from auth
      const vendorId = 'current_vendor_id';
      final wallet = await _walletService.getWalletByUserId(vendorId);

      if (wallet == null) {
        // Create wallet if it doesn't exist
        final newWallet = WalletModel(
          id: '',
          userId: vendorId,
          balance: 0.0,
          currency: 'ZAR',
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        final walletId = await _walletService.createWallet(newWallet);
        final createdWallet = await _walletService.getWalletByUserId(vendorId);
        setState(() {
          _wallet = createdWallet;
        });
      } else {
        setState(() {
          _wallet = wallet;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load wallet: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _withdrawFunds() async {
    if (_wallet == null) return;

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _WithdrawDialog(wallet: _wallet!),
    );

    if (amount != null && amount > 0) {
      if (_wallet!.balance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient funds')),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      try {
        await _walletService.deductFunds(_wallet!.id, amount);
        await _loadWallet(); // Refresh wallet data
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Successfully withdrew R${amount.toStringAsFixed(2)}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to withdraw funds: $e')),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _updateSpendingLimit() async {
    if (_wallet == null) return;

    final limit = await showDialog<double>(
      context: context,
      builder: (context) => _SpendingLimitDialog(wallet: _wallet!),
    );

    if (limit != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        await _walletService.updateSpendingLimit(_wallet!.id, limit);
        await _loadWallet(); // Refresh wallet data
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spending limit updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update spending limit: $e')),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet & Settlements'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadWallet,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Wallet Balance Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Wallet Balance',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'R${_wallet?.balance.toStringAsFixed(2) ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Spending Limit: R${_wallet?.spendingLimit?.toStringAsFixed(2) ?? 'No limit'}',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Action Buttons
                    const Text(
                      'Wallet Actions',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.2,
                      children: [
                        _buildActionCard(
                          title: 'Withdraw Funds',
                          icon: Icons.account_balance_wallet,
                          color: Colors.blue,
                          onTap: _withdrawFunds,
                        ),
                        _buildActionCard(
                          title: 'Update Spending Limit',
                          icon: Icons.settings,
                          color: Colors.orange,
                          onTap: _updateSpendingLimit,
                        ),
                        _buildActionCard(
                          title: 'Transaction History',
                          icon: Icons.history,
                          color: Colors.purple,
                          onTap: () {
                            // TODO: Implement transaction history
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Transaction history will be implemented')),
                            );
                          },
                        ),
                        _buildActionCard(
                          title: 'Settlement Reports',
                          icon: Icons.receipt_long,
                          color: Colors.green,
                          onTap: () {
                            // TODO: Implement settlement reports
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Settlement reports will be implemented')),
                            );
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Processing Indicator
                    if (_isProcessing)
                      const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Processing...'),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: _isProcessing ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 40,
                color: color,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WithdrawDialog extends StatefulWidget {
  final WalletModel wallet;

  const _WithdrawDialog({required this.wallet});

  @override
  State<_WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<_WithdrawDialog> {
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Withdraw Funds'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              'Available Balance: R${widget.wallet.balance.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (R)',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount != null &&
                amount > 0 &&
                amount <= widget.wallet.balance) {
              Navigator.of(context).pop(amount);
            }
          },
          child: const Text('Withdraw'),
        ),
      ],
    );
  }
}

class _SpendingLimitDialog extends StatefulWidget {
  final WalletModel wallet;

  const _SpendingLimitDialog({required this.wallet});

  @override
  State<_SpendingLimitDialog> createState() => _SpendingLimitDialogState();
}

class _SpendingLimitDialogState extends State<_SpendingLimitDialog> {
  final _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _limitController.text = widget.wallet.spendingLimit?.toString() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Spending Limit'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              'Current limit: R${widget.wallet.spendingLimit?.toStringAsFixed(2) ?? 'No limit'}'),
          const SizedBox(height: 16),
          TextField(
            controller: _limitController,
            decoration: const InputDecoration(
              labelText: 'New Spending Limit (R)',
              border: OutlineInputBorder(),
              hintText: 'Leave empty for no limit',
            ),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            final limitText = _limitController.text.trim();
            final limit = limitText.isEmpty ? null : double.tryParse(limitText);
            if (limit == null || limit >= 0) {
              Navigator.of(context).pop(limit);
            }
          },
          child: const Text('Set Limit'),
        ),
      ],
    );
  }
}
