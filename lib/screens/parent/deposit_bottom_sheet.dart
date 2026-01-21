// Deposit bottom sheet for selecting amount and payment method
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/deposit_model.dart';
import '../../services/deposit_service.dart';
import '../../services/auth_service.dart';
import '../../services/security_service.dart';

class DepositBottomSheet extends StatefulWidget {
  const DepositBottomSheet({super.key});

  @override
  State<DepositBottomSheet> createState() => _DepositBottomSheetState();
}

class _DepositBottomSheetState extends State<DepositBottomSheet> {
  final DepositService _depositService = DepositService();
  final AuthService _authService = AuthService();
  final SecurityService _securityService = SecurityService();

  final TextEditingController _amountController = TextEditingController();
  DepositMethod _selectedMethod = DepositMethod.bankCard;
  bool _isLoading = false;
  String? _errorMessage;
  List<DepositSuggestion> _suggestions = [];

  // Payment details
  final Map<String, dynamic> _paymentDetails = {};

  @override
  void initState() {
    super.initState();
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final user = _authService.currentUser;
    if (user != null) {
      try {
        final suggestions = await _depositService.getDepositSuggestions(user.uid);
        if (mounted) {
          setState(() {
            _suggestions = suggestions;
          });
        }
      } catch (e) {
        // Handle error silently
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                const Text(
                  'Deposit Money',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Amount input
            const Text(
              'Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              decoration: InputDecoration(
                hintText: 'Enter amount',
                prefixText: 'R ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
              ),
            ),

            // Suggestions
            if (_suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Suggested amounts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _suggestions.map((suggestion) {
                  return OutlinedButton(
                    onPressed: () {
                      _amountController.text = suggestion.amount.toStringAsFixed(2);
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Text('R ${suggestion.amount.toStringAsFixed(0)}'),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 24),

            // Payment method selection
            const Text(
              'Payment Method',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            ...DepositMethod.values.map((method) {
              return RadioListTile<DepositMethod>(
                title: Row(
                  children: [
                    Icon(_getMethodIcon(method)),
                    const SizedBox(width: 12),
                    Text(method.displayName),
                  ],
                ),
                value: method,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMethod = value;
                      _paymentDetails.clear();
                    });
                  }
                },
                contentPadding: EdgeInsets.zero,
                dense: true,
              );
            }),

            // Payment details form
            _buildPaymentDetailsForm(),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Deposit button
            ElevatedButton(
              onPressed: _isLoading ? null : _processDeposit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Deposit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsForm() {
    switch (_selectedMethod) {
      case DepositMethod.bankCard:
        return _buildCardForm();
      case DepositMethod.eft:
        return _buildEFTForm();
      case DepositMethod.mobileMoney:
        return _buildMobileMoneyForm();
      case DepositMethod.qrCode:
        return _buildQRCodeForm();
    }
  }

  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Card Details', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Card Number',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _paymentDetails['cardNumber'] = value,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'MM/YY',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _paymentDetails['expiry'] = value,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'CVV',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => _paymentDetails['cvv'] = value,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEFTForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Bank Details', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Account Number',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _paymentDetails['accountNumber'] = value,
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Bank Code',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => _paymentDetails['bankCode'] = value,
        ),
      ],
    );
  }

  Widget _buildMobileMoneyForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('Mobile Money', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        TextField(
          decoration: const InputDecoration(
            hintText: 'Phone Number',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          onChanged: (value) => _paymentDetails['phoneNumber'] = value,
        ),
      ],
    );
  }

  Widget _buildQRCodeForm() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Scan QR code to complete payment',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  IconData _getMethodIcon(DepositMethod method) {
    switch (method) {
      case DepositMethod.bankCard:
        return Icons.credit_card;
      case DepositMethod.eft:
        return Icons.account_balance;
      case DepositMethod.mobileMoney:
        return Icons.phone_android;
      case DepositMethod.qrCode:
        return Icons.qr_code;
    }
  }

  Future<void> _processDeposit() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      setState(() => _errorMessage = 'Please enter an amount');
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    // Authenticate with biometrics if available
    final canAuthenticate = await _securityService.isBiometricAvailable();
    if (canAuthenticate) {
      final authenticated = await _securityService.authenticateWithBiometrics();
      if (!authenticated) {
        setState(() => _errorMessage = 'Authentication failed');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final result = await _depositService.processDeposit(
        userId: user.uid,
        amount: amount,
        method: _selectedMethod,
        paymentDetails: _paymentDetails.isNotEmpty ? _paymentDetails : null,
        idempotencyKey: 'deposit_${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
      );

      if (result.success) {
        Navigator.of(context).pop(result.transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deposit successful!')),
        );
      } else {
        setState(() => _errorMessage = result.error ?? 'Deposit failed');
      }
    } catch (e) {
      setState(() => _errorMessage = 'An error occurred: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}