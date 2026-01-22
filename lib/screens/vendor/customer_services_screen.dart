import 'package:flutter/material.dart';
import '../../models/customer_card_model.dart';
import '../../services/customer_card_service.dart';

class CustomerServicesScreen extends StatefulWidget {
  const CustomerServicesScreen({super.key});

  @override
  State<CustomerServicesScreen> createState() => _CustomerServicesScreenState();
}

class _CustomerServicesScreenState extends State<CustomerServicesScreen> {
  final CustomerCardService _cardService = CustomerCardService();
  CustomerCardModel? _selectedCard;
  bool _isProcessing = false;

  Future<void> _scanCustomerCard() async {
    // TODO: Implement QR scanning
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Customer Card'),
        content: const Text('QR scanning will be implemented'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _enterCardNumber() async {
    final cardNumber = await showDialog<String>(
      context: context,
      builder: (context) => const _EnterCardNumberDialog(),
    );

    if (cardNumber != null && cardNumber.isNotEmpty) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final card = await _cardService.getCustomerCardByNumber(cardNumber);
        if (card != null) {
          setState(() {
            _selectedCard = card;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Card "${card.cardName}" selected successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card not found or inactive')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading card: $e')),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _checkBalance() async {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer card first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Card Balance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Card Name: ${_selectedCard!.cardName}'),
            Text('Card Number: ${_selectedCard!.cardNumber}'),
            const SizedBox(height: 8),
            Text(
              'Balance: R${_selectedCard!.balance.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            Text(
                'Spending Limit: R${_selectedCard!.spendingLimit.toStringAsFixed(2)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _addFunds() async {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer card first')),
      );
      return;
    }

    final amount = await showDialog<double>(
      context: context,
      builder: (context) => _AddFundsDialog(card: _selectedCard!),
    );

    if (amount != null && amount > 0) {
      setState(() {
        _isProcessing = true;
      });

      try {
        await _cardService.addFundsToCard(_selectedCard!.id, amount);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully added R${amount.toStringAsFixed(2)} to card')),
        );
        // Refresh card data
        _loadCardData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add funds: $e')),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _updateSpendingLimit() async {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer card first')),
      );
      return;
    }

    final limit = await showDialog<double>(
      context: context,
      builder: (context) => _SpendingLimitDialog(card: _selectedCard!),
    );

    if (limit != null) {
      setState(() {
        _isProcessing = true;
      });

      try {
        await _cardService.updateSpendingLimit(_selectedCard!.id, limit);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spending limit updated successfully')),
        );
        // Refresh card data
        _loadCardData();
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

  Future<void> _loadCardData() async {
    if (_selectedCard != null) {
      try {
        final updatedCard = await _cardService
            .getCustomerCardByNumber(_selectedCard!.cardNumber);
        if (updatedCard != null) {
          setState(() {
            _selectedCard = updatedCard;
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Services'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Card Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Card',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _selectedCard != null
                        ? Card(
                            color: Colors.blue.shade50,
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
                                        _selectedCard!.cardName,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () => setState(
                                            () => _selectedCard = null),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      'Card Number: ${_selectedCard!.cardNumber}'),
                                  Text(
                                      'Balance: R${_selectedCard!.balance.toStringAsFixed(2)}'),
                                  Text(
                                      'Spending Limit: R${_selectedCard!.spendingLimit.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _scanCustomerCard,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan QR Code'),
                              ),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: _enterCardNumber,
                                icon: const Icon(Icons.keyboard),
                                label: const Text('Enter Card Number'),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Service Options
            const Text(
              'Available Services',
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
                _buildServiceCard(
                  title: 'Check Balance',
                  icon: Icons.account_balance_wallet,
                  color: Colors.blue,
                  onTap: _checkBalance,
                ),
                _buildServiceCard(
                  title: 'Add Funds',
                  icon: Icons.add_circle,
                  color: Colors.green,
                  onTap: _addFunds,
                ),
                _buildServiceCard(
                  title: 'Update Spending Limit',
                  icon: Icons.settings,
                  color: Colors.orange,
                  onTap: _updateSpendingLimit,
                ),
                _buildServiceCard(
                  title: 'Card History',
                  icon: Icons.history,
                  color: Colors.purple,
                  onTap: () {
                    // TODO: Implement card transaction history
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Card history will be implemented')),
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
    );
  }

  Widget _buildServiceCard({
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

class _AddFundsDialog extends StatefulWidget {
  final CustomerCardModel card;

  const _AddFundsDialog({required this.card});

  @override
  State<_AddFundsDialog> createState() => _AddFundsDialogState();
}

class _AddFundsDialogState extends State<_AddFundsDialog> {
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Funds to Card'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Card: ${widget.card.cardName}'),
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
            if (amount != null && amount > 0) {
              Navigator.of(context).pop(amount);
            }
          },
          child: const Text('Add Funds'),
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

class _EnterCardNumberDialog extends StatefulWidget {
  const _EnterCardNumberDialog();

  @override
  State<_EnterCardNumberDialog> createState() => _EnterCardNumberDialogState();
}

class _EnterCardNumberDialogState extends State<_EnterCardNumberDialog> {
  final _cardNumberController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Card Number'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter the customer card number to select the card.'),
          const SizedBox(height: 16),
          TextField(
            controller: _cardNumberController,
            decoration: const InputDecoration(
              labelText: 'Card Number',
              border: OutlineInputBorder(),
              hintText: 'e.g., CARD-123456',
            ),
            keyboardType: TextInputType.text,
            textCapitalization: TextCapitalization.characters,
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
            final cardNumber = _cardNumberController.text.trim().toUpperCase();
            if (cardNumber.isNotEmpty) {
              Navigator.of(context).pop(cardNumber);
            }
          },
          child: const Text('Select Card'),
        ),
      ],
    );
  }
}
