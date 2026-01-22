import 'package:flutter/material.dart';
import '../../models/customer_card_model.dart';
import '../../services/customer_card_service.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final CustomerCardService _cardService = CustomerCardService();
  late Stream<List<CustomerCardModel>> _cardsStream;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // TODO: Get current vendor ID from auth
    _cardsStream = _cardService.getCustomerCardsByParentId('current_vendor_id');
  }

  Future<void> _updateSpendingLimit(CustomerCardModel card) async {
    final limit = await showDialog<double>(
      context: context,
      builder: (context) => _SpendingLimitDialog(card: card),
    );

    if (limit != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _cardService.updateSpendingLimit(card.id, limit);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spending limit updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update spending limit: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deactivateCard(CustomerCardModel card) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Card'),
        content: Text(
            'Are you sure you want to deactivate the card "${card.cardName}"? This will prevent any further transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Deactivate'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _cardService.deactivateCard(card.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Card deactivated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to deactivate card: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security & Child Protection'),
      ),
      body: StreamBuilder<List<CustomerCardModel>>(
        stream: _cardsStream,
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

          final cards = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Security Overview
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Security Overview',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.security, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                                '${cards.where((c) => c.isActive).length} Active Cards'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.block, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                                '${cards.where((c) => !c.isActive).length} Inactive Cards'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
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
                      title: 'Emergency Lock',
                      icon: Icons.lock,
                      color: Colors.red,
                      onTap: () {
                        // TODO: Implement emergency lock for all cards
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Emergency lock will be implemented')),
                        );
                      },
                    ),
                    _buildActionCard(
                      title: 'Security Report',
                      icon: Icons.report,
                      color: Colors.orange,
                      onTap: () {
                        // TODO: Implement security report
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Security report will be implemented')),
                        );
                      },
                    ),
                    _buildActionCard(
                      title: 'Transaction Alerts',
                      icon: Icons.notifications,
                      color: Colors.blue,
                      onTap: () {
                        // TODO: Implement transaction alerts settings
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Transaction alerts will be implemented')),
                        );
                      },
                    ),
                    _buildActionCard(
                      title: 'PIN Management',
                      icon: Icons.pin,
                      color: Colors.purple,
                      onTap: () {
                        // TODO: Implement PIN management
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('PIN management will be implemented')),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Customer Cards Management
                const Text(
                  'Customer Cards',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                if (cards.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text('No customer cards found'),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cards.length,
                    itemBuilder: (context, index) {
                      final card = cards[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    card.cardName,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: card.isActive
                                          ? Colors.green
                                          : Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      card.isActive ? 'Active' : 'Inactive',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text('Card Number: ${card.cardNumber}'),
                              Text(
                                  'Balance: R${card.balance.toStringAsFixed(2)}'),
                              Text(
                                  'Spending Limit: R${card.spendingLimit.toStringAsFixed(2)}'),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: card.isActive
                                          ? () => _updateSpendingLimit(card)
                                          : null,
                                      icon: const Icon(Icons.settings),
                                      label: const Text('Set Limit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: card.isActive
                                          ? () => _deactivateCard(card)
                                          : null,
                                      icon: const Icon(Icons.block),
                                      label: const Text('Deactivate'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Security Tips
                const Text(
                  'Security Tips',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTip(
                          icon: Icons.visibility_off,
                          title: 'Monitor Transactions',
                          description:
                              'Regularly check transaction history for suspicious activity.',
                        ),
                        const Divider(),
                        _buildTip(
                          icon: Icons.lock,
                          title: 'Set Spending Limits',
                          description:
                              'Configure appropriate spending limits for each card.',
                        ),
                        const Divider(),
                        _buildTip(
                          icon: Icons.report,
                          title: 'Report Issues',
                          description:
                              'Contact support immediately if you notice any security concerns.',
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          );
        },
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
        onTap: onTap,
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

  Widget _buildTip({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpendingLimitDialog extends StatefulWidget {
  final CustomerCardModel card;

  const _SpendingLimitDialog({required this.card});

  @override
  State<_SpendingLimitDialog> createState() => _SpendingLimitDialogState();
}

class _SpendingLimitDialogState extends State<_SpendingLimitDialog> {
  final _limitController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _limitController.text = widget.card.spendingLimit.toString();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Set Spending Limit for ${widget.card.cardName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              'Current limit: R${widget.card.spendingLimit.toStringAsFixed(2)}'),
          const SizedBox(height: 16),
          TextField(
            controller: _limitController,
            decoration: const InputDecoration(
              labelText: 'New Spending Limit (R)',
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
            final limit = double.tryParse(_limitController.text);
            if (limit != null && limit >= 0) {
              Navigator.of(context).pop(limit);
            }
          },
          child: const Text('Set Limit'),
        ),
      ],
    );
  }
}
