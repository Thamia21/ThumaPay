import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../models/customer_card_model.dart';
import '../../models/transaction_model.dart';
import '../../services/product_service.dart';
import '../../services/customer_card_service.dart';
import '../../services/transaction_service.dart';
import '../../services/wallet_service.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ProductService _productService = ProductService();
  final CustomerCardService _cardService = CustomerCardService();
  final TransactionService _transactionService = TransactionService();
  final WalletService _walletService = WalletService();

  List<ProductModel> _cart = [];
  CustomerCardModel? _selectedCard;
  double _total = 0.0;
  bool _isProcessing = false;

  void _addToCart(ProductModel product) {
    setState(() {
      _cart.add(product);
      _total += product.price;
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      _total -= _cart[index].price;
      _cart.removeAt(index);
    });
  }

  Future<void> _scanProduct() async {
    // TODO: Implement QR scanning for products
    // For now, show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Scan Product'),
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

  Future<void> _scanCustomerCard() async {
    // TODO: Implement QR scanning for customer cards
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
    final TextEditingController _cardNumberController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enter Card Number'),
        content: TextField(
          controller: _cardNumberController,
          decoration: const InputDecoration(
            labelText: 'Card Number',
            hintText: 'Enter the customer card number',
          ),
          keyboardType: TextInputType.number,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final cardNumber = _cardNumberController.text.trim();
              if (cardNumber.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a card number')),
                );
                return;
              }

              try {
                final card =
                    await _cardService.getCustomerCardByNumber(cardNumber);
                if (card != null) {
                  setState(() {
                    _selectedCard = card;
                  });
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Card "${card.cardName}" selected')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Card not found or inactive')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error fetching card: $e')),
                );
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_cart.isEmpty || _selectedCard == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Please add items to cart and select a customer card')),
      );
      return;
    }

    if (_selectedCard!.balance < _total) {
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
        type: TransactionType.purchase,
        amount: _total,
        currency: 'ZAR',
        status: TransactionStatus.completed,
        description: 'POS Purchase',
        metadata: {
          'products': _cart.map((p) => p.toMap()).toList(),
          'cardNumber': _selectedCard!.cardNumber,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      String transactionId =
          await _transactionService.createTransaction(transaction);

      // Deduct from card
      await _cardService.deductFundsFromCard(_selectedCard!.id, _total);

      // Clear cart
      setState(() {
        _cart.clear();
        _total = 0.0;
        _selectedCard = null;
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Payment processed successfully! Transaction ID: $transactionId')),
      );
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('POS - Receive Payment'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanProduct,
            tooltip: 'Scan Product',
          ),
        ],
      ),
      body: Column(
        children: [
          // Customer Card Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Customer Card',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                      : Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _scanCustomerCard,
                                icon: const Icon(Icons.qr_code_scanner),
                                label: const Text('Scan QR Code'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _enterCardNumber,
                                icon: const Icon(Icons.keyboard),
                                label: const Text('Enter Card Number'),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),

          // Cart Section
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Cart (${_cart.length} items)',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text('No items in cart'))
                        : ListView.builder(
                            itemCount: _cart.length,
                            itemBuilder: (context, index) {
                              final product = _cart[index];
                              return ListTile(
                                leading: const Icon(Icons.shopping_cart),
                                title: Text(product.name),
                                subtitle: Text(
                                    'R${product.price.toStringAsFixed(2)}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () => _removeFromCart(index),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // Total and Payment Section
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'R${_total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _processPayment,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isProcessing
                          ? const CircularProgressIndicator()
                          : const Text('Process Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
