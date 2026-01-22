import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';
import '../../services/customer_card_service.dart';
import '../../models/customer_card_model.dart';

class DigitalServicesScreen extends StatefulWidget {
  const DigitalServicesScreen({super.key});

  @override
  State<DigitalServicesScreen> createState() => _DigitalServicesScreenState();
}

class _DigitalServicesScreenState extends State<DigitalServicesScreen> {
  final TransactionService _transactionService = TransactionService();
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

  Future<void> _sellAirtime() async {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer card first')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _AirtimeDialog(),
    );

    if (result != null) {
      final phoneNumber = result['phoneNumber'] as String;
      final amount = result['amount'] as double;

      if (_selectedCard!.balance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient funds on card')),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      try {
        // Create transaction
        TransactionModel transaction = TransactionModel(
          id: '',
          vendorId: 'current_vendor_id', // TODO: Get from auth
          customerId: _selectedCard!.parentId,
          type: TransactionType.airtime,
          amount: amount,
          currency: 'ZAR',
          status: TransactionStatus.completed,
          description: 'Airtime Purchase - $phoneNumber',
          metadata: {
            'phoneNumber': phoneNumber,
            'cardNumber': _selectedCard!.cardNumber,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        String transactionId =
            await _transactionService.createTransaction(transaction);

        // Deduct from card
        await _cardService.deductFundsFromCard(_selectedCard!.id, amount);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Airtime sold successfully! Transaction ID: $transactionId')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sell airtime: $e')),
        );
      } finally {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _sellTransportTicket() async {
    if (_selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a customer card first')),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const _TransportDialog(),
    );

    if (result != null) {
      final route = result['route'] as String;
      final amount = result['amount'] as double;

      if (_selectedCard!.balance < amount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insufficient funds on card')),
        );
        return;
      }

      setState(() {
        _isProcessing = true;
      });

      try {
        // Create transaction
        TransactionModel transaction = TransactionModel(
          id: '',
          vendorId: 'current_vendor_id', // TODO: Get from auth
          customerId: _selectedCard!.parentId,
          type: TransactionType.transport,
          amount: amount,
          currency: 'ZAR',
          status: TransactionStatus.completed,
          description: 'Transport Ticket - $route',
          metadata: {
            'route': route,
            'cardNumber': _selectedCard!.cardNumber,
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        String transactionId =
            await _transactionService.createTransaction(transaction);

        // Deduct from card
        await _cardService.deductFundsFromCard(_selectedCard!.id, amount);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Transport ticket sold successfully! Transaction ID: $transactionId')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to sell transport ticket: $e')),
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
        title: const Text('Digital Services'),
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
                        ? ListTile(
                            leading: const Icon(Icons.credit_card),
                            title: Text(_selectedCard!.cardName),
                            subtitle: Text(
                                'Balance: R${_selectedCard!.balance.toStringAsFixed(2)}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () =>
                                  setState(() => _selectedCard = null),
                            ),
                          )
                        : ElevatedButton.icon(
                            onPressed: _scanCustomerCard,
                            icon: const Icon(Icons.qr_code_scanner),
                            label: const Text('Scan Customer Card'),
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
                  title: 'Sell Airtime',
                  icon: Icons.phone_android,
                  color: Colors.blue,
                  onTap: _sellAirtime,
                ),
                _buildServiceCard(
                  title: 'Transport Ticket',
                  icon: Icons.directions_bus,
                  color: Colors.green,
                  onTap: _sellTransportTicket,
                ),
                _buildServiceCard(
                  title: 'Electricity',
                  icon: Icons.electrical_services,
                  color: Colors.orange,
                  onTap: () {
                    // TODO: Implement electricity bill payment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Electricity bill payment will be implemented')),
                    );
                  },
                ),
                _buildServiceCard(
                  title: 'Water Bill',
                  icon: Icons.water_drop,
                  color: Colors.cyan,
                  onTap: () {
                    // TODO: Implement water bill payment
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Water bill payment will be implemented')),
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

class _AirtimeDialog extends StatefulWidget {
  const _AirtimeDialog();

  @override
  State<_AirtimeDialog> createState() => _AirtimeDialogState();
}

class _AirtimeDialogState extends State<_AirtimeDialog> {
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sell Airtime'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'e.g. 0712345678',
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (R)',
              hintText: 'e.g. 50.00',
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
            final phone = _phoneController.text.trim();
            final amount = double.tryParse(_amountController.text);
            if (phone.isNotEmpty && amount != null && amount > 0) {
              Navigator.of(context).pop({
                'phoneNumber': phone,
                'amount': amount,
              });
            }
          },
          child: const Text('Sell'),
        ),
      ],
    );
  }
}

class _TransportDialog extends StatefulWidget {
  const _TransportDialog();

  @override
  State<_TransportDialog> createState() => _TransportDialogState();
}

class _TransportDialogState extends State<_TransportDialog> {
  final _routeController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sell Transport Ticket'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _routeController,
            decoration: const InputDecoration(
              labelText: 'Route/Destination',
              hintText: 'e.g. Johannesburg to Pretoria',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (R)',
              hintText: 'e.g. 25.00',
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
            final route = _routeController.text.trim();
            final amount = double.tryParse(_amountController.text);
            if (route.isNotEmpty && amount != null && amount > 0) {
              Navigator.of(context).pop({
                'route': route,
                'amount': amount,
              });
            }
          },
          child: const Text('Sell'),
        ),
      ],
    );
  }
}
